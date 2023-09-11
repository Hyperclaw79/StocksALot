"""A FastAPI server that connects to a PostgreSQL database."""
import asyncio
import os
from typing import Annotated

from fastapi import FastAPI, Depends
from fastapi.responses import JSONResponse
from fastapi.params import Path

from utils import logger_factory, fetch_password
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


@app.on_event("startup")
async def startup():
    """On API startup, connect to the database."""""
    await db_handler.connect()
    await rmq_handler.connect()
    await k8s_authorizer.connect()
    asyncio.create_task(
        rmq_handler.periodic_consume(
            "ohlc", db_handler.process_ohlc, 120
        )
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
    try:
        items = await db_handler.get_tickers()
        response = {"count": len(items), "items": items}
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to get tickers.")
        logger.error(exc)
        response = {"count": 0, "items": []}
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
    try:
        response = await db_handler.get_ticker(ticker)
        if not response:
            return JSONResponse(
                content={"error": "Ticker not found."},
                status_code=404
            )
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to get ticker %s.", ticker)
        logger.error(exc)
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
    try:
        items = await db_handler.get_ohlc()
        response = {"count": len(items), "items": items}
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to get OHLC data.")
        logger.error(exc)
        response = {"count": 0, "items": []}
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
    try:
        response = await db_handler.process_ohlc(
            [record.model_dump() for record in ohlc]
        )
        if not response:
            return JSONResponse(
                content={"error": "Error inserting data."},
                status_code=400
            )
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to post OHLC data.")
        logger.error(exc)
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
    try:
        response = await db_handler.insert_companies(companies)
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to put company data.")
        logger.error(exc)
        return JSONResponse(
            content={"error": "Error inserting data."},
            status_code=400
        )
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
    try:
        items = await db_handler.get_latest_ohlc()
        response = {"count": len(items), "items": items}
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to get latest OHLC data.")
        logger.error(exc)
        response = {"count": 0, "items": []}
    return OHLCResponse(**response)


@app.get("/insights", response_model=InsightsResponse)
async def get_insights(
    username: Annotated[str, Depends(authenticator.get_current_user)]
) -> InsightsResponse:
    """Get insights from the latest stocks."""
    if username != "internal":
        logger.info("User %s requested for insights.", username)
    try:
        items = await db_handler.get_insights_input()
        result = await gpt_client.prompt(items)
        records = []
        for item in result.items:
            for insight in item.insights:
                record = insight.model_dump() | {"datetime": item.datetime}
                records.append(record)
        if records:
            try:
                await db_handler.insert_insights(records)
            except Exception as exc:  # pylint: disable=broad-except
                logger.warning("Failed to insert insights.")
                logger.warning(exc)
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to get insights.")
        logger.error(exc)
        result = InsightsResponse(count=0, items=[])
    return result


@app.get("/market_movers", response_model=MoversResponse, include_in_schema=False)
@app.get("/movers", response_model=MoversResponse)
async def get_market_movers(
    username: Annotated[str, Depends(authenticator.get_current_user)]
) -> MoversResponse:
    """Get the market movers."""
    if username != "internal":
        logger.info("User %s requested for market movers.", username)
    try:
        items = await db_handler.get_market_movers()
    except Exception as exc:  # pylint: disable=broad-except
        logger.error("Failed to get market movers.")
        logger.error(exc)
        items = []
    return MoversResponse(count=len(items), items=items)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("DB_SERVER_PORT", 5000)))
