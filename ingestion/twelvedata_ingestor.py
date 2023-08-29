"""
Ingestor for TwelveData.
"""
from __future__ import annotations
import asyncio
from itertools import zip_longest
from typing import Literal

import aiohttp


try:
    from .base_ingestor import BaseIgnestionConfig, BaseIngestor
    from .ingestion_utils import logger_factory
except ImportError:
    from base_ingestor import BaseIgnestionConfig, BaseIngestor
    from ingestion_utils import logger_factory


logger = logger_factory(__name__)


# pylint: disable=too-few-public-methods
class TwelveDataConfig(BaseIgnestionConfig):
    """
    Configuration for the TwelveData ingestor.
    """
    apikey: str
    symbols: list[str]
    interval: Literal[
        '1min', '5min', '15min', '30min', '45min', '1h',
        '2h', '4h', '8h', '1day', '1week', '1month'
    ]

    def parameter_dict(self):
        """
        Returns a dict of mandatory and optional parameters.
        """
        return {
            'mandatory': ['apikey', 'symbols'],
            'optional': ['interval']
        }


# pylint: disable=unused-argument
class TwelveDataIngestor(BaseIngestor):
    """
    Ingestor for TwelveData.
    """
    def __init__(self, config: TwelveDataConfig, *args, **kwargs):
        super().__init__(config, *args, **kwargs)
        self.config: TwelveDataConfig
        self.base_url = "https://api.twelvedata.com/quote"
        self.field_mapping = {
            'datetime': ('datetime', str),
            'timestamp': ('timestamp', int),
            'symbol': ('ticker', str),
            'name': ('name', str),
            'open': ('open', float),
            'high': ('high', float),
            'low': ('low', float),
            'close': ('close', float),
            'volume': ('volume', int)
        }

    async def fetch(self, *args, **kwargs) -> dict:
        """
        Factory method for creating a TwelveData ingestor.
        """
        async with aiohttp.ClientSession() as session:
            params = {
                'symbol': ','.join(kwargs['symbols']),
                'apikey': self.config.apikey
            }
            if self.config.interval:
                params['interval'] = self.config.interval
            async with session.get(self.base_url, params=params) as resp:
                return await resp.json()

    async def ingest(self, *args, **kwargs) -> list[dict[str, str | int | float]]:
        """
        Ingests data from TwelveData.
        """
        logger.info("Fetching data for %s symbols.", len(self.config.symbols))
        records = []
        for symbols in zip_longest(*[iter(self.config.symbols)] * 8):
            symbols = [symbol for symbol in symbols if symbol]
            resp = await self.fetch(symbols=symbols)
            records_batch = [
                {
                    replacer: transform(data[field])
                    for field, (replacer, transform) in self.field_mapping.items()
                } | {'source': 'twelvedata'}
                for data in resp.values()
            ]
            records.extend(records_batch)
            logger.info("Fetched batch of %s records.", len(records_batch))
            await self.store(records_batch)
            await asyncio.sleep(60)
        logger.info("Totally fetched %s records.", len(records))
        return records
