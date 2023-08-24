"""
This module contains FastAPI request models.
"""
from __future__ import annotations
from datetime import datetime as dt
from typing import Literal, Optional
from pydantic import BaseModel, Field, model_validator


class SuccessResponse(BaseModel):
    """A model representing the response of the registration."""
    status: Literal["ok"] = Field(..., description="The status of the registration.")


class ErrorResponse(BaseModel):
    """A model representing an error response."""
    detail: str = Field(..., description="The error message.", alias="error")


class User(BaseModel):
    """A model representing a user."""
    username: Optional[str] = None
    password: str = Field(..., description="The password of the user.")
    email: Optional[str] = None

    @model_validator(mode='after')
    def validate_username(self) -> User:
        """Validates either the username or email is passed."""
        if not self.username and not self.email:
            raise ValueError("Either username or email must be passed.")
        if not self.username:
            setattr(self, 'username', self.email)
        return self


class RegisterUser(User):
    """A model representing a user for registration."""
    email: str = Field(..., description="The email of the user.")
    password: str = Field(..., description="The password of the user.")
    username: Optional[str] = None

    @model_validator(mode='after')
    def validate_username(self) -> RegisterUser:
        """Validates either the username or email is passed."""
        if not self.username:
            setattr(self, 'username', self.email)
        return self


class Token(BaseModel):
    """A model representing a token."""
    token: str = Field(..., description="A Bearer token for authenticating your requests.")


class Ticker(BaseModel):
    """A model representing a ticker."""
    ticker: str = Field(..., description="The ticker symbol of the stock.")
    name: str = Field(..., description="The name of the stock.")


class TickersResponse(BaseModel):
    """A model representing the response of the tickers."""
    count: int = Field(..., description="The number of tickers.")
    items: list[Ticker] = Field(..., description="The list of tickers.")


class OHLC(BaseModel):
    """A model representing the OHLC data of a stock."""
    datetime: dt = Field(..., description="The datetime of the stock.")
    timestamp: int = Field(..., description="The timestamp of the stock.")
    ticker: str = Field(..., description="The ticker symbol of the stock.")
    name: str = Field(..., description="The name of the stock.")
    open: float = Field(..., description="The opening price of the stock.")
    high: float = Field(..., description="The highest price of the stock.")
    low: float = Field(..., description="The lowest price of the stock.")
    close: float = Field(..., description="The closing price of the stock.")
    volume: float = Field(..., description="The volume of the stock.")
    source: str = Field(..., description="The source of the stock data.")


class JoinedOHLCData(OHLC):
    """A model representing the OHLC data of a stock with the stored ticker name."""
    stored_company_name: str = Field(..., description="The stored name of the stock.")


class OHLCResponse(BaseModel):
    """A model representing the response of the OHLC data of a stock."""
    count: int = Field(..., description="The number of OHLC data.")
    items: list[JoinedOHLCData] = Field(..., description="The list of OHLC data.")
