"""Talks to the db-server via REST API"""
from __future__ import annotations
import asyncio
import aiohttp


try:
    from .base_connector import BaseConnector, ensure_session
    from .ingestion_utils import logger_factory
except ImportError:
    from base_connector import BaseConnector, ensure_session
    from ingestion_utils import logger_factory


logger = logger_factory(__name__)


class DatabaseConnector(BaseConnector):
    """Connects to the database via REST API."""
    def __init__(self, host: str, port: int):
        super().__init__()
        self.host = host
        self.port = port
        self.base_url = f"http://{self.host}:{self.port}"
        self.session = None

    async def connect(self):
        """Connects to the database."""
        self.session = aiohttp.ClientSession()

    @ensure_session
    async def get_ticker(self, ticker: str):
        """Gets a ticker from the database."""
        async with self.session.get(f"{self.base_url}/tickers/{ticker}") as resp:
            return await resp.json()

    @ensure_session
    async def get_all_tickers(self):
        """Gets all tickers from the database."""
        while True:
            try:
                async with self.session.get(f"{self.base_url}/tickers") as resp:
                    data = await resp.json()
                    logger.info("Found %s tickers.", len(data['items']))
                    return [
                        ticker['ticker']
                        for ticker in data['items']
                    ]
            except aiohttp.ClientConnectorError:
                logger.warning("Failed to get tickers. Retrying in 10 seconds...")
                await asyncio.sleep(10)

    @ensure_session
    async def get_ohlc(self):
        """Gets the saved OHLC data from the database."""
        async with self.session.get(f"{self.base_url}/ohlc") as resp:
            return await resp.json()

    @ensure_session
    async def post_ohlc(self, ohlc: dict):
        """Posts OHLC data to the database."""
        async with self.session.post(f"{self.base_url}/ohlc", json=ohlc) as resp:
            return await resp.json()
