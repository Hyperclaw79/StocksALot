"""Authentication module for the database."""
from __future__ import annotations
from datetime import datetime, timedelta
from typing import TYPE_CHECKING, Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt
from jose.exceptions import JWTError
from passlib.context import CryptContext
from psycopg.sql import SQL

from models import User

if TYPE_CHECKING:
    from dbconn import DatabaseConnection


class Authenticator:
    """Class for authenticating users."""
    def __init__(
        self, db_conn: DatabaseConnection,
        secret_key: str, expiry_days: int = 365
    ):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        self.algorithm = "HS256"
        self.db_conn = db_conn
        self.secret_key = secret_key
        self.expiry_days = expiry_days

    def verify_password(self, plain_password, hashed_password):
        """Verify a password."""
        return self.pwd_context.verify(plain_password, hashed_password)

    def get_password_hash(self, password):
        """Get a password hash."""
        return self.pwd_context.hash(password)

    async def authenticate_user(self, user: User) -> User:
        """Authenticate a user."""
        fetched_user = await self.db_conn.fetchone(
            SQL("SELECT * FROM users WHERE username = {username}").format(
                username=SQL("%s")
            ), (user.username,)
        )
        if not fetched_user:
            return None
        fetched_user = User(**fetched_user)
        if not fetched_user or not self.verify_password(user.password, fetched_user.password):
            return None
        return fetched_user

    async def get_current_user(self, token: Annotated[
        str, Depends(OAuth2PasswordBearer(tokenUrl="token"))
    ]) -> str:
        """Get the current user."""
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
