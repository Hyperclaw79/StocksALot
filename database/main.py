"""A FastAPI server that connects to a PostgreSQL database."""
import asyncio
import os
from typing import Annotated

from fastapi import FastAPI, Depends
from fastapi.responses import JSONResponse
from fastapi.params import Path
from psycopg.sql import SQL, Identifier

from utils import logger_factory
from dbconn import DatabaseConnection
from rcbconn import RabbitMQConnector
from auth import Authenticator
from k8s_authorizer import KubernetesAPI
from gpt_client import GptClient
from models import (
    Company, ErrorResponse, OHLC, OHLCResponse, SuccessResponse,
    Ticker, TickersResponse, Token, User, InsightsResponse,
    MoversResponse
)

def fetch_password(pwd_name: str, default: str = None) -> str:
    """Get the password for the database."""
    if pwd := os.getenv(pwd_name):
        return pwd
    if pwd_file := os.getenv(f"{pwd_name}_FILE"):
        with open(pwd_file, encoding='utf-8') as password_file:
            return password_file.read().strip()
    return default


logger = logger_factory("API Server")


app = FastAPI(
    title="StocksALot API",
    summary="External API to access the StocksALot data and insights."
)


db_handler=DatabaseConnection(
    user=os.getenv("DATABASE_USER", "postgres"),
    password=fetch_password("DATABASE_PASSWORD"),
    host=os.getenv("DATABASE_HOST", "localhost"),
    port=int(os.getenv("DATABASE_PORT", "5432")),
    database=os.getenv("DATABASE_NAME", "stocks")
)
rmq_handler=RabbitMQConnector(
    host=os.getenv("RABBITMQ_HOST", "localhost"),
    port=int(os.getenv("RABBITMQ_PORT", "5672")),
    username=os.getenv("RABBITMQ_USER", "guest"),
    password=fetch_password("RABBITMQ_PASSWORD", default="guest")
)
k8s_authorizer = KubernetesAPI()
authenticator = Authenticator(
    db_conn=db_handler,
    k8s_authorizer=k8s_authorizer,
    secret_key=os.getenv("API_TOKEN_SECRET"),
    expiry_days=int(os.getenv("API_TOKEN_EXPIRY_DAYS", "365"))
)
gpt_client = GptClient(
    api_key=fetch_password("GPT_API_KEY")
)


async def process_data(ohlc: list[dict]):
    """Process the OHLC data."""
    keys = ohlc[0].keys()
    query = SQL("INSERT INTO ohlc ({fields}) VALUES ({values})").format(
        fields=SQL(', ').join(map(Identifier, keys)),
        values=SQL(', ').join([SQL("%s") for _ in keys])
    )
    values = [[row[key] for key in keys] for row in ohlc]
    return await db_handler.insert(query, values)


@app.on_event("startup")
async def startup():
    """On API startup, connect to the database."""""
    await db_handler.connect()
    await rmq_handler.connect()
    await k8s_authorizer.connect()
    asyncio.create_task(
        rmq_handler.periodic_consume("ohlc", process_data, 120)
    )


@app.on_event("shutdown")
async def shutdown():
    """On API shutdown, disconnect from the database."""""
    await db_handler.disconnect()
    await rmq_handler.disconnect()
    await k8s_authorizer.disconnect()


@app.post(
    '/users/register',
    response_model=SuccessResponse,
    status_code=201,
    responses={
        409: {"model": ErrorResponse, "description": "User already exists."},
        400: {"model": ErrorResponse, "description": "Error inserting data."},
        403: {"model": ErrorResponse, "description": "You shall not pass."}
    }
)
async def register_user(
    user: Annotated[User, Depends(authenticator.register_user)]
) -> SuccessResponse:
    """Register a user."""
    if user.username == "forbidden":
        return JSONResponse(
            content={"error": "You shall not pass."},
            status_code=403
        )
    if user.username == "exists":
        return JSONResponse(
            content={"error": "User already exists."},
            status_code=409
        )
    logger.info("Registered user %s.", user.username)
    return SuccessResponse(status="ok")


@app.post('/token', response_model=Token)
async def login_user(
    token: Annotated[
        Token, Depends(authenticator.authenticate_user)
    ]
) -> Token:
    """Login a user."""
    return token


@app.get('/tickers', response_model=TickersResponse, openapi_extra={
    "description": """
    NOTE: This endpoint is for testing the API without authentication.
    """
})
async def get_tickers() -> TickersResponse:
    """Get all tickers."""
    items = await db_handler.fetchall(
        SQL("SELECT {fields} FROM {table}").format(
            fields=SQL(', ').join(map(Identifier, ["ticker", "name"])),
            table=Identifier("tickers")
        )
    )
    response = {"count": len(items), "items": items}
    return TickersResponse(**response)


