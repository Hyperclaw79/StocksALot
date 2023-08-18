"""Abstract Base class for all connectors which communicate externally."""
from __future__ import annotations
from abc import ABC, abstractmethod
from functools import wraps


def ensure_session(func):
    """Ensures that the session is open before calling the function."""
    @wraps(func)
    async def wrapper(self, *args, **kwargs):
        if not self.session:
            raise TypeError(
                f"Use the {self} as an async context manager."
            )
        return await func(self, *args, **kwargs)
    return wrapper

# pylint: disable=too-few-public-methods
class AbstractSession(ABC):
    """
    Abstract base class to represent a closable session.
    """
    @abstractmethod
    def close(self):
        """Closes the session."""


class BaseConnector(ABC):
    """
    Base class for all connectors.
    """
    def __init__(self):
        self.session: AbstractSession = None

    def __repr__(self) -> str:
        return f"<[{self.__class__.__name__}]>"

    @abstractmethod
    async def connect(self):
        """Connects to the external resource."""

    async def disconnect(self):
        """Closes the connection to the external resource."""
        await self.session.close()

    async def __aenter__(self) -> BaseConnector:
        await self.connect()
        return self

    async def __aexit__(self, *_):
        await self.disconnect()
