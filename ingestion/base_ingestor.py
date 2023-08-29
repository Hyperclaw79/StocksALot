"""
Contains the base class for all ingestors.
"""
from __future__ import annotations
from abc import ABC, abstractmethod
import json
from typing import Literal, TYPE_CHECKING

try:
    from .ingestion_utils import logger_factory
except ImportError:
    from ingestion_utils import logger_factory

if TYPE_CHECKING:
    try:
        from .database_connector import DatabaseConnector
        from .rabbitmq_connector import RabbitMQConnector
    except ImportError:
        from database_connector import DatabaseConnector
        from rabbitmq_connector import RabbitMQConnector


logger = logger_factory(__name__)


class BaseIgnestionConfig(ABC):
    """
    Base class for all ingestion configurations.
    """
    def __init__(self, config: dict):
        self._loaded = {}
        self._load(config)

    @abstractmethod
    def parameter_dict(self) -> dict[Literal['mandatory', 'optional'], dict]:
        """
        Abstract method for returning a dict of mandatory and optional parameters.
        """
        return {'mandatory': [], 'optional': []}

    def to_dict(self) -> dict:
        """
        Returns a dict representation of the config.
        """
        return self._loaded

    def _load(self, config: dict):
        parameter_dict = self.parameter_dict()
        mandatory_params = parameter_dict['mandatory']
        optional_params = parameter_dict['optional']
        for param in mandatory_params:
            if param not in config:
                raise ValueError(f"Missing mandatory parameter {param}.")
            setattr(self, param, config[param])
            self._loaded[param] = config[param]
        for param in optional_params:
            setattr(self, param, config.get(param))
            self._loaded[param] = config.get(param)

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}({self._loaded})"


class BaseIngestor(ABC):
    """
    Base class for all ingestors.
    """
    def __init__(
        self, config: BaseIgnestionConfig,
        dbconn: DatabaseConnector,
        rbconn: RabbitMQConnector
    ):
        self.config = config
        self.dbconn = dbconn
        self.rbconn = rbconn

    @abstractmethod
    async def fetch(self, *args, **kwargs):
        """
        Abstract factory method for creating ingestors.
        """

    @abstractmethod
    async def ingest(self, *args, **kwargs):
        """
        Abstract method for ingesting data.
        """

    async def store(self, records: list[dict[str, str | int | float]]) -> bool:
        """
        Store the records to the database.
        """
        if not records:
            logger.warning("No records to store.")
            return False
        logger.info("Storing %s records.", len(records))
        response = await self.rbconn.publish('ohlc', json.dumps(records))
        if response:
            logger.success("Successfully stored records.")
            return True
        logger.error("Failed to store records.")
        return False
