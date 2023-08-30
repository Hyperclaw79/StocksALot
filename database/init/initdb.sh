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
        ('GOOGL', 'ALPHABET INC.'),
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
        ('INTU', 'INTUIT INC.'),
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

    INSERT INTO companies(ticker, name, website, country, logo, industry, exchange, phone, market_cap, num_shares) VALUES
        ('GOOGL', 'Alphabet Inc', 'https://abc.xyz/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/GOOG.svg', 'Media', 'NASDAQ NMS - GLOBAL MARKET', '+16502530000', 1702264, 12610),
        ('AAPL', 'Apple Inc', 'https://www.apple.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.svg', 'Technology', 'NASDAQ NMS - GLOBAL MARKET', '+14089961010', 2878574, 15634),
        ('MSFT', 'Microsoft Corp', 'https://www.microsoft.com/en-us', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/MSFT.svg', 'Technology', 'NASDAQ NMS - GLOBAL MARKET', '+14258828080', 2440008, 7429),
        ('AMZN', 'Amazon.com Inc', 'https://www.amazon.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AMZN.svg', 'Retail', 'NASDAQ NMS - GLOBAL MARKET', '+12062661000', 1384224, 10260),
        ('META', 'Meta Platforms Inc', 'https://investor.fb.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/FB.svg', 'Media', 'NASDAQ NMS - GLOBAL MARKET', '+16505434800', 766901, 2573),
        ('TSLA', 'Tesla Inc', 'https://www.tesla.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/TSLA.svg', 'Automobiles', 'NASDAQ NMS - GLOBAL MARKET', '+15125168177', 816287, 3173),
        ('BRK.A', 'Berkshire Hathaway Inc', 'https://www.berkshirehathaway.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/BRK.B.svg', 'Financial Services', 'NEW YORK STOCK EXCHANGE, INC.', '+14023461400', 781408, 1),
        ('NVDA', 'NVIDIA Corp', 'https://www.nvidia.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/NVDA.svg', 'Semiconductors', 'NASDAQ NMS - GLOBAL MARKET', '+14084862000', 1204964, 2470),
        ('JPM', 'JPMorgan Chase & Co', 'https://www.jpmorganchase.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/JPM.svg', 'Banking', 'NEW YORK STOCK EXCHANGE, INC.', '+12122706000', 432309, 2906),
        ('JNJ', 'Johnson & Johnson', 'https://www.jnj.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/JNJ.svg', 'Pharmaceuticals', 'NEW YORK STOCK EXCHANGE, INC.', '+17325242455', 427036, 2598),
        ('V', 'Visa Inc', 'https://usa.visa.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/V.svg', 'Financial Services', 'NEW YORK STOCK EXCHANGE, INC.', '+16504323200', 500142, 2036),
        ('UNH', 'UnitedHealth Group Inc', 'https://www.unitedhealthgroup.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/UNH.svg', 'Health Care', 'NEW YORK STOCK EXCHANGE, INC.', '+19529361300', 456510, 926),
        ('HD', 'Home Depot Inc', 'https://www.homedepot.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/HD.svg', 'Retail', 'NEW YORK STOCK EXCHANGE, INC.', '+17704338211', 329401, 1000),
        ('PG', 'Procter & Gamble Co', 'https://us.pg.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/PG.svg', 'Consumer products', 'NEW YORK STOCK EXCHANGE, INC.', '+15139831100', 362655, 2356),
        ('MA', 'Mastercard Inc', 'https://www.mastercard.us/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/MA.svg', 'Financial Services', 'NEW YORK STOCK EXCHANGE, INC.', '+19142492000', 387711, 941),
        ('DIS', 'Walt Disney Co', 'https://thewaltdisneycompany.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/DIS.svg', 'Media', 'NEW YORK STOCK EXCHANGE, INC.', '+18185601000', 154224, 1827),
        ('BAC', 'Bank of America Corp', 'https://www.bankofamerica.com', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/BAC.svg', 'Banking', 'NEW YORK STOCK EXCHANGE, INC.', '+17043868486', 231795, 7946),
        ('CMCSA', 'Comcast Corp', 'https://corporate.comcast.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/CMCSA.svg', 'Media', 'NASDAQ NMS - GLOBAL MARKET', '+12152861700', 192973, 4125),
        ('XOM', 'Exxon Mobil Corp', 'https://corporate.exxonmobil.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/XOM.svg', 'Energy', 'NEW YORK STOCK EXCHANGE, INC.', '+19729406000', 439590, 4003),
        ('INTC', 'Intel Corp', 'https://www.intel.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/INTC.svg', 'Semiconductors', 'NASDAQ NMS - GLOBAL MARKET', '+14087658080', 143690, 4188),
        ('KO', 'Coca-Cola Co', 'https://www.coca-colacompany.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/KO.svg', 'Beverages', 'NEW YORK STOCK EXCHANGE, INC.', '+14046762121', 261622, 4324),
        ('NFLX', 'Netflix Inc', 'https://www.netflix.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/NFLX.svg', 'Media', 'NASDAQ NMS - GLOBAL MARKET', '+14085403700', 190548, 443),
        ('INTU', 'Intuit Inc.', 'https://www.intuit.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/INTU.svg', 'Technology', 'NASDAQ NMS - GLOBAL MARKET', '+16509446000', 150249, 280),
        ('PFE', 'Pfizer Inc', 'https://www.pfizer.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/PFE.svg', 'Pharmaceuticals', 'NEW YORK STOCK EXCHANGE, INC.', '+12127332323', 204101, 5645),
        ('MRK', 'Merck & Co Inc', 'https://www.merck.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/MRK.svg', 'Pharmaceuticals', 'NEW YORK STOCK EXCHANGE, INC.', '+19087404000', 279101, 2537),
        ('CSCO', 'Cisco Systems Inc', 'https://www.cisco.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/950800186156.svg', 'Communications', 'NASDAQ NMS - GLOBAL MARKET', '+14085264000', 230485, 4075),
        ('WMT', 'Walmart Inc', 'https://corporate.walmart.com', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/WMT.svg', 'Retail', 'NEW YORK STOCK EXCHANGE, INC.', '+14792734000', 430988, 2692),
        ('ABT', 'Abbott Laboratories', 'https://www.abbott.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/ABT.svg', 'Health Care', 'NEW YORK STOCK EXCHANGE, INC.', '+12246676100', 180251, 1735),
        ('CRM', 'Salesforce Inc', 'https://www.salesforce.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/CRM.svg', 'Technology', 'NEW YORK STOCK EXCHANGE, INC.', '+14159017000', 206449, 974),
        ('CVX', 'Chevron Corp', 'https://www.chevron.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/CVX.svg', 'Energy', 'NEW YORK STOCK EXCHANGE, INC.', '+19258421000', 305139, 1907),
        ('PEP', 'PepsiCo Inc', 'https://www.pepsico.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/PEP.svg', 'Beverages', 'NASDAQ NMS - GLOBAL MARKET', '+19142532000', 249064, 1376),
        ('ORCL', 'Oracle Corp', 'https://www.oracle.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/ORCL.svg', 'Technology', 'NEW YORK STOCK EXCHANGE, INC.', '+17378671000', 327475, 2714),
        ('NKE', 'Nike Inc', 'https://about.nike.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/NKE.svg', 'Textiles, Apparel & Luxury Goods', 'NEW YORK STOCK EXCHANGE, INC.', '+15036713173', 155715, 1530),
        ('ABBV', 'Abbvie Inc', 'https://www.abbvie.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/ABBV.svg', 'Biotechnology', 'NEW YORK STOCK EXCHANGE, INC.', '+18479327900', 260503, 1765),
        ('ACN', 'Accenture PLC', 'https://www.accenture.com/ie-en/', 'IE', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/ACN.svg', 'Technology', 'NEW YORK STOCK EXCHANGE, INC.', '+35316462000', 214871, 664),
        ('TMO', 'Thermo Fisher Scientific Inc', 'https://www.thermofisher.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/TMO.svg', 'Life Sciences Tools & Services', 'NEW YORK STOCK EXCHANGE, INC.', '+17816221000', 214360, 385),
        ('MCD', 'McDonald''s Corp', 'https://www.mcdonalds.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/MCD.svg', 'Hotels, Restaurants & Leisure', 'NEW YORK STOCK EXCHANGE, INC.', '+16306233000', 206670, 728),
        ('COST', 'Costco Wholesale Corp', 'https://www.costco.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/COST.svg', 'Retail', 'NASDAQ NMS - GLOBAL MARKET', '+14253138100', 240527, 443),
        ('LLY', 'Eli Lilly and Co', 'https://www.lilly.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/LLY.svg', 'Pharmaceuticals', 'NEW YORK STOCK EXCHANGE, INC.', '+13172762000', 525814, 949),
        ('DHR', 'Danaher Corp', 'https://www.danaher.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/DHR.svg', 'Life Sciences Tools & Services', 'NEW YORK STOCK EXCHANGE, INC.', '+12028280850', 194924, 738),
        ('TXN', 'Texas Instruments Inc', 'https://www.ti.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/TXN.svg', 'Semiconductors', 'NASDAQ NMS - GLOBAL MARKET', '+19729953773', 154980, 907),
        ('AVGO', 'Broadcom Inc', 'https://www.broadcom.com', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AVGO.svg', 'Semiconductors', 'NASDAQ NMS - GLOBAL MARKET', '+14084338000', 367261, 412),
        ('UPS', 'United Parcel Service Inc', 'https://www.ups.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/UPS.svg', 'Logistics & Transportation', 'NEW YORK STOCK EXCHANGE, INC.', '+14048286000', 146893, 855),
        ('ADBE', 'Adobe Inc', 'https://www.adobe.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/ADBE.svg', 'Technology', 'NASDAQ NMS - GLOBAL MARKET', '+14085366000', 246391, 455),
        ('AMD', 'Advanced Micro Devices Inc', 'https://www.amd.com/en', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AMD.svg', 'Semiconductors', 'NASDAQ NMS - GLOBAL MARKET', '+14087494000', 171131, 1615),
        ('WFC', 'Wells Fargo & Co', 'https://www.wellsfargo.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/WFC.svg', 'Banking', 'NEW YORK STOCK EXCHANGE, INC.', '+16126671234', 153668, 3658),
        ('PM', 'Philip Morris International Inc', 'https://www.pmi.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/PM.svg', 'Tobacco', 'NEW YORK STOCK EXCHANGE, INC.', '+12039052410', 149413, 1552),
        ('CAT', 'Caterpillar Inc', 'https://www.caterpillar.com', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/CAT.svg', 'Machinery', 'NEW YORK STOCK EXCHANGE, INC.', '+19728917700', 142855, 510),
        ('MS', 'Morgan Stanley', 'https://www.morganstanley.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/MS.svg', 'Financial Services', 'NEW YORK STOCK EXCHANGE, INC.', '+12127614000', 141753, 1656),
        ('BA', 'Boeing Co', 'https://www.boeing.com/', 'US', 'https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/BA.svg', 'Aerospace & Defense', 'NEW YORK STOCK EXCHANGE, INC.', '+17034146338', 137078, 603);

    GRANT ALL PRIVILEGES
        ON ALL TABLES
        IN SCHEMA public
        TO $DB_USER;
EOSQL