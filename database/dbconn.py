"""Creates the Database Connection and Exposes it."""
from __future__ import annotations
import asyncio
import sys
from typing import TYPE_CHECKING

import psycopg
from psycopg.rows import dict_row
from psycopg.pq import ExecStatus
from psycopg.sql import SQL, Identifier

from base_connector import BaseConnector
from utils import logger_factory, ensure_session

if TYPE_CHECKING:
    from psycopg.sql import Composed
    from models import Company


logger = logger_factory(__name__)


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

    @ensure_session
    async def process_ohlc(self, ohlc: list[dict]) -> bool:
        """Process the OHLC data."""
        keys = ohlc[0].keys()
        query = SQL("INSERT INTO ohlc ({fields}) VALUES ({values})").format(
            fields=SQL(', ').join(map(Identifier, keys)),
            values=SQL(', ').join([SQL("%s") for _ in keys])
        )
        values = [[row[key] for key in keys] for row in ohlc]
        return await self.insert(query, values)

    @ensure_session
    async def get_tickers(self) -> list[str]:
        """Get the tickers from the database."""
        return await self.fetchall(
            SQL("SELECT {fields} FROM {table}").format(
                fields=SQL(', ').join(map(Identifier, ["ticker", "name"])),
                table=Identifier("tickers")
            )
        )

    @ensure_session
    async def get_ticker(self, ticker: str) -> dict:
        """Get a ticker from the database."""
        return await self.fetchone(
            SQL("SELECT {fields} FROM {table} WHERE ticker = {ticker}").format(
                fields=SQL(', ').join(map(Identifier, ["ticker", "name"])),
                table=Identifier("tickers"),
                ticker=SQL("%s")
            ),
            (ticker,)
        )

    @ensure_session
    async def get_ohlc(self) -> list[dict]:
        """Get the OHLC data from the database."""
        return await self.fetchall(
            SQL("""
                SELECT {ohlc}.*, {ticker}.name AS stored_company_name
                    FROM {ohlc}
                    JOIN {ticker}
                        ON {ticker}.ticker = {ohlc}.ticker;
            """).format(
                ohlc=Identifier("ohlc"),
                ticker=Identifier("tickers")
            )
        )

    @ensure_session
    async def insert_companies(self, companies: list[Company]) -> bool:
        """Insert the companies to the database."""
        query = SQL("""
            UPDATE {company}
            SET
                ticker = updater.ticker,
                name = updater.name,
                industry = updater.industry,
                exchange = updater.exchange,
                website = updater.website,
                phone = updater.phone,
                country = updater.country,
                logo = updater.logo,
                market_cap = updater.market_cap,
                num_shares = updater.num_shares
            FROM (
                VALUES
                    (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ) AS updater (
                ticker, name, industry, exchange, website, phone,
                country, logo, market_cap, num_shares
            )
            WHERE {company}.ticker = updater.ticker;
        """).format(
            company=Identifier("companies")
        )
        values = [[
            company.ticker, company.name, company.industry, company.exchange,
            company.website, company.phone, company.country, company.logo,
            company.market_cap, company.num_shares
        ] for company in companies]
        return await self.insert(query, values)

    @ensure_session
    async def get_latest_ohlc(self) -> list[dict]:
        """Get the latest OHLC data from the database."""
        return await self.fetchall(
            SQL("""
                SELECT {ohlc}.*, {ticker}.name AS stored_company_name
                    FROM {ohlc}
                    JOIN {ticker}
                        ON {ticker}.ticker = {ohlc}.ticker
                    WHERE {ohlc}.datetime = (
                        SELECT MAX(datetime) FROM {ohlc}
                    );
            """).format(
                ohlc=Identifier("ohlc"),
                ticker=Identifier("tickers")
            )
        )

    @ensure_session
    async def get_insights_input(self) -> list[dict]:
        """Prepate the input for ChatGPT to extract insights from."""
        return await self.fetchall(
            SQL("""
                WITH dates AS (
                    SELECT DISTINCT datetime
                    FROM ohlc
                    ORDER BY datetime DESC
                    LIMIT 2
                ), history AS (
                    SELECT *,
                        LAG(volume) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_volume,
                        LAG(high) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_high,
                        LAG(low) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_low,
                        LAG(open) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_open,
                        LAG(close) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_close
                        FROM ohlc
                        JOIN dates USING (datetime)
                ), change_calc AS (
                    SELECT *,
                        CASE
                            WHEN prev_open IS NOT NULL
                            THEN abs((
                                    (open + close + high + low + volume) -
                                    (prev_open + prev_close + prev_high + prev_low + prev_volume)
                                ) / (
                                    prev_open + prev_close + prev_high + prev_low + prev_volume
                            ))
                            ELSE NULL
                        END AS change_ratio
                        FROM history
                ), top10 AS
                (
                    SELECT ticker
                    FROM change_calc
                    ORDER BY abs(change_ratio) DESC
                    LIMIT 10
                )

                SELECT
                    datetime, ticker, name,
                    open, high, low, close,
                    volume
                FROM ohlc
                JOIN top10 USING (ticker)
                JOIN dates USING (datetime)
                ORDER BY datetime DESC;
            """).format(
                ohlc=Identifier("ohlc")
            )
        )

    @ensure_session
    async def insert_insights(self, insights: list[dict]) -> bool:
        """Insert the insights to the database."""
        return await self.insert(
            SQL("INSERT INTO insights ({fields}) VALUES ({values})").format(
                fields=SQL(', ').join(map(Identifier, insights[0].keys())),
                values=SQL(', ').join([SQL("%s") for _ in insights[0].keys()])
            ),
            [list(record.values()) for record in insights]
        )

    @ensure_session
    async def get_market_movers(self) -> list[dict]:
        """Get the market movers from the database."""
        return await self.fetchall(
            SQL("""
                WITH dates AS (
                    SELECT DISTINCT datetime
                    FROM {ohlc}
                    ORDER BY datetime DESC
                    LIMIT 2
                ), history AS (
                    SELECT *,
                        LAG(volume) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_volume,
                        LAG(high) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_high,
                        LAG(low) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_low,
                        LAG(open) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_open,
                        LAG(close) OVER (PARTITION BY ticker ORDER BY datetime) AS prev_close
                        FROM {ohlc}
                        JOIN dates USING (datetime)
                ), change_calc AS (
                    SELECT *,
                        CASE
                            WHEN prev_open IS NOT NULL
                            THEN abs((
                                    (open + close + high + low + volume) -
                                    (prev_open + prev_close + prev_high + prev_low + prev_volume)
                                ) / (
                                    prev_open + prev_close + prev_high + prev_low + prev_volume
                            ))
                            ELSE NULL
                        END AS change_ratio,
                        CASE WHEN prev_open IS NOT NULL
                            THEN (open - prev_open)
                            ELSE 0
                        END AS open_delta,
                        CASE WHEN prev_close IS NOT NULL
                            THEN (close - prev_close)
                            ELSE 0
                        END AS close_delta,
                        CASE WHEN prev_high IS NOT NULL
                            THEN (high - prev_high)
                            ELSE 0
                        END AS high_delta,
                        CASE WHEN prev_low IS NOT NULL
                            THEN (low - prev_low)
                            ELSE 0
                        END AS low_delta,
                        CASE WHEN prev_volume IS NOT NULL
                            THEN (volume - prev_volume)
                            ELSE 0
                        END AS volume_delta
                        FROM history
                ), top10 AS
                (
                    SELECT *
                    FROM change_calc
                    ORDER BY abs(change_ratio) DESC
                    LIMIT 10
                )
                SELECT
                    row_to_json(company.*) AS profile,
                    json_build_object(
                        'open', top10.open,
                        'close', top10.close,
                        'high', top10.high,
                        'low', top10.low,
                        'volume', top10.volume
                    ) AS current_metrics,
                    json_build_object(
                        'open', top10.open_delta,
                        'close', top10.close_delta,
                        'high', top10.high_delta,
                        'low', top10.low_delta,
                        'volume', top10.volume_delta
                    ) AS metric_deltas
                FROM {ohlc}
                JOIN top10 USING (ticker)
                JOIN dates
                    ON top10.datetime = dates.datetime
                JOIN {company} AS company USING (ticker)
                ORDER BY top10.datetime DESC;
            """).format(
                ohlc=Identifier("ohlc"),
                company=Identifier("companies")
            )
        )

    @ensure_session
    async def check_user(self, username: str, email: str) -> bool:
        """Check if a user exists."""
        return await self.fetchone(
            SQL("""
                SELECT 1 FROM users
                    WHERE
                        username = {username}
                        OR email = {email}
            """).format(
                username=SQL("%s"),
                email=SQL("%s")
            ), (username, email)
        )

    @ensure_session
    async def create_user(self, email: str, password: str, username: str) -> bool:
        """Create a user."""
        fields = ["email", "password", "username"]
        values = [email, password, username]
        return await self.insert(
            SQL("""
                INSERT INTO users ({fields})
                VALUES ({values})
            """).format(
                fields=SQL(",").join(SQL(field) for field in fields),
                values=SQL(",").join(SQL("%s") for _ in values)
            ), values
        )

    @ensure_session
    async def get_user(self, username: str) -> dict:
        """Get a user."""
        return await self.fetchone(
            SQL("""
                SELECT * FROM users
                    WHERE username = {username}
            """).format(
                username=SQL("%s")
            ), (username,)
        )
