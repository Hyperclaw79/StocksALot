# pylint: skip-file
import asyncio
from contextlib import asynccontextmanager
from unittest.mock import patch

import pytest

from rcbconn import RabbitMQConnector


@pytest.fixture
def mock_aio_pika():
    with patch('aio_pika.connect_robust') as mock_connect_robust:
        class MockMessage:
            def __init__(self, body):
                self.body = body
            @asynccontextmanager
            async def process(self):
                yield
        class MockMessageIterator:
            def __init__(self) -> None:
                self.queue = asyncio.Queue()
                self.seeded = False
            def __aiter__(self):
                return self
            async def __anext__(self):
                if not self.seeded and self.queue.empty():
                    for message in [
                        MockMessage(b'{"symbol": "AAPL", "price": 150.0}'),
                        MockMessage(b'{"symbol": "GOOG", "price": 2500.0}'),
                        MockMessage(b'{"symbol": "TSLA", "price": 700.0}'),
                    ]:
                        await self.queue.put(message)
                    self.seeded = True
                elif self.queue.empty():
                    raise StopAsyncIteration
                return await self.queue.get()
        class MockMessageQueueIterator:
            async def __aenter__(self):
                return MockMessageIterator()
            async def __aexit__(self, exc_type, exc, tb):
                pass
        class MockQueue:
            def __init__(self, queue_name):
                self.name = queue_name
            def iterator(self):
                return MockMessageQueueIterator()
        class MockChannel:
            async def declare_queue(self, queue_name, **kwargs):
                return MockQueue(queue_name)
        class MockConnection:
            def __init__(self):
                self.closed = False
            async def close(self):
                self.closed = True
            async def channel(self):
                return MockChannel()
        mock_connect_robust.return_value = MockConnection()
        yield mock_connect_robust


@pytest.fixture
async def rabbitmq_conn(mock_aio_pika):
    yield RabbitMQConnector(
        host='localhost', port=5672,
        username='guest', password='guest'
    )


async def test_ping(rabbitmq_conn: RabbitMQConnector):
    async with rabbitmq_conn:
        assert rabbitmq_conn.session is not None
    assert rabbitmq_conn.session.closed is True


async def test_rabbitmq_connector_consume(rabbitmq_conn):
    queue_name = "test_queue"
    messages = [
        {"symbol": "AAPL", "price": 150.0},
        {"symbol": "GOOG", "price": 2500.0},
        {"symbol": "TSLA", "price": 700.0},
    ]
    async def callback(ohlc):
        assert ohlc in messages

    async with rabbitmq_conn:
        await rabbitmq_conn.consume(queue_name, callback)