@app.get(
    '/tickers/{ticker}',
    response_model=Ticker,
    responses={404: {"model": ErrorResponse, "description": "Ticker not found."}},
    openapi_extra={
        "description": """
        NOTE: This endpoint is for testing the API without authentication.
        """
    }
)
async def get_ticker(
    ticker: str = Path(..., description="The ticker symbol of the stock")
) -> Ticker:
    """Get a ticker."""
    response = await db_handler.fetchone(
        SQL("SELECT {fields} FROM {table} WHERE ticker = {ticker}").format(
            fields=SQL(', ').join(map(Identifier, ["ticker", "name"])),
            table=Identifier("tickers"),
            ticker=SQL("%s")
        ),
        (ticker,)
    )
    if not response:
        return JSONResponse(
            content={"error": "Ticker not found."},
            status_code=404
        )
    return Ticker(**response)


@app.get(
    '/ohlc',
    response_model=OHLCResponse,
    include_in_schema=False,
    responses={401: {"model": ErrorResponse, "description": "Missing Bearer Token."}}
)
async def get_ohlc(
    username: Annotated[str, Depends(authenticator.get_current_user)]
) -> OHLCResponse:
    """Get all OHLC data."""
    if username != "internal":
        logger.info("User %s requested all the OHLC data.", username)
        return JSONResponse(
            content={"error": "You shall not pass."},
            status_code=403
        )
    items = await db_handler.fetchall(
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
    response = {"count": len(items), "items": items}
    return OHLCResponse(**response)


@app.post('/ohlc', status_code=201, include_in_schema=False)
async def post_ohlc(
    ohlc: list[OHLC],
    username: Annotated[str, Depends(authenticator.get_current_user)] = None
) -> SuccessResponse:
    """Post OHLC data."""
    if username != "internal":
        logger.info("User %s posted %s OHLC records.", username, len(ohlc))
        return JSONResponse(
            content={"error": "You shall not pass."},
            status_code=403
        )
    if not ohlc:
        return JSONResponse(
            content={"error": "No records provided."},
            status_code=400
        )
    response = await process_data([record.model_dump() for record in ohlc])
    if not response:
        return JSONResponse(
            content={"error": "Error inserting data."},
            status_code=400
        )
    return SuccessResponse(status="ok")


@app.put('/companies', status_code=200, include_in_schema=False)
async def put_companies(
    companies: list[Company],
    username: Annotated[str, Depends(authenticator.get_current_user)]
) -> SuccessResponse:
    """Put company data."""
    if username != "internal":
        logger.info("User %s put %s company records.", username, len(companies))
        return JSONResponse(
            content={"error": "You shall not pass."},
            status_code=403
        )
    if not companies:
        return JSONResponse(
            content={"error": "No records provided."},
            status_code=400
        )
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
    response = await db_handler.insert(query, values)
    if not response:
        return JSONResponse(
            content={"error": "Error inserting data."},
            status_code=400
        )
    return SuccessResponse(status="ok")


@app.get("/latest", response_model=OHLCResponse, openapi_extra={
    "summary": "Get the latest OHLC data.",
    "description": """
    Note: This endpoint does not provide price deltas.
    Caching should be implemented on the client side.
    """
})
async def get_latest_ohlc(
    username: Annotated[
    str, Depends(authenticator.get_current_user)
]) -> OHLCResponse:
    """Get the latest OHLC data."""
    if username != "internal":
        logger.info("User %s requested the latest OHLC data.", username)
    items = await db_handler.fetchall(
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
    response = {"count": len(items), "items": items}
    return OHLCResponse(**response)


@app.get("/insights", response_model=InsightsResponse)
async def get_insights(
    username: Annotated[str, Depends(authenticator.get_current_user)]
) -> InsightsResponse:
    """Get insights from the latest stocks."""
    if username != "internal":
        logger.info("User %s requested for insights.", username)
    items = await db_handler.fetchall(
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
    result = await gpt_client.prompt(items)
    records = []
    for item in result.items:
        for insight in item.insights:
            record = insight.model_dump() | {"datetime": item.datetime}
            records.append(record)
    if records:
        await db_handler.insert(
            SQL("INSERT INTO insights ({fields}) VALUES ({values})").format(
                fields=SQL(', ').join(map(Identifier, records[0].keys())),
                values=SQL(', ').join([SQL("%s") for _ in records[0].keys()])
            ),
            [list(record.values()) for record in records]
        )
    return result


@app.get("/market_movers", response_model=MoversResponse, include_in_schema=False)
@app.get("/movers", response_model=MoversResponse)
async def get_market_movers(
    username: Annotated[str, Depends(authenticator.get_current_user)]
) -> MoversResponse:
    """Get the market movers."""
    if username != "internal":
        logger.info("User %s requested for market movers.", username)
    items = await db_handler.fetchall(
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
    return MoversResponse(count=len(items), items=items)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("DB_SERVER_PORT", 5000)))
