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

    CREATE TABLE users (
        id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        username VARCHAR(50) NOT NULL,
        password VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE insights (
        id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        datetime TIMESTAMP NOT NULL,
        message VARCHAR(1000) NOT NULL,
        sentiment VARCHAR(10) NOT NULL CHECK (
            sentiment IN ('positive', 'negative', 'neutral')
        )
    );

    CREATE TABLE companies (
        ticker VARCHAR(10) NOT NULL,
        name VARCHAR(50) NOT NULL,
        website VARCHAR(100) NOT NULL,
        country VARCHAR(50) NOT NULL,
        logo VARCHAR(100) NOT NULL,
        industry VARCHAR(50) NULL,
        exchange VARCHAR(50) NULL,
        phone VARCHAR(20) NULL,
        market_cap BIGINT NULL,
        num_shares BIGINT NULL,
        PRIMARY KEY (ticker),
        FOREIGN KEY (ticker) REFERENCES tickers(ticker)
    );

    INSERT INTO companies (ticker, name, website, country, logo, industry, exchange, phone, market_cap, num_shares) VALUES
        ('AAPL', 'APPLE INC.', 'https://www.apple.com', 'United States', 'https://logo.clearbit.com/apple.com', 'Consumer Electronics', 'NASDAQ', '1-408-996-1010', 2470000000000, 16687500000),
        ('MSFT', 'MICROSOFT CORPORATION', 'https://www.microsoft.com', 'United States', 'https://logo.clearbit.com/microsoft.com', 'Software—Infrastructure', 'NASDAQ', '1-425-882-8080', 2220000000000, 7560000000),
        ('AMZN', 'AMAZON.COM, INC.', 'https://www.amazon.com', 'United States', 'https://logo.clearbit.com/amazon.com', 'Internet Retail', 'NASDAQ', '1-206-266-1000', 1660000000000, 500000000),
        ('GOOG', 'ALPHABET INC.', 'https://www.abc.xyz', 'United States', 'https://logo.clearbit.com/abc.xyz', 'Internet Content & Information', 'NASDAQ', '1-650-253-0000', 1660000000000, 680000000),
        ('META', 'Meta Platforms, Inc.', 'https://www.meta.com', 'United States', 'https://logo.clearbit.com/meta.com', 'Internet Content & Information', 'NASDAQ', '1-650-543-4800', 1000000000000, 2400000000),
        ('TSLA', 'TESLA, INC.', 'https://www.tesla.com', 'United States', 'https://logo.clearbit.com/tesla.com', 'Auto Manufacturers', 'NASDAQ', '1-650-681-5000', 1000000000000, 960000000),
        ('BRK.A', 'BERKSHIRE HATHAWAY INC.,', 'https://www.berkshirehathaway.com', 'United States', 'https://logo.clearbit.com/berkshirehathaway.com', 'Insurance—Diversified', 'NYSE', '1-402-346-1400', 1000000000000, 1000000),
        ('NVDA', 'NVIDIA CORPORATION', 'https://www.nvidia.com', 'United States', 'https://logo.clearbit.com/nvidia.com', 'Semiconductors', 'NASDAQ', '1-408-486-2000', 1000000000000, 620000000),
        ('JPM', 'JPMORGAN CHASE & CO.', 'https://www.jpmorganchase.com', 'United States', 'https://logo.clearbit.com/jpmorganchase.com', 'Banks—Diversified', 'NYSE', '1-212-270-6000', 500000000000, 3000000000),
        ('JNJ', 'JOHNSON & JOHNSON', 'https://www.jnj.com', 'United States', 'https://logo.clearbit.com/jnj.com', 'Drug Manufacturers—General', 'NYSE', '1-732-524-0400', 500000000000, 2600000000),
        ('V', 'VISA INC.', 'https://www.visa.com', 'United States', 'https://logo.clearbit.com/visa.com', 'Credit Services', 'NYSE', '1-650-432-3200', 500000000000, 2000000000),
        ('UNH', 'UNITEDHEALTH GROUP INCORPORATED', 'https://www.unitedhealthgroup.com', 'United States', 'https://logo.clearbit.com/unitedhealthgroup.com', 'Healthcare Plans', 'NYSE', '1-952-936-1300', 400000000000, 1000000000),
        ('HD', 'THE HOME DEPOT, INC.', 'https://www.homedepot.com', 'United States', 'https://logo.clearbit.com/homedepot.com', 'Home Improvement Retail', 'NYSE', '1-770-433-8211', 400000000000, 1000000000),
        ('PG', 'THE PROCTER & GAMBLE COMPANY', 'https://www.pg.com', 'United States', 'https://logo.clearbit.com/pg.com', 'Household & Personal Products', 'NYSE', '1-513-983-1100', 400000000000, 2600000000),
        ('MA', 'MASTERCARD INCORPORATED.', 'https://www.mastercard.com', 'United States', 'https://logo.clearbit.com/mastercard.com', 'Credit Services', 'NYSE', '1-914-249-2000', 400000000000, 1000000000),
        ('DIS', 'THE WALT DISNEY COMPANY', 'https://www.thewaltdisneycompany.com', 'United States', 'https://logo.clearbit.com/thewaltdisneycompany.com', 'Entertainment', 'NYSE', '1-818-560-1000', 300000000000, 1800000000),
        ('BAC', 'BANK OF AMERICA CORPORATION', 'https://www.bankofamerica.com', 'United States', 'https://logo.clearbit.com/bankofamerica.com', 'Banks—Diversified', 'NYSE', '1-704-386-5681', 300000000000, 8500000000),
        ('CMCSA', 'COMCAST CORPORATION', 'https://www.comcastcorporation.com', 'United States', 'https://logo.clearbit.com/comcastcorporation.com', 'Telecom Services', 'NASDAQ', '1-215-286-1700', 300000000000, 4500000000),
        ('XOM', 'EXXON MOBIL CORPORATION', 'https://www.exxonmobil.com', 'United States', 'https://logo.clearbit.com/exxonmobil.com', 'Oil & Gas Integrated', 'NYSE', '1-972-940-6000', 300000000000, 4500000000),
        ('INTC', 'INTEL CORPORATION', 'https://www.intel.com', 'United States', 'https://logo.clearbit.com/intel.com', 'Semiconductors', 'NASDAQ', '1-408-765-8080', 300000000000, 4300000000),
        ('KO', 'THE COCA-COLA COMPANY', 'https://www.coca-colacompany.com', 'United States', 'https://logo.clearbit.com/coca-colacompany.com', 'Beverages—Non-Alcoholic', 'NYSE', '1-404-676-2121', 300000000000, 4300000000),
        ('NFLX', 'NETFLIX, INC.', 'https://www.netflix.com', 'United States', 'https://logo.clearbit.com/net', 'Entertainment', 'NASDAQ', '1-408-540-3700', 300000000000, 450000000),
        ('PFE', 'PFIZER INC.', 'https://www.pfizer.com', 'United States', 'https://logo.clearbit.com/pfizer.com', 'Drug Manufacturers—General', 'NYSE', '1-212-733-2323', 300000000000, 5800000000),
        ('MRK', 'MERCK & CO., INC.', 'https://www.merck.com', 'United States', 'https://logo.clearbit.com/merck.com', 'Drug Manufacturers—General', 'NYSE', '1-908-740-4000', 300000000000, 2300000000),
        ('CSCO', 'CISCO SYSTEMS, INC.', 'https://www.cisco.com', 'United States', 'https://logo.clearbit.com/cisco.com', 'Communication Equipment', 'NASDAQ', '1-408-526-4000', 300000000000, 4300000000),
        ('WMT', 'WALMART INC.', 'https://www.walmart.com', 'United States', 'https://logo.clearbit.com/walmart.com', 'Discount Stores', 'NYSE', '1-479-273-4000', 300000000000, 2900000000),
        ('ABT', 'ABBOTT LABORATORIES', 'https://www.abbott.com', 'United States', 'https://logo.clearbit.com/abbott.com', 'Medical Devices', 'NYSE', '1-224-667-6100', 200000000000, 1800000000),
        ('CRM', 'SALESFORCE, INC.', 'https://www.salesforce.com', 'United States', 'https://logo.clearbit.com/salesforce.com', 'Software—Application', 'NYSE', '1-415-901-7000', 200000000000, 1000000000),
        ('CVX', 'CHEVRON CORPORATION', 'https://www.chevron.com', 'United States', 'https://logo.clearbit.com/chevron.com', 'Oil & Gas Integrated', 'NYSE', '1-925-842-1000', 200000000000, 1800000000),
        ('PEP', 'PEPSICO, INC.', 'https://www.pepsico.com', 'United States', 'https://logo.clearbit.com/pepsico.com', 'Beverages—Non-Alcoholic', 'NASDAQ', '1-914-253-2000', 200000000000, 1400000000),
        ('ORCL', 'ORACLE CORPORATION', 'https://www.oracle.com', 'United States', 'https://logo.clearbit.com/oracle.com', 'Software—Infrastructure', 'NYSE', '1-650-506-7000', 200000000000, 4000000000),
        ('NKE', 'NIKE, INC.', 'https://www.nike.com', 'United States', 'https://logo.clearbit.com/nike.com', 'Footwear & Accessories', 'NYSE', '1-503-671-6453', 200000000000, 1400000000),
        ('ABBV', 'ABBVIE INC.', 'https://www.abbvie.com', 'United States', 'https://logo.clearbit.com/abbvie.com', 'Drug Manufacturers—General', 'NYSE', '1-847-932-7900', 200000000000, 1800000000),
        ('ACN', 'ACCENTURE PUBLIC LIMITED COMPANY', 'https://www.accenture.com', 'United States', 'https://logo.clearbit.com/accenture.com', 'Information Technology Services', 'NYSE', '1-353-166-7000', 200000000000, 640000000),
        ('TMO', 'THERMO FISHER SCIENTIFIC INC.', 'https://www.thermofisher.com', 'United States', 'https://logo.clearbit.com/thermofisher.com', 'Life Sciences Tools & Services', 'NYSE', '1-781-622-1000', 200000000000, 400000000),
        ('MCD', 'MCDONALD''S CORPORATION', 'https://www.mcdonalds.com', 'United States', 'https://logo.clearbit.com/mcdonalds.com', 'Restaurants', 'NYSE', '1-630-623-3000', 200000000000, 750000000),
        ('COST', 'COSTCO WHOLESALE CORPORATION', 'https://www.costco.com', 'United States', 'https://logo.clearbit.com/costco.com', 'Discount Stores', 'NASDAQ', '1-425-313-8100', 200000000000, 440000000),
        ('LLY', 'ELI LILLY AND COMPANY', 'https://www.lilly.com', 'United States', 'https://logo.clearbit.com/lilly.com', 'Drug Manufacturers—General', 'NYSE', '1-317-276-2000', 200000000000, 1000000000),
        ('DHR', 'DANAHER CORPORATION', 'https://www.danaher.com', 'United States', 'https://logo.clearbit.com/danaher.com', 'Medical Devices', 'NYSE', '1-202-828-0850', 200000000000, 700000000),
        ('TXN', 'TEXAS INSTRUMENTS INCORPORATED', 'https://www.ti.com', 'United States', 'https://logo.clearbit.com/ti.com', 'Semiconductors', 'NASDAQ', '1-214-479-3773', 200000000000, 1000000000),
        ('AVGO', 'Broadcom Inc.', 'https://www.broadcom.com', 'United States', 'https://logo.clearbit.com/broadcom.com', 'Semiconductors', 'NASDAQ', '1-408-433-8000', 200000000000, 400000000),
        ('UPS', 'UNITED PARCEL SERVICE, INC.', 'https://www.ups.com', 'United States', 'https://logo.clearbit.com/ups.com', 'Integrated Freight & Logistics', 'NYSE', '1-404-828-6000', 200000000000, 700000000),
        ('ADBE', 'ADOBE INC.', 'https://www.adobe.com', 'United States', 'https://logo.clearbit.com/adobe.com', 'Software—Application', 'NASDAQ', '1-408-536-6000', 200000000000, 500000000),
        ('LIN', 'LINDE PUBLIC LIMITED COMPANY', 'https://www.linde.com', 'United States', 'https://logo.clearbit.com/linde.com', 'Chemicals', 'NYSE', '1-203-837-2000', 200000000000, 500000000),
        ('AMD', 'ADVANCED MICRO DEVICES, INC.', 'https://www.amd.com', 'United States', 'https://logo.clearbit.com/amd.com', 'Semiconductors', 'NASDAQ', '1-408-749-4000', 200000000000, 1200000000),
        ('WFC', 'WELLS FARGO & COMPANY', 'https://www.wellsfargo.com', 'United States', 'https://logo.clearbit.com/wellsfargo.com', 'Banks—Diversified', 'NYSE', '1-866-878-5865', 200000000000, 4200000000),
        ('PM', 'Philip Morris International Inc.', 'https://www.pmi.com', 'United States', 'https://logo.clearbit.com/pmi.com', 'Tobacco', 'NYSE', '1-917-663-2000', 200000000000, 1800000000),
        ('CAT', 'CATERPILLAR INC.', 'https://www.caterpillar.com', 'United States', 'https://logo.clearbit.com/caterpillar.com', 'Farm & Heavy Construction Machinery', 'NYSE', '1-309-675-1000', 200000000000, 600000000),
        ('MS', 'MORGAN STANLEY', 'https://www.morganstanley.com', 'United States', 'https://logo.clearbit.com/morganstanley.com', 'Capital Markets', 'NYSE', '1-212-761-4000', 200000000000, 1800000000),
        ('BA', 'THE BOEING COMPANY', 'https://www.boeing.com', 'United States', 'https://logo.clearbit.com/boeing.com', 'Aerospace & Defense', 'NYSE', '1-312-544-2000', 200000000000, 600000000);

    GRANT ALL PRIVILEGES
        ON ALL TABLES
        IN SCHEMA public
        TO $DB_USER;
EOSQL