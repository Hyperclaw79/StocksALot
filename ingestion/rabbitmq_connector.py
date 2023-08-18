"""Talks to the RabbitMQ server via AMQP"""
from __future__ import annotations
import asyncio
import aio_pika
from aio_pika import connect_robust, Message

try:
    from .ingestion_utils import logger_factory
    from .base_connector import BaseConnector, ensure_session
except ImportError:
    from base_connector import BaseConnector, ensure_session
    from ingestion_utils import logger_factory


logger = logger_factory(__name__)


# pylint: disable=too-many-arguments
class RabbitMQConnector(BaseConnector):
    """Connector for RabbitMQ server."""
    def __init__(
        self, host: str, port: int,
        username: str, password: str,
        ack_timeout: float = 5.0
    ):
        super().__init__()
        self.connection_string = f"amqp://{username}:{password}@{host}:{port}"
        self.ack_timeout = ack_timeout
        self.session: aio_pika.Connection = None
        self.channel: aio_pika.Channel = None
        self.queues: list[aio_pika.Queue] = []

    async def connect(self):
        """Connects to the RabbitMQ server."""
        logger.info("Connecting to RabbitMQ...")
        while not self.session:
            try:
                self.session = await connect_robust(self.connection_string)
                logger.success("Connected to RabbitMQ.")
            except aio_pika.exceptions.AMQPConnectionError:
                logger.warning("Failed to connect to RabbitMQ. Retrying in 10 seconds...")
                await asyncio.sleep(10)
        self.channel = await self.session.channel()

    @ensure_session
    async def publish(self, queue_name: str, message: str):
        """Publishes a message to a queue."""
        if queue_name not in self.queues:
            await self.channel.declare_queue(queue_name)
            self.queues.append(queue_name)
        try:
            await self.channel.default_exchange.publish(
                Message(body=message.encode()),
                routing_key=queue_name,
                timeout=self.ack_timeout
            )
            return True
        except aio_pika.exceptions.DeliveryError:
            return False
