"""This module contains FastAPI request models."""
# pylint: disable=too-few-public-methods
from fastapi.param_functions import Form
from pydantic import SecretStr, EmailStr


class RegistrationForm:
    """A model representing a user for registration."""
    def __init__(
        self,
        *,
        email: EmailStr = Form(..., description="The email of the user."),
        password: SecretStr = Form(..., description="The password of the user."),
        username: str = Form(
            default=None,
            description="An optional username. Defaults to email."
        )
    ):
        self.email = email
        self.password = password
        self.username = username or email
