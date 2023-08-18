#! /bin/bash
set -e

psql -v ON_ERROR_STOP=1 <<-EOSQL
    CREATE DATABASE $DB_NAME;
    CREATE USER $DB_USER WITH PASSWORD '$POSTGRES_PASSWORD';
    \c $DB_NAME;

    CREATE TABLE tickers (
        ticker VARCHAR(10) NOT NULL,
        name VARCHAR(50) NOT NULL,
        PRIMARY KEY (ticker)
    );

    INSERT INTO tickers (ticker, name) VALUES
        ('AAPL', 'APPLE INC.'),
        ('MSFT', 'MICROSOFT CORPORATION'),
        ('AMZN', 'AMAZON.COM, INC.'),
        ('GOOG', 'ALPHABET INC.'),
        ('META', 'Meta Platforms, Inc.'),
        ('TSLA', 'TESLA, INC.'),
        ('BRK.A', 'BERKSHIRE HATHAWAY INC.,'),
        ('NVDA', 'NVIDIA CORPORATION'),
        ('JPM', 'JPMORGAN CHASE & CO.'),
        ('JNJ', 'JOHNSON & JOHNSON'),
        ('V', 'VISA INC.'),
        ('UNH', 'UNITEDHEALTH GROUP INCORPORATED'),
        ('HD', 'THE HOME DEPOT, INC.'),
        ('PG', 'THE PROCTER & GAMBLE COMPANY'),
        ('MA', 'MASTERCARD INCORPORATED.'),
        ('DIS', 'THE WALT DISNEY COMPANY'),
        ('BAC', 'BANK OF AMERICA CORPORATION'),
        ('CMCSA', 'COMCAST CORPORATION'),
        ('XOM', 'EXXON MOBIL CORPORATION'),
        ('INTC', 'INTEL CORPORATION'),
        ('KO', 'THE COCA-COLA COMPANY'),
        ('NFLX', 'NETFLIX, INC.'),
        ('PFE', 'PFIZER INC.'),
        ('MRK', 'MERCK & CO., INC.'),
        ('CSCO', 'CISCO SYSTEMS, INC.'),
        ('WMT', 'WALMART INC.'),
        ('ABT', 'ABBOTT LABORATORIES'),
        ('CRM', 'SALESFORCE, INC.'),
        ('CVX', 'CHEVRON CORPORATION'),
        ('PEP', 'PEPSICO, INC.'),
        ('ORCL', 'ORACLE CORPORATION'),
        ('NKE', 'NIKE, INC.'),
        ('ABBV', 'ABBVIE INC.'),
        ('ACN', 'ACCENTURE PUBLIC LIMITED COMPANY'),
        ('TMO', 'THERMO FISHER SCIENTIFIC INC.'),
        ('MCD', 'MCDONALD''S CORPORATION'),
        ('COST', 'COSTCO WHOLESALE CORPORATION'),
        ('LLY', 'ELI LILLY AND COMPANY'),
        ('DHR', 'DANAHER CORPORATION'),
        ('TXN', 'TEXAS INSTRUMENTS INCORPORATED'),
        ('AVGO', 'Broadcom Inc.'),
        ('UPS', 'UNITED PARCEL SERVICE, INC.'),
        ('ADBE', 'ADOBE INC.'),
        ('LIN', 'LINDE PUBLIC LIMITED COMPANY'),
        ('AMD', 'ADVANCED MICRO DEVICES, INC.'),
        ('WFC', 'WELLS FARGO & COMPANY'),
        ('PM', 'Philip Morris International Inc.'),
        ('CAT', 'CATERPILLAR INC.'),
        ('MS', 'MORGAN STANLEY'),
        ('BA', 'THE BOEING COMPANY');

    CREATE TABLE ohlc (
        datetime TIMESTAMP NOT NULL,
        timestamp BIGINT NOT NULL,
        ticker VARCHAR(10) NOT NULL,
        name VARCHAR(50) NOT NULL,
        open NUMERIC(10, 2) NOT NULL,
        high NUMERIC(10, 2) NOT NULL,
        low NUMERIC(10, 2) NOT NULL,
        close NUMERIC(10, 2) NOT NULL,
        volume BIGINT NOT NULL,
        source VARCHAR(30) NOT NULL,
        PRIMARY KEY (ticker, datetime),
        FOREIGN KEY (ticker) REFERENCES tickers(ticker)
    );

    GRANT ALL PRIVILEGES
        ON ALL TABLES
        IN SCHEMA public
        TO $DB_USER;
EOSQL