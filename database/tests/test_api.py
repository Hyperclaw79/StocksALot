# pylint: skip-file
from datetime import datetime, timedelta
import os
from unittest import mock

from jose import jwt
from fastapi.testclient import TestClient
import pytest

from .fixtures import db_conn, gpt_client_fixture, k8s_auth_fixture


@pytest.fixture
def client(db_conn, gpt_client_fixture, k8s_auth_fixture):
    """Create a test client for the FastAPI app."""
    with (
        mock.patch("dbconn.DatabaseConnection", db_conn) as _,
        mock.patch("gpt_client.GptClient", gpt_client_fixture) as _,
        mock.patch("k8s_authorizer.KubernetesAPI", k8s_auth_fixture) as _,
    ):
        from main import app

        return TestClient(app)


@pytest.fixture(scope="module", autouse=True)
def valid_token():
    """Create a valid token."""
    os.environ["API_TOKEN_SECRET"] = "test_secret"
    expires = datetime.utcnow() + timedelta(days=365)
    return jwt.encode({"sub": "test", "exp": expires}, "test_secret", algorithm="HS256")


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


@pytest.mark.parametrize("headers, expected", [
    (
        {}, {"status": 401, "json": {"detail": "Not authenticated"}},
    ),
    (
        {
            "Authorization": "Bearer blahblah",
            "X-Internal-Client": "blahblah"
        }, {"status": 401, "json": {'detail': 'Could not validate credentials'}},
    ),
    (
        {
            "Authorization": "Bearer blahblah",
            "X-Internal-Client": "blahblah",
            "X-Internal-Token": "blahblah"
        }, {"status": 200, "json": {
            "count": 2,
            "items": [
                {
                    "datetime": "2021-01-01T09:30:00",
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
                    "datetime": "2021-01-01T09:30:00",
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
        }}
    ),
])
async def test_get_ohlc(client, valid_token, headers, expected):
    """Test the GET /ohlc endpoint."""
    response = client.get("/ohlc", headers=headers)
    assert response.status_code == expected["status"]
    assert response.json() == expected["json"]



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
        422
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
        422
    )
])
async def test_post_ohlc(client, test_input, expected):
    """Test the POST /ohlc endpoint."""
    response = client.post("/ohlc", json=test_input, headers={
        "Authorization": "Bearer blahblah",
        "X-Internal-Client": "blahblah",
        "X-Internal-Token": "blahblah"
    })
    assert response.status_code == expected


@pytest.mark.parametrize("test_input, expected", [
    # New Valid Company
    (
        [{
            "ticker": "RAND",
            "name": "Random Company",
            "website": "https://random.com",
            "country": "USA",
            "logo": "https://random.com/logo.png",
            "industry": "Random Industry",
            "exchange": "Random Exchange",
            "phone": "1234567890",
            "market_cap": 1000000000,
            "num_shares": 1000000000
        }], 200
    ),
    # Existing Company
    (
        [{
            "ticker": "AAPL",
            "name": "Random Company",
            "website": "https://random.com",
            "country": "USA",
            "logo": "https://random.com/logo.png",
            "industry": "Random Industry",
            "exchange": "Random Exchange",
            "phone": "1234567890",
            "market_cap": 1000000000,
            "num_shares": 1000000000
        }], 200
    ),
    # Missing fields
    (
        [{
            "ticker": "RAND",
            "name": "Random Company",
            "website": "https://random.com",
            "logo": "https://random.com/logo.png",
            "industry": "Random Industry",
            "exchange": "Random Exchange",
            "phone": "1234567890",
            "market_cap": 1000000000,
            "num_shares": 1000000000
        }], 422
    ),
    # Invalid data type
    (
        [{
            "ticker": "RAND",
            "name": "Random Company",
            "website": "https://random.com",
            "country": "USA",
            "logo": "https://random.com/logo.png",
            "industry": "Random Industry",
            "exchange": "Random Exchange",
            "phone": "1234567890",
            "market_cap": 1000000000,
            "num_shares": "nan"
        }], 422
    )
])
async def test_put_companies(client, test_input, expected):
    """Test the PUT /companies endpoint."""
    response = client.put("/companies", json=test_input, headers={
        "Authorization": "Bearer blahblah",
        "X-Internal-Client": "blahblah",
        "X-Internal-Token": "blahblah"
    })
    assert response.status_code == expected


@pytest.mark.parametrize("test_input, expected", [
    # New Valid User
    (
        {
            "username": "test2",
            "password": "test",
            "email": "test2@test.com"
        }, 201
    ),
    # Duplicate username
    (
        {
            "username": "test",
            "password": "test",
            "email": "test@test.com"
        }, 409
    ),
    # Internal as username
    (
        {
            "username": "internal",
            "password": "test",
            "email": "test3@test.com"
        }, 403
    ),
    # Missing fields
    (
        {
            "username": "test2",
            "password": "test"
        }, 422
    ),
    # Invalid data type
    (
        {
            "username": "test2",
            "password": "test",
            "email": 123
        }, 422
    )
])
async def test_register_user(client, test_input, expected):
    """Test the POST /users/register endpoint."""
    response = client.post(
        "/users/register",
        data=test_input,
        headers={'content-type': 'application/x-www-form-urlencoded'}
    )
    assert response.status_code == expected


@pytest.mark.parametrize("test_input, expected", [
    # Valid login
    (
        {
            "username": "test",
            "password": "test"
        }, 200
    ),
    # Invalid username
    (
        {
            "username": "test2",
            "password": "test"
        }, 400
    ),
    # Invalid password
    (
        {
            "username": "test",
            "password": "test2"
        }, 400
    ),
    # Missing fields
    (
        {
            "username": "test"
        }, 422
    ),
    # Invalid data type
    (
        {
            "username": "test",
            "password": 123
        }, 400
    )
])
async def test_login_user(client, test_input, expected):
    """Test the POST /users/login endpoint."""
    response = client.post(
        "/token",
        data=test_input,
        headers={'content-type': 'application/x-www-form-urlencoded'}
    )
    assert response.status_code == expected


async def test_get_latest_ohlc(client):
    """Test the GET /latest endpoint."""
    response = client.get("/latest", headers={
        "Authorization": "Bearer blahblah",
        "X-Internal-Client": "blahblah",
        "X-Internal-Token": "blahblah"
    })
    assert response.status_code == 200
    assert response.json() == {"count": 2, "items": [
        {
            "datetime": "2021-01-01T09:30:00",
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
            "datetime": "2021-01-01T09:30:00",
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
    ]}


async def test_insights(client):
    """Test the GET /insights endpoint."""
    response = client.get("/insights", headers={
        "Authorization": "Bearer blahblah",
        "X-Internal-Client": "blahblah",
        "X-Internal-Token": "blahblah"
    })
    assert response.status_code == 200


async def test_market_movers(client):
    """Test the GET /movers endpoint."""
    response = client.get("/movers", headers={
        "Authorization": "Bearer blahblah",
        "X-Internal-Client": "blahblah",
        "X-Internal-Token": "blahblah"
    })
    assert response.status_code == 200
