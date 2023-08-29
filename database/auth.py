"""Authentication module for the database."""
from __future__ import annotations
from datetime import datetime, timedelta
from typing import TYPE_CHECKING, Annotated

from fastapi import Depends, HTTPException, Security, status, Header
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import jwt
from jose.exceptions import JWTError
from passlib.context import CryptContext
from psycopg.sql import SQL

from models import User, Token
from forms import RegistrationForm

if TYPE_CHECKING:
    from dbconn import DatabaseConnection
    from k8s_authorizer import KubernetesAPI


OAUTH2_SCHEME = OAuth2PasswordBearer(tokenUrl="token")

class Authenticator:
    """Class for authenticating users."""
    def __init__(
        self, db_conn: DatabaseConnection,
        k8s_authorizer: KubernetesAPI,
        secret_key: str, expiry_days: int = 365
    ):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        self.algorithm = "HS256"
        self.db_conn = db_conn
        self.k8s_authorizer = k8s_authorizer
        self.secret_key = secret_key
        self.expiry_days = expiry_days

    def verify_password(self, plain_password, hashed_password):
        """Verify a password."""
        return self.pwd_context.verify(plain_password, hashed_password)

    def get_password_hash(self, password):
        """Get a password hash."""
        return self.pwd_context.hash(password)

    async def register_user(self,
        form_data: Annotated[RegistrationForm, Depends()]
    ) -> User:
        """Register a user."""
        if form_data.username == "internal":
            return User(username="forbidden", password="N/A")
        fetched_user = await self.db_conn.fetchone(
            SQL("""
                SELECT 1 FROM users
                WHERE
                    username = {username}
                    OR email = {email}
            """).format(
                username=SQL("%s"),
                email=SQL("%s")
            ), (form_data.username, form_data.email)
        )
        if fetched_user:
            return User(username="exists", password="N/A")
        form_data.password = self.get_password_hash(
            form_data.password.get_secret_value()
        )
        fields = ["email", "password", "username"]
        values = [getattr(form_data, field) for field in fields]
        await self.db_conn.insert(
            SQL("""
                INSERT INTO users ({fields})
                VALUES ({values})
            """).format(
                fields=SQL(",").join(SQL(field) for field in fields),
                values=SQL(",").join(SQL("%s") for _ in values)
            ), values
        )
        return User(username=form_data.username, password="N/A")

    async def authenticate_user(self,
        form_data: Annotated[OAuth2PasswordRequestForm, Depends()]
    ) -> User:
        """Authenticate a user."""
        fetched_user = await self.db_conn.fetchone(
            SQL("SELECT * FROM users WHERE username = {username}").format(
                username=SQL("%s")
            ), (form_data.username,)
        )
        if not fetched_user:
            raise HTTPException(status_code=400, detail="Incorrect username or password")
        fetched_user = User(**fetched_user)
        if not fetched_user or not self.verify_password(
            form_data.password,
            # pylint: disable=no-member
            fetched_user.password.get_secret_value()
        ):
            raise HTTPException(status_code=400, detail="Incorrect username or password")
        token = self.get_access_token(fetched_user)
        return Token(access_token=token, token_type="bearer")

    async def get_current_user(
        self, token: Annotated[
            str, Security(OAUTH2_SCHEME)
        ],
        x_internal_client=Header(include_in_schema=False, default=None),
        x_internal_token=Header(include_in_schema=False, default=None)
    ) -> str:
        """Get the current user."""
        if (
            x_internal_client and x_internal_token
            and await self.k8s_authorizer.validate_token(x_internal_client, x_internal_token)
        ):
            return "internal"
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        try:
            if token is None:
                raise credentials_exception
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            username: str = payload.get("sub")
            if username is None:
                raise credentials_exception
        except JWTError as jex:
            raise credentials_exception from jex
        return username

    def get_access_token(self, user: User):
        """Get an access token."""
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        expires = datetime.utcnow() + timedelta(days=self.expiry_days)
        to_encode = {"sub": user.username, "exp": expires}
        return jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
