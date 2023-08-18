"""Connection Handler for RabbitMQ."""
from __future__ import annotations
import asyncio
import json
import aio_pika
from base_connector import BaseConnector
from utils import logger_factory


logger = logger_factory(__name__)


class RabbitMQConnector(BaseConnector):
    """Connector for RabbitMQ server."""
    def __init__(
        self, host: str, port: int,
        username: str, password: str
    ):
        super().__init__()
        self.connection_string = f"amqp://{username}:{password}@{host}:{port}"
        self.session: aio_pika.Connection = None
        self.channel: aio_pika.Channel = None
        self.queues: list[aio_pika.Queue] = []

    async def connect(self):
        """Connects to the RabbitMQ server."""
        logger.info("Connecting to RabbitMQ...")
        while not self.session:
            try:
                self.session = await aio_pika.connect_robust(self.connection_string)
                logger.success("Connected to RabbitMQ.")
            except aio_pika.exceptions.AMQPConnectionError:
                logger.warning("Failed to connect to RabbitMQ. Retrying in 10 seconds...")
                await asyncio.sleep(10)
        self.channel = await self.session.channel()

    async def disconnect(self):
        """Disconnects from the RabbitMQ server."""
        logger.info("Disconnecting from RabbitMQ...")
        await super().disconnect()

    async def consume(self, queue_name: str, callback: callable):
        """Consumes a queue."""
        if queue_name not in self.queues:
            queue = await self.channel.declare_queue(queue_name)
            self.queues.append(queue_name)
        num_messages = 0
        async with queue.iterator() as queue_iter:
            async for message in queue_iter:
                async with message.process():
                    num_messages += 1
                    try:
                        ohlc = json.loads((message.body or b'{}').decode())
                    except json.JSONDecodeError:
                        ohlc = None
                    if not ohlc:
                        logger.warning("RabbitMQ: Received invalid message.")
                        continue
                    logger.info("RabbitMQ: Processing new message.")
                    await callback(ohlc)
        logger.success(f"RabbitMQ: Consumed {num_messages} messages.")

    async def periodic_consume(
        self, queue_name: str,
        callback: callable, interval: int
    ):
        """Consumes a queue periodically."""
        logger.info("RabbitMQ: Periodic consumption started.")
        while True:
            await self.consume(queue_name, callback)
            await asyncio.sleep(interval)
            logger.info("RabbitMQ: Checking Queue for new messages.")
