# pylint: skip-file
from __future__ import annotations
from typing import TYPE_CHECKING
import pytest

if TYPE_CHECKING:
    from dbconn import DatabaseConnection

from .fixtures import db_conn


async def test_ping(db_conn: type[DatabaseConnection]):
    """Tests the connection and disconnection to the database."""
    db_conn_obj = db_conn(
        "postgres",
        "postgres",
        "localhost",
        5432,
        "test_db_2"
    )
    async with db_conn_obj as connection:
        assert connection.session is not None
    assert db_conn_obj.session.closed is True


async def test_fetchall(db_conn: type[DatabaseConnection]):
    """Tests fetching multiple entries."""
    async with db_conn(
        "postgres",
        "postgres",
        "localhost",
        5432,
        "test_db_2"
    ) as connection:
        query = "SELECT * FROM tickers"
        args = ()
        response = await connection.fetchall(query, *args)
        assert response == [
            {
                "ticker": "AAPL",
                "name": "Apple"
            },
            {
                "ticker": "MSFT",
                "name": "Microsoft"
            }
        ]


async def test_fetchone(db_conn: type[DatabaseConnection]):
    """Tests fetching a single entry."""
    async with db_conn(
        "postgres",
        "postgres",
        "localhost",
        5432,
        "test_db_2"
    ) as connection:
        query = "SELECT * FROM tickers WHERE ticker = %s"
        args = ("AAPL",)
        response = await connection.fetchone(query, args)
        assert response == {
            "ticker": "AAPL",
            "name": "Apple"
        }


@pytest.mark.parametrize("query, args, expected", [
    # Single entry
    (
        "INSERT INTO tickers (ticker, name) VALUES (%s, %s)",
        ["RAND", "Random Company"], 
        True
    ),
    # Multiple entries
    (
        "INSERT INTO tickers (ticker, name) VALUES (%s, %s)",
        [
            ["RAND1", "Random Company 1"],
            ["RAND2", "Random Company 2"]
        ], 
        True
    ),
    # Missing arguments
    (
        "INSERT INTO tickers (ticker, name) VALUES (%s, %s)",
        [],
        False
    ),
    # Invalid query
    (
        "INSERT INTO dummy (ticker, name) VALUES (%s, %s)",
        ["RAND", "Random Company"],
        False
    )
])
async def test_insert(db_conn: type[DatabaseConnection], query, args, expected):
    """Tests inserting a single or multiple entries."""
    async with db_conn(
        "postgres",
        "postgres",
        "localhost",
        5432,
        "test_db_2"
    ) as connection:
        response = await connection.insert(query, args)
        assert response is expected
