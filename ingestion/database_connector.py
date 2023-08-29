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
        self.session: aiohttp.ClientSession = None

    async def connect(self):
        """Connects to the database."""
        self.session = aiohttp.ClientSession(headers={
            'Authorization': 'Bearer Internal',
            'X-Internal-Client': 'Ingestor',
            'X-Internal-Token': str(self._get_k8s_token())
        })

    @ensure_session
    async def get_ticker(self, ticker: str) -> dict:
        """Gets a ticker from the database."""
        async with self.session.get(f"{self.base_url}/tickers/{ticker}") as resp:
            return await resp.json()

    @ensure_session
    async def get_all_tickers(self) -> dict:
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
    async def get_ohlc(self) -> dict:
        """Gets the saved OHLC data from the database."""
        async with self.session.get(f"{self.base_url}/ohlc") as resp:
            return await resp.json()

    @ensure_session
    async def post_ohlc(self, ohlc: dict) -> dict:
        """Posts OHLC data to the database."""
        async with self.session.post(f"{self.base_url}/ohlc", json=ohlc) as resp:
            return await resp.json()

    @ensure_session
    async def put_companies(self, companies: list[dict]) -> dict:
        """Puts companies to the database."""
        async with self.session.put(f"{self.base_url}/companies", json=companies) as resp:
            return await resp.json()

    async def __aenter__(self) -> DatabaseConnector:
        await super().__aenter__()
        logger.info("Connected to the database server.")
        return self

    async def __aexit__(self, *_):
        await super().__aexit__()
        logger.info("Disconnected from the database server.")

    @staticmethod
    def _get_k8s_token() -> str:
        """Gets the kubernetes token."""
        try:
            with open(
                "/var/run/secrets/kubernetes.io/serviceaccount/token",
                encoding="utf-8"
            ) as token_file:
                return token_file.read()
        except FileNotFoundError:
            return None
