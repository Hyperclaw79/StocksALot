"""
Ingestor for FinnHub.
"""
from __future__ import annotations
import asyncio

import aiohttp


try:
    from .base_ingestor import BaseIgnestionConfig, BaseIngestor
    from .ingestion_utils import logger_factory
except ImportError:
    from base_ingestor import BaseIgnestionConfig, BaseIngestor
    from ingestion_utils import logger_factory


logger = logger_factory(__name__)


# pylint: disable=too-few-public-methods
class FinnHubConfig(BaseIgnestionConfig):
    """
    Configuration for the FinnHub ingestor.
    """
    token: str
    symbols: list[str]

    def parameter_dict(self):
        """
        Returns a dict of mandatory and optional parameters.
        """
        return {
            'mandatory': ['token', 'symbols'],
            'optional': []
        }


# pylint: disable=unused-argument
class FinnHubIngestor(BaseIngestor):
    """
    Ingestor for FinnHub.
    """
    def __init__(self, config: FinnHubConfig, *args, **kwargs):
        super().__init__(config, *args, **kwargs)
        self.config: FinnHubConfig
        self.base_url = "https://finnhub.io/api/v1/stock/profile2"
        self.field_mapping = {
            'ticker': ('ticker', str),
            'name': ('name', str),
            'weburl': ('website', str),
            'country': ('country', str),
            'logo': ('logo', str),
            'finnhubIndustry': ('industry', str),
            'exchange': ('exchange', str),
            'phone': ('phone', lambda phn: f"+{phn.split('.')[0]}"),
            'marketCapitalization': ('market_cap', int),
            'shareOutstanding': ('num_shares', int)
        }

    async def fetch(self, *args, **kwargs) -> dict:
        """
        Factory method for creating a FinnHub ingestor.
        """
        async with aiohttp.ClientSession() as session:
            params = {
                'symbol': kwargs['symbol'],
                'token': self.config.token
            }
            async with session.get(self.base_url, params=params) as resp:
                return await resp.json()

    async def ingest(self, *args, **kwargs) -> list[dict[str, str | int]]:
        """
        Ingests data from FinnHub.
        """
        logger.info("Fetching data for %s symbols.", len(self.config.symbols))
        records = []
        for symbol in self.config.symbols:
            resp = await self.fetch(symbol=symbol)
            records.append({
                replacer: transform(resp[field])
                for field, (replacer, transform) in self.field_mapping.items()
            })
            logger.info("Updated info for %s.", symbol)
            await asyncio.sleep(1.0)
        await self.store(records)
        logger.info("Totally updated %s companies.", len(records))
        return records

    async def store(self, records: list[dict[str, str | int]]) -> bool:
        """
        Store the records to the database.
        """
        if not records:
            logger.warning("No records to store.")
            return False
        logger.info("Storing %s records.", len(records))
        response = await self.dbconn.put_companies(records)
        response = response.get('status', 'error') == 'ok'
        if response:
            logger.success("Successfully stored records.")
            return True
        logger.error("Failed to store records.")
        return False
