"""Launches all ingestion processes."""
from __future__ import annotations
import asyncio
import os
from typing import TYPE_CHECKING

try:
    from .rabbitmq_connector import RabbitMQConnector
    from .database_connector import DatabaseConnector
    from .twelvedata_ingestor import TwelveDataConfig, TwelveDataIngestor
    from .finnhub_ingestor import FinnHubConfig, FinnHubIngestor
except ImportError:
    from rabbitmq_connector import RabbitMQConnector
    from database_connector import DatabaseConnector
    from twelvedata_ingestor import TwelveDataConfig, TwelveDataIngestor
    from finnhub_ingestor import FinnHubConfig, FinnHubIngestor

if TYPE_CHECKING:
    try:
        from .base_ingestor import BaseIngestor, BaseIgnestionConfig
    except ImportError:
        from base_ingestor import BaseIngestor, BaseIgnestionConfig


def fetch_password(pwd_name: str, default: str = None) -> str:
    """Get the password for the database."""
    if pwd := os.getenv(pwd_name):
        return pwd
    if pwd_file := os.getenv(f"{pwd_name}_FILE"):
        with open(pwd_file, encoding='utf-8') as password_file:
            return password_file.read().strip()
    return default


AVAILABLE_INGESTORS: list[
    dict[str, BaseIngestor | BaseIgnestionConfig | dict]
] = [
    {
        'ingestor': FinnHubIngestor,
        'config': FinnHubConfig,
        'config_params': {
            'token': fetch_password("FINNHUB_API_KEY")
        }
    },
    {
        'ingestor': TwelveDataIngestor,
        'config': TwelveDataConfig,
        'config_params': {
            'apikey': fetch_password("TWELVEDATA_API_KEY"),
            'interval': '1h'
        }
    }
]


async def main():
    """Main entrypoint."""
    async with (
        DatabaseConnector(
            host=os.getenv('DB_SERVER_HOST', 'localhost'),
            port=os.getenv('DB_SERVER_PORT', '5000')
        ) as dbconn,
        RabbitMQConnector(
            host=os.getenv('RABBITMQ_HOST', 'localhost'),
            port=os.getenv('RABBITMQ_PORT', '5672'),
            username=os.getenv('RABBITMQ_USER', 'guest'),
            password=fetch_password('RABBITMQ_PASSWORD', default='guest')
        ) as rbconn,
        asyncio.TaskGroup() as task_group
    ):
        all_tickers = await dbconn.get_all_tickers()
        for ingestor in AVAILABLE_INGESTORS:
            ingestor_cls: type[BaseIngestor] = ingestor['ingestor']
            ingestor_cfg: BaseIgnestionConfig = ingestor['config']
            cfg = ingestor_cfg(ingestor['config_params'] | {'symbols': all_tickers})
            ingestor = ingestor_cls(cfg, dbconn, rbconn)
            task_group.create_task(ingestor.ingest())


if __name__ == '__main__':
    asyncio.run(main())
