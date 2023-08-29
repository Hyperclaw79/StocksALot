"""
This module contains FastAPI request models.
"""
from __future__ import annotations
from datetime import datetime as dt
from enum import Enum
import json
from typing import Literal
from pydantic import BaseModel, ConfigDict, EmailStr, Field, SecretStr, model_validator


# pylint: disable=function-redefined
class BaseModel(BaseModel):
    """Overridden Pydantic BaseModel to use enums as values."""
    model_config = ConfigDict(use_enum_values=True, populate_by_name=True)


class SuccessResponse(BaseModel):
    """A model representing the response of the registration."""
    status: Literal["ok"] = Field(..., description="The status of the registration.")


class ErrorResponse(BaseModel):
    """A model representing an error response."""
    detail: str = Field(..., description="The error message.", alias="error")


class User(BaseModel):
    """A model representing a user."""
    username: str = Field(..., description="Use your email if you don't have a username.")
    password: SecretStr = Field(..., description="The password of the user.")


class RegisterUser(User):
    """A model representing a user for registration."""
    email: EmailStr = Field(..., description="The email of the user.")
    username: str = Field(
        default=None,
        description="An optional username. Defaults to email."
    )

    @model_validator(mode='after')
    def validate_username(self) -> RegisterUser:
        """Validates either the username or email is passed."""
        if not self.username:
            setattr(self, 'username', self.email)
        return self


class Token(BaseModel):
    """A model representing a token."""
    access_token: str = Field(..., description="A Bearer token for authenticating your requests.")
    token_type: Literal["bearer"] = Field(default="bearer", description="The type of the token.")


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


class Company(BaseModel):
    """A model representing a company."""
    ticker: str = Field(..., description="The ticker symbol of the stock.")
    name: str = Field(..., description="The name of the stock.")
    website: str = Field(..., description="The website of the stock.")
    country: str = Field(..., description="The country of the stock.")
    logo: str = Field(..., description="The logo of the stock.")
    industry: str = Field(default=None, description="The industry of the stock.")
    exchange: str = Field(default=None, description="The exchange of the stock.")
    phone: str = Field(default=None, description="The phone number of the stock.")
    market_cap: int = Field(default=None, description="The market capitalization of the stock.")
    num_shares: int = Field(default=None, description="The number of shares of the stock.")


class Sentiments(Enum):
    """A class representing the sentiments of an insight."""
    POSITIVE = "positive"
    NEGATIVE = "negative"
    NEUTRAL = "neutral"


class Insight(BaseModel):
    """A model representing an insight from analysing stocks."""
    message: str = Field(..., description="The message of the insight.", alias="insight")
    sentiment: Sentiments = Field(
        ..., description="The sentiment of the insight."
    )

class Insights(BaseModel):
    """A model representing the insights from analysing stocks."""
    datetime: dt = Field(..., description="The datetime of the stock.")
    insights: list[Insight] = Field(
        ..., description="The list of insights.",
        min_length=3, max_length=5
    )

    @model_validator(mode='before')
    @classmethod
    def validate_insights(cls, value: dict | Insights) -> Insights:
        """Validates the number of insights."""
        # Suppress errors while maintaing the schema since OpenAI's behavior
        # is not consistent.
        if isinstance(value, dict) and not value.get("insights"):
            value["count"] = 0
            value["insights"] = [
                Insight(
                    message="",
                    sentiment=Sentiments.NEUTRAL
                )
            ] * 3
        if isinstance(value, Insights) and len(value.insights) < 3:
            value.insights.extend([
                Insight(
                    message="",
                    sentiment=Sentiments.NEUTRAL
                )
            ] * (3 - len(value.insights)))
            value.count = 0
        return value


class InsightsResponse(BaseModel):
    """A model representing the response of the insights."""
    count: int = Field(..., description="The number of insights.")
    items: list[Insights] = Field(..., description="The list of insights.")


class GptRoles(Enum):
    """A class representing the roles of the GPT API."""
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"


class Message(BaseModel):
    """A model representing a message for the GPT API."""
    role: GptRoles = Field(..., description="The role of the message.")
    content: str = Field(..., description="The text of the message.")


class InsightsRequest(BaseModel):
    """A model representing the request for the insights."""
    datetime: dt = Field(..., description="The datetime of the stock.")
    ticker: str = Field(..., description="The ticker symbol of the stock.")
    name: str = Field(..., description="The name of the stock.")
    open: float = Field(..., description="The opening price of the stock.")
    high: float = Field(..., description="The highest price of the stock.")
    low: float = Field(..., description="The lowest price of the stock.")
    close: float = Field(..., description="The closing price of the stock.")
    volume: float = Field(..., description="The volume of the stock.")


class InsightsRequests(BaseModel):
    """A model representing the collection of requests for the insights."""
    requests: list[InsightsRequest] = Field(..., description="List of stock data records.")

    def to_json(self) -> str:
        """Converts the model to JSON."""
        return json.dumps([
            # pylint: disable=not-an-iterable
            req.model_dump() for req in self.requests
        ], indent=3, default=str)


class InsightsRequestsBatch(BaseModel):
    """A model representing the batch of requests for the insights."""
    batch: list[InsightsRequests] = Field(..., description="List of stock data batches.")

    @classmethod
    def from_sql_result(cls, result: list[dict]) -> InsightsRequestsBatch:
        """Converts the SQL result to a InsightsRequestsBatch."""
        datetime_map: dict[str, list] = {}
        for row in result:
            if row['datetime'] not in datetime_map:
                datetime_map[row['datetime']] = []
            datetime_map[row['datetime']].append(
                InsightsRequest(**row)
            )
        batch = [
            InsightsRequests(requests=requests)
            for requests in datetime_map.values()
        ]
        return cls(batch=batch)


class Metrics(BaseModel):
    """A model representing the metrics of a stock."""
    open: float = Field(..., description="The opening price of the stock.")
    high: float = Field(..., description="The highest price of the stock.")
    low: float = Field(..., description="The lowest price of the stock.")
    close: float = Field(..., description="The closing price of the stock.")
    volume: int = Field(..., description="The volume of the stock.")


class Mover(BaseModel):
    """A model representing a market mover."""
    profile: Company
    current_metrics: Metrics
    metric_deltas: Metrics


class MoversResponse(BaseModel):
    """A model representing the response of the market movers."""
    count: int = Field(..., description="The number of market movers.")
    items: list[Mover] = Field(..., description="The list of market movers.")
