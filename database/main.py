"""A FastAPI server that connects to a PostgreSQL database."""
import asyncio
import os
from typing import Annotated

from fastapi import FastAPI, Depends, Request
from fastapi.responses import JSONResponse
from fastapi.params import Path
from psycopg.sql import SQL, Identifier

from utils import logger_factory
from dbconn import DatabaseConnection
from rcbconn import RabbitMQConnector
from auth import Authenticator, OAuth2PasswordBearer
from k8s_authorizer import KubernetesAPI
from models import (
    ErrorResponse, OHLC, OHLCResponse, RegisterUser,
    SuccessResponse, Ticker, TickersResponse, Token, User
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
    summary="External API to access the stocksalot data and insights."
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
authenticator = Authenticator(
    db_conn=db_handler,
    secret_key=os.getenv("API_TOKEN_SECRET"),
    expiry_days=int(os.getenv("API_TOKEN_EXPIRY_DAYS", "365"))
)
k8s_authorizer = KubernetesAPI()


async def get_username(request: Request):
    """Check if the request is internal."""
    internal_client = request.headers.get("X-Internal-Client")
    k8s_token = request.headers.get("X-Internal-Token")
    if (
        internal_client and k8s_token
        and await k8s_authorizer.validate_token(internal_client, k8s_token)
    ):
        return "internal"
    token = await OAuth2PasswordBearer(tokenUrl="token")(request)
    return await authenticator.get_current_user(token)


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
async def register_user(user_input: RegisterUser) -> SuccessResponse:
    """Register a user."""
    if user_input.username == "internal":
        return JSONResponse(
            content={"error": "You shall not pass."},
            status_code=403
        )
    if await db_handler.fetchone(
        SQL("SELECT * FROM users WHERE username = {username}").format(
            username=SQL("%s")
        ), (user_input.username,)
    ):
        return JSONResponse(
            content={"error": "User already exists."},
            status_code=409
        )
    fields = ["username", "password", "email"]
    query = SQL("INSERT INTO users ({fields}) VALUES ({values})").format(
        fields=SQL(', ').join(map(Identifier, fields)),
        values=SQL(', ').join([SQL("%s") for _ in fields])
    )
    user = user_input.model_dump()
    user["password"] = authenticator.get_password_hash(user["password"])
    res = await db_handler.insert(query, [user["username"], user["password"], user["email"]])
    if not res:
        return JSONResponse(
            content={"error": "Error inserting data."},
            status_code=400
        )
    return SuccessResponse(status="ok")


@app.post('/users/login', response_model=Token)
async def login_user(
    user: Annotated[
        User, Depends(authenticator.authenticate_user)
    ]
) -> Token:
    """Login a user."""
    token = authenticator.get_access_token(user)
    return Token(token=token)


@app.get('/tickers', response_model=TickersResponse)
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
    responses={404: {"model": ErrorResponse, "description": "Ticker not found."}}
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
    responses={401: {"model": ErrorResponse, "description": "Missing Bearer Token."}}
)
async def get_ohlc(username: Annotated[
    str, Depends(get_username)
]) -> OHLCResponse:
    """Get all OHLC data."""
    if username != "internal":
        logger.info("User %s requested all OHLC data.", username)
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
    username: Annotated[str, Depends(get_username)] = None
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


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("DB_SERVER_PORT", 5000)))
