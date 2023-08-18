# pylint: skip-file
from contextlib import nullcontext
import json
import pytest

from ingestion.base_ingestor import BaseIgnestionConfig, BaseIngestor


@pytest.fixture
def config():
    class CustomConfig(BaseIgnestionConfig):
        def parameter_dict(self):
            return {'mandatory': ['foo'], 'optional': ['bar']}
    return CustomConfig


@pytest.fixture
def mock_ingestor():
    class CustomIngestor(BaseIngestor):
        def fetch(self, *args, **kwargs):
            pass
        def ingest(self, *args, **kwargs):
            pass
    return CustomIngestor


@pytest.fixture
def mock_rbconn():
    class MockRBConn:
        async def publish(self, _, records):
            item: dict = json.loads(records)[0]
            return not item.get('fail')
    return MockRBConn


@pytest.fixture
def mock_dbconn():
    class MockDBConn:
        pass
    return MockDBConn


class TestBaseIngestionConfig:
    @pytest.mark.parametrize('test_inputs, expected', [
        ({'foo': 'baz'}, nullcontext({'foo': 'baz', 'bar': None})),
        ({'foo': 'baz', 'bar': 'qux'}, nullcontext({'foo': 'baz', 'bar': 'qux'})),
        ({'bar': 'qux'}, pytest.raises(ValueError))
    ])
    def test_load(self, config: type[BaseIgnestionConfig], test_inputs, expected):
        with expected as res:
            assert config(test_inputs).to_dict() == res


class TestBaseIngestor:
    @pytest.mark.parametrize('test_inputs, expected', [
        ([], pytest.raises(TypeError)),
        (['dbconn', 'rbconn'], nullcontext())
    ])
    def test_init(
        self, mock_ingestor: type[BaseIngestor], config,
        mock_dbconn, mock_rbconn,
        test_inputs, expected
    ):
        conn_dict = {'dbconn': mock_dbconn, 'rbconn': mock_rbconn}
        with expected:
            assert mock_ingestor(
                config({'foo': 'baz'}),
                *map(lambda x: conn_dict[x](), test_inputs)
            )

    @pytest.mark.parametrize('test_inputs, expected', [
        ([{'key': 'val'}], True),
        ([{'fail': True}], False),
        ([], False)
    ])
    async def test_store(
        self, mock_ingestor: type[BaseIngestor], config,
        mock_dbconn, mock_rbconn,
        test_inputs, expected
    ):
        test_ingestor = mock_ingestor(
            config({'foo': 'baz'}),
            mock_dbconn(),
            mock_rbconn()
        )
        resp = await test_ingestor.store(test_inputs)
        assert resp == expected
