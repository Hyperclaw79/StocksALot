# pylint: skip-file
from datetime import datetime
import re
from unittest.mock import patch

from passlib.context import CryptContext
import psycopg
from psycopg.pq import ExecStatus
from psycopg.sql import Composed, Identifier, SQL
import pytest

from database.dbconn import DatabaseConnection


def extract_sql(sql: Composed | SQL | Identifier | str) -> list:
    """Extract the SQL query from a Composed object."""
    if isinstance(sql, (Identifier, SQL)):
        obj = sql._obj
        if isinstance(obj, tuple):
            obj = ','.join(list(obj))
        return obj
    return [extract_sql(elem) for elem in sql]


def sql_to_string(sql: Composed) -> str:
    """Convert a SQL query to a string."""
    combined = ''.join(
        ''.join(elem)
        if isinstance(elem, list) else elem
        for elem in extract_sql(sql)
    )
    return ' '.join(
        line.strip()
        for line in combined.split('\n')
        if set(line.strip())
    )


@pytest.fixture
def db_conn() -> type[DatabaseConnection]:
    with patch('psycopg.AsyncConnection.connect') as mock_connect:
        class MockPGResult:
            status = ExecStatus.EMPTY_QUERY
        class MockCursor:
            def __init__(self):
                self.table_pattern = re.compile(r"[FI][RN][OT][MO]\s{1}(\w+)\s*")
                self.join_pattern = re.compile(
                    r"SELECT\s+(?P<columns>.*?)\s+FROM\s+\w+\s+JOIN\s+"
                    r"(?P<foreign_table>\w+)\s+ON\s+\w+\."
                    r"(?P<matcher>\w+)\s"
                )
                self.col_pattern = re.compile(
                    r"(?P<table>\w+)\.(?P<column>[\*\w]+)"
                    r"(?:\sAS\s(?P<alias>\w+))?"
                )
                self.data = {
                    'tickers': [
                        {
                            "ticker": "AAPL",
                            "name": "Apple"
                        },
                        {
                            "ticker": "MSFT",
                            "name": "Microsoft"
                        }
                    ],
                    'ohlc': [
                        {
                            "datetime": datetime(2021, 1, 1, 9, 30, 0),
                            "timestamp": 1609459200,
                            "ticker": "AAPL",
                            "name": "Apple Inc.",
                            "open": 133.52,
                            "high": 135.99,
                            "low": 133.52,
                            "close": 135.99,
                            "volume": 140,
                            "source": "yahoo"
                        },
                        {
                            "datetime": datetime(2021, 1, 1, 9, 30, 0),
                            "timestamp": 1609459200,
                            "ticker": "MSFT",
                            "name": "Microsoft Corporation",
                            "open": 222.53,
                            "high": 223.00,
                            "low": 222.53,
                            "close": 223.00,
                            "volume": 100,
                            "source": "yahoo"
                        },
                    ],
                    'users': [
                        {
                            "username": "test",
                            "password": CryptContext(
                                schemes=["bcrypt"],
                                deprecated="auto"
                            ).hash("test"),
                            "email": "test@test.com"
                        }
                    ]
                }
                self.result_cache = []
                self.pgresult = MockPGResult()
            async def execute(self, query, *args, **kwargs):
                if isinstance(query, Composed):
                    query = sql_to_string(query)
                self.pgresult.status = ExecStatus.EMPTY_QUERY
                table_name = self.table_pattern.search(query).group(1)
                if table_name not in self.data:
                    raise psycopg.errors.UndefinedTable("Table does not exist.")
                # Simulate INSERT queries
                if query.startswith("INSERT INTO") and self._handle_insert(table_name, args):
                    self.data[table_name].append(dict(zip(self.data[table_name][0], args)))
                    self.pgresult.status = ExecStatus.COMMAND_OK
                    return True
                # Simulate SELECT queries
                if query.startswith("SELECT"):
                    # Simulate JOIN queries
                    if match := self.join_pattern.search(query):
                        result = self._handle_join(match)
                        self.result_cache.extend(result)
                        self.pgresult.status = ExecStatus.TUPLES_OK
                        return result
                    if "WHERE" not in query:
                        self.result_cache.extend(self.data[table_name])
                        self.pgresult.status = ExecStatus.TUPLES_OK
                        return self.data[table_name]
                    column, value = query.split("WHERE")[1].split("=")
                    column = column.strip()
                    value = args[0][0]
                    result = next(
                        (
                            record
                            for record in self.data[table_name]
                            if record.get(column) == value
                        ),
                        None,
                    )
                    self.result_cache.append(result)
                    self.pgresult.status = ExecStatus.TUPLES_OK
                    return result
                return None
            def _handle_join(self, match):
                column_list = [
                    self.col_pattern.search(column.strip()).groups()
                    for column in match.group("columns").split(",")
                ]
                for column in column_list[:]:
                    if column[1] == "*":
                        table_name = column[0]
                        column_list.remove(column)
                        column_list = [
                            (table_name, col, None)
                            for col in self.data[table_name][0]
                        ] + column_list
                results = [
                    [
                        record.get(column_name)
                        for record in self.data[table_name]
                    ]
                    for table_name, column_name, _ in column_list
                ]
                return [
                    dict(
                        zip(
                            [
                                (column[2] or column[1])
                                for column in column_list
                            ],
                            row,
                        )
                    )
                    for row in zip(*results)
                ]
            def _handle_insert(self, table_name, args):
                if not args:
                    raise psycopg.errors.SyntaxError("No values provided.")
                if not all(
                    all(record)
                    and (
                        not isinstance(record, (list, tuple))
                        or (
                            isinstance(record, (list, tuple))
                            and len(record) == len(self.data[table_name][0])
                        )
                    )
                    for record in args[0]
                ):
                    raise psycopg.errors.Error("Not all values are provided.")
                ticker_list = (
                        existing_record.get("ticker")
                        for existing_record in self.data["tickers"]
                    )
                if table_name == "ohlc" and any(
                    record[2] not in ticker_list
                    for record in args[0]
                ):
                    raise psycopg.errors.ForeignKeyViolation("Foreign key violation.")
                fk_list = (
                    (existing_record.get("datetime"), existing_record.get("ticker"))
                    for existing_record in self.data["ohlc"]
                )
                if table_name == "ohlc" and any(
                    (record[0], record[2]) in fk_list
                    for record in args[0]
                ):
                    raise psycopg.errors.UniqueViolation("Unique constraint violation.")
                return True
            async def fetchone(self, *args, **kwargs):
                return self.result_cache.pop(0)
            async def fetchall(self, *args, **kwargs):
                cached = self.result_cache
                self.result_cache = []
                return cached
            async def executemany(self, query, *args, **kwargs):
                self.pgresult.status = ExecStatus.EMPTY_QUERY
                if not args:
                    raise psycopg.errors.SyntaxError("No values provided.")
                if len(args) == 1:
                    return await self.execute(query, args[0], **kwargs)
                if isinstance(query, Composed):
                    query = sql_to_string(query)
                table_name = self.table_pattern.search(query).group(1)
                if table_name in self.data:
                    self.data[table_name].extend([
                        dict(zip(self.data[table_name][0], row))
                        for row in args[0]
                    ])
                    self.pgresult.status = ExecStatus.COMMAND_OK
                    return True
                raise psycopg.errors.UndefinedTable(f"Table {table_name} does not exist.")
            async def __aenter__(self):
                return self
            async def __aexit__(self, exc_type, exc, tb):
                pass
        class MockConnection:
            def __init__(self):
                self.closed = False
                self.cursor = MockCursor
            async def close(self):
                self.closed = True
            async def __aenter__(self):
                return self
            async def __aexit__(self, exc_type, exc, tb):
                pass
        mock_connect.return_value = MockConnection()
        yield DatabaseConnection
