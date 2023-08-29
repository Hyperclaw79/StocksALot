# pylint: skip-file
import pytest
from ingestion.base_connector import BaseConnector, AbstractSession, ensure_session


class TestBaseConnector:
    @pytest.fixture
    def mock_session(self):
        class CustomSession(AbstractSession):
            async def connect(self):
                pass
            async def close(self):
                pass
        return CustomSession()

    @pytest.fixture
    def mock_connector(self, mock_session):
        class CustomConnector(BaseConnector):
            def __init__(self):
                super().__init__()
                self.closed = True
            async def connect(self):
                self.session = mock_session
            async def disconnect(self):
                await super().disconnect()
                self.closed = False
            @ensure_session
            async def test_func(self):
                return True
        return CustomConnector()

    async def test_context(self, mock_connector):
        async with mock_connector as conn:
            assert conn.closed is True
        assert conn.closed is False

    async def test_ensure_session(self, mock_connector):
        with pytest.raises(TypeError):
            await mock_connector.test_func()
        async with mock_connector:
            assert await mock_connector.test_func() is True
