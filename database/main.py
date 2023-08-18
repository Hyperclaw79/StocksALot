"""A FastAPI server that connects to a PostgreSQL database."""
import asyncio
import os
from fastapi import FastAPI
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from fastapi.params import Path
from psycopg.sql import SQL, Identifier

from dbconn import DatabaseConnection
from rcbconn import RabbitMQConnector


def fetch_password(pwd_name: str, default: str = None) -> str:
    """Get the password for the database."""
    if pwd := os.getenv(pwd_name):
        return pwd
    if pwd_file := os.getenv(f"{pwd_name}_FILE"):
        with open(pwd_file, encoding='utf-8') as password_file:
            return password_file.read().strip()
    return default


app = FastAPI()
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
    asyncio.create_task(
        rmq_handler.periodic_consume("ohlc", process_data, 120)
    )


@app.on_event("shutdown")
async def shutdown():
    """On API shutdown, disconnect from the database."""""
    await db_handler.disconnect()
    await rmq_handler.disconnect()


@app.get('/tickers')
async def get_tickers() -> JSONResponse:
    """Get all tickers."""
    items = await db_handler.fetchall(
        SQL("SELECT {fields} FROM {table}").format(
            fields=SQL(', ').join(map(Identifier, ["ticker", "name"])),
            table=Identifier("tickers")
        )
    )
    response = {"count": len(items), "items": items}
    return JSONResponse(content=response)


@app.get('/tickers/{ticker}')
async def get_ticker(
    ticker: str = Path(..., description="The ticker symbol of the stock")
) -> JSONResponse:
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
    return JSONResponse(content=response)


@app.get('/ohlc')
async def get_ohlc() -> JSONResponse:
    """Get all OHLC data."""
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
    return JSONResponse(content=jsonable_encoder(response))


@app.post('/ohlc')
async def post_ohlc(ohlc: list[dict]) -> JSONResponse:
    """Post OHLC data."""
    if not ohlc:
        return JSONResponse(
            content={"error": "No records provided."},
            status_code=400
        )
    response = await process_data(ohlc)
    if not response:
        return JSONResponse(
            content={"error": "Error inserting data."},
            status_code=400
        )
    return JSONResponse(content={"status": "ok"}, status_code=201)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("DB_SERVER_PORT", 5000)))
