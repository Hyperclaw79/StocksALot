# pylint: skip-file
from unittest import mock

from fastapi.testclient import TestClient
import pytest

from .fixtures import db_conn


@pytest.fixture
def client(db_conn):
    """Create a test client for the FastAPI app."""
    with mock.patch("dbconn.DatabaseConnection", db_conn):
        from main import app

        return TestClient(app)


async def test_get_tickers(client):
    """Test the GET /tickers endpoint."""
    response = client.get("/tickers")
    assert response.status_code == 200
    assert response.json() == {"count": 2, "items": [
        {"ticker": "AAPL", "name": "Apple"},
        {"ticker": "MSFT", "name": "Microsoft"}
    ]}


@pytest.mark.parametrize("test_input, expected", [
    ("AAPL", {"ticker": "AAPL", "name": "Apple"}),
    ("GOOG", {'error': 'Ticker not found.'}),
])
async def test_get_ticker(client, test_input, expected):
    """Test the GET /tickers/{ticker} endpoint."""
    response = client.get(f"/tickers/{test_input}")
    assert response.json() == expected


async def test_get_ohlc(client):
    """Test the GET /ohlc endpoint."""
    response = client.get("/ohlc")
    assert response.status_code == 200
    assert response.json() == {
        "count": 2,
        "items": [
            {
                "datetime": "2021-01-01 09:30:00",
                "timestamp": 1609459200,
                "ticker": "AAPL",
                "name": "Apple Inc.",
                "open": 133.52,
                "high": 135.99,
                "low": 133.52,
                "close": 135.99,
                "volume": 140,
                "source": "yahoo",
                "stored_company_name": "Apple"
            },
            {
                "datetime": "2021-01-01 09:30:00",
                "timestamp": 1609459200,
                "ticker": "MSFT",
                "name": "Microsoft Corporation",
                "open": 222.53,
                "high": 223.0,
                "low": 222.53,
                "close": 223.0,
                "volume": 100,
                "source": "yahoo",
                "stored_company_name": "Microsoft"
            }
        ]
    }



@pytest.mark.parametrize("test_input, expected", [
    (
        [{
            "datetime": "2021-01-02 09:30:00",
            "timestamp": 1609459200,
            "ticker": "AAPL",
            "name": "Apple Inc.",
            "open": 100.00,
            "high": 200.00,
            "low": 100.00,
            "close": 200.00,
            "volume": 100,
            "source": "yahoo"
        }],
        201
    ),
    # Duplicate primary key violation
    (
        [{
            "datetime": "2021-01-01 09:30:00",
            "timestamp": 1609459200,
            "ticker": "AAPL",
            "name": "Apple Inc.",
            "open": 100.00,
            "high": 200.00,
            "low": 100.00,
            "close": 200.00,
            "volume": 100,
            "source": "yahoo"
        }],
        400
    ),
    # Foreign key constraint violation
    (
        [{
            "datetime": "2021-01-02 09:30:00",
            "timestamp": 1609459200,
            "ticker": "RAND",
            "name": "Random Company",
            "open": 100.00,
            "high": 200.00,
            "low": 100.00,
            "close": 200.00,
            "volume": 100,
            "source": "yahoo"
        }],
        400
    ),
    # Missing fields
    (
        [{
            "datetime": "2021-01-02 09:30:00",
            "timestamp": 1609459200,
            "ticker": "AAPL",
            "name": "Apple Inc.",
            "open": 100.00,
            "high": 200.00,
            "low": 100.00,
            "close": 200.00,
            "volume": 100
        }],
        400
    ),
    # Empty list
    ([], 400),
    # Invalid data type
    (
        [{
            "datetime": "2021-01-02 09:30:00",
            "timestamp": 1609459200,
            "ticker": "AAPL",
            "name": "Apple Inc.",
            "open": None,
            "high": 200.00,
            "low": 100.00,
            "close": 200.00,
            "volume": 100,
            "source": "yahoo"
        }],
        400
    )
])
async def test_post_ohlc(client, test_input, expected):
    """Test the POST /ohlc endpoint."""
    response = client.post("/ohlc", json=test_input)
    assert response.status_code == expected
