"""Creates the Database Connection and Exposes it."""
from __future__ import annotations
import asyncio
from functools import wraps
import sys
from typing import TYPE_CHECKING

import psycopg
from psycopg.rows import dict_row
from psycopg.pq import ExecStatus

from base_connector import BaseConnector
from utils import logger_factory

if TYPE_CHECKING:
    from psycopg.sql import Composed


logger = logger_factory(__name__)


def ensure_session(func: callable):
    """Ensure that the connection is open."""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        """Wrapper function."""
        if args[0].session is None:
            await args[0].connect()
        return await func(*args, **kwargs)
    return wrapper


# pylint: disable=too-many-arguments
class DatabaseConnection(BaseConnector):
    """Database Connection Class."""
    def __init__(
        self, user: str, password: str,
        host: str, port: str,
        database: str
    ):
        super().__init__()
        self.session: psycopg.AsyncConnection
        self.conn_str = f"postgresql://{user}:{password}@{host}:{port}/{database}"
        if sys.platform == "win32":
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    async def connect(self):
        """Connect to the database."""
        logger.info("Connecting to database...")
        while not self.session:
            try:
                self.session = await psycopg.AsyncConnection.connect(
                    self.conn_str, row_factory=dict_row,
                    autocommit=True
                )
                logger.success("Connected to the Database.")
            except psycopg.errors.Error:
                logger.warning("Failed to connect to Database. Retrying in 10 seconds...")
                await asyncio.sleep(10)

    async def disconnect(self):
        """Disconnect from the database."""
        logger.info("Disconnecting from database...")
        await super().disconnect()

    @ensure_session
    async def fetchall(self, query: Composed | str, *args) -> list[dict]:
        """Fetch a query."""
        async with self.session.cursor() as cursor:
            try:
                await cursor.execute(query, *args)
                logger.info("Fetched all rows.")
                return await cursor.fetchall()
            except psycopg.errors.Error as exp:
                logger.error(exp)
                return []

    @ensure_session
    async def fetchone(self, query: Composed | str, *args) -> dict:
        """Fetch a single row."""
        async with self.session.cursor() as cursor:
            try:
                await cursor.execute(query, *args)
                logger.info("Fetched a single row.")
                return await cursor.fetchone()
            except psycopg.errors.Error as exp:
                logger.error(exp)
                return None

    @ensure_session
    async def insert(self, query: Composed | str, *args) -> bool:
        """Insert a single or multiple rows."""
        async with self.session.cursor() as cursor:
            try:
                values = args[0]
                if not values:
                    return False
                if isinstance(values[0], list):
                    await cursor.executemany(query, values, returning=True)
                else:
                    await cursor.execute(query, values)
                logger.success("Inserted %s rows.", len(values))
                return (
                    cursor.pgresult
                    and 'OK' in ExecStatus(cursor.pgresult.status).name
                )
            except psycopg.errors.Error as exp:
                logger.error(exp)
                return False
