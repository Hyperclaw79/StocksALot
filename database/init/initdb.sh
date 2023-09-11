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

    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'CMCSA', 'Comcast Corp', 45.895, 46.055, 45.89, 46, 2389735, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'XOM', 'Exxon Mobil Corp', 109.14, 109.49, 109.08, 109.16, 2071922, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'INTC', 'Intel Corp', 33.44, 33.675, 33.425, 33.63, 3575802, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'KO', 'Coca-Cola Co', 60.54, 60.68, 60.54, 60.56, 1059040, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'NFLX', 'Netflix Inc', 415.23999, 418.32999, 415.13, 418.17999, 346678, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'INTU', 'Intuit Inc.', 518, 519.21997, 517.45001, 518.87, 273812, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'PFE', 'Pfizer Inc', 36.13, 36.23, 36.095, 36.21, 2615003, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'GOOGL', 'Alphabet Inc', 130.78999, 131.28, 130.74001, 131.07001, 2552125, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'AAPL', 'Apple Inc', 179.89, 180.59, 179.80499, 180.21001, 5793020, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'MSFT', 'Microsoft Corp', 322.64001, 324.07001, 322.39999, 323.73999, 1700034, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'AMZN', 'Amazon.com Inc', 132.74001, 133.31, 132.655, 133.14999, 3662120, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'META', 'Meta Platforms Inc', 288.79999, 290.56, 288.64499, 290.29001, 1514049, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'TSLA', 'Tesla Inc', 237.59, 239.67999, 237.47, 238.89, 6875789, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'BRK.A', 'Berkshire Hathaway Inc', 538840, 540557.4375, 538520, 539604.875, 107, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'NVDA', 'NVIDIA Corp', 465.75, 469.79999, 465.5, 468.155, 5530038, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'JPM', 'JPMorgan Chase & Co', 147.25, 147.769, 147.21001, 147.53, 773504, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'JNJ', 'Johnson & Johnson', 164.02, 164.73, 163.94, 164.28, 1555374, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'V', 'Visa Inc', 243.62, 244.39999, 243.36, 243.8, 573097, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'UNH', 'UnitedHealth Group Inc', 490.54999, 492.26999, 490.47, 491.20999, 199055, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'HD', 'Home Depot Inc', 325.42001, 326.41, 325.19, 325.85999, 336555, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'PG', 'Procter & Gamble Co', 153.77, 154.12, 153.75, 153.785, 522675, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'MA', 'Mastercard Inc', 406.42999, 407.79999, 406.23999, 407.48001, 403067, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'DIS', 'Walt Disney Co', 83.86, 84.24, 83.85, 84.15, 1625151, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'MRK', 'Merck & Co Inc', 108.855, 109.03, 108.65, 108.92, 699418, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'CSCO', 'Cisco Systems Inc', 56.15, 56.28, 56.115, 56.21, 2574172, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'WMT', 'Walmart Inc', 158.39999, 158.83, 158.33, 158.67, 673324, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'ABT', 'Abbott Laboratories', 102.4, 102.93, 102.355, 102.8, 812649, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'CRM', 'Salesforce Inc', 211.33, 211.88, 211.08, 211.69, 497742, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'CVX', 'Chevron Corp', 159.71001, 160.36, 159.63, 160.23, 700793, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'PEP', 'PepsiCo Inc', 180.00999, 180.44501, 180.005, 180.28, 506677, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'ORCL', 'Oracle Corp', 116.44, 117.01, 116.375, 116.83, 730711, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'MS', 'Morgan Stanley', 84.35, 84.64, 84.33, 84.37, 841586, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'BA', 'Boeing Co', 226.45, 227.45, 226.22, 227.00999, 692689, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'NKE', 'Nike Inc', 99.275, 99.855, 99.26, 99.62, 816706, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'ABBV', 'Abbvie Inc', 147.05, 147.72, 147.00999, 147.38, 668169, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'ACN', 'Accenture PLC', 319.97, 321.26001, 319.92999, 321.035, 197645, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'TMO', 'Thermo Fisher Scientific Inc', 544.66498, 546.08002, 544.33002, 545.21002, 139044, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'MCD', 'McDonalds Corp', 283.75, 284.17001, 283.51001, 283.64001, 352682, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'COST', 'Costco Wholesale Corp', 534.42499, 536.38, 534.31, 536.17999, 195507, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'LLY', 'Eli Lilly and Co', 552.26001, 554.07001, 551.60999, 553.79999, 280113, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'DHR', 'Danaher Corp', 261.01001, 262.01001, 260.92499, 261.51999, 469425, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'TXN', 'Texas Instruments Inc', 168.08, 168.86, 167.985, 168.72, 535606, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'AVGO', 'Broadcom Inc', 856.15997, 861.37, 855.03998, 861.35999, 263260, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'UPS', 'United Parcel Service Inc', 168.5, 169.14, 168.5, 168.84, 420289, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'ADBE', 'Adobe Inc', 528.81512, 530.65002, 528.59998, 529.91998, 223093, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'AMD', 'Advanced Micro Devices Inc', 102.29, 102.91, 102.2488, 102.655, 4647581, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'WFC', 'Wells Fargo & Co', 41.75, 41.93, 41.74, 41.87, 2268496, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'PM', 'Philip Morris International Inc', 95.86, 96.07, 95.85, 95.87, 504932, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 15:30:00', 1693216800, 'CAT', 'Caterpillar Inc', 274.47, 275.20001, 274.13, 274.79001, 239700, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'BAC', 'Bank of America Corp', 28.76, 28.795, 28.73, 28.7388, 3007395, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'CMCSA', 'Comcast Corp', 45.7799, 45.9, 45.75, 45.9, 993502, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'XOM', 'Exxon Mobil Corp', 109.0714, 109.35, 108.94, 109.15, 921174, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'INTC', 'Intel Corp', 33.44, 33.47, 33.365, 33.445, 1544849, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'KO', 'Coca-Cola Co', 60.48, 60.6, 60.47, 60.54, 712662, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'NFLX', 'Netflix Inc', 414.83249, 416.73999, 413.70999, 415.5, 279126, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'INTU', 'Intuit Inc.', 518.09003, 519.82001, 517.46002, 518.29999, 115497, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'PFE', 'Pfizer Inc', 36.085, 36.19, 36.045, 36.13, 1793341, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'GOOGL', 'Alphabet Inc', 130.59, 131.16, 130.45, 130.8, 1530712, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'AAPL', 'Apple Inc', 179.55, 180.00999, 179.35001, 179.905, 3598477, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'MSFT', 'Microsoft Corp', 322.04999, 323.54999, 321.72198, 322.685, 1447839, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'AMZN', 'Amazon.com Inc', 132.23, 132.925, 132.11, 132.75999, 2861569, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'META', 'Meta Platforms Inc', 288.33749, 289.79999, 287.67001, 288.79999, 1133272, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'TSLA', 'Tesla Inc', 237.1319, 238.5, 236.55, 237.61501, 8798929, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'BRK.A', 'Berkshire Hathaway Inc', 538602.6875, 539500.0625, 538000, 538857.4375, 235, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'NVDA', 'NVIDIA Corp', 466.62, 468.84991, 464.60999, 465.80499, 7300654, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'JPM', 'JPMorgan Chase & Co', 147.59, 147.75, 147.21001, 147.25999, 706899, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'JNJ', 'Johnson & Johnson', 163.32001, 164.10001, 163.19, 164.03, 1669029, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'V', 'Visa Inc', 243.41949, 244.07001, 243.3916, 243.63, 302435, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'UNH', 'UnitedHealth Group Inc', 489.23001, 490.98999, 489.16, 490.54999, 134307, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'HD', 'Home Depot Inc', 324.60999, 325.56, 324.14499, 325.47, 194077, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'PG', 'Procter & Gamble Co', 153.50011, 153.88, 153.45, 153.78999, 262755, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'MA', 'Mastercard Inc', 405.76999, 407.01999, 405.64999, 406.51001, 189310, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'DIS', 'Walt Disney Co', 83.975, 84, 83.72, 83.8601, 1099092, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'MRK', 'Merck & Co Inc', 108.72, 109.06, 108.65, 108.85, 500242, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'CSCO', 'Cisco Systems Inc', 56.08, 56.17, 56.05, 56.15, 1354417, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'WMT', 'Walmart Inc', 158.215, 158.4299, 158.09, 158.41991, 335516, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'ABT', 'Abbott Laboratories', 102.285, 102.55, 102.26, 102.4, 476158, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'CRM', 'Salesforce Inc', 211.175, 211.75999, 211.06, 211.38, 397527, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'CVX', 'Chevron Corp', 159.57001, 159.92999, 159.52, 159.74001, 387426, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'PEP', 'PepsiCo Inc', 179.77, 180.10001, 179.71001, 180.02, 318272, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'ORCL', 'Oracle Corp', 116.38, 116.65, 116.2, 116.4491, 352238, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'MS', 'Morgan Stanley', 84.38, 84.53, 84.24, 84.35, 676470, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'BA', 'Boeing Co', 225.7923, 226.94, 225.62, 226.425, 307794, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'NKE', 'Nike Inc', 99.29, 99.38, 99.1172, 99.29, 497093, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'ABBV', 'Abbvie Inc', 146.80499, 147.11, 146.77, 147.03999, 239850, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'ACN', 'Accenture PLC', 319.845, 320.60999, 319.5, 320.01999, 106216, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'TMO', 'Thermo Fisher Scientific Inc', 543.76001, 545.25, 543.45001, 544.69, 57559, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'MCD', 'McDonalds Corp', 283.73999, 284.07999, 283.60251, 283.81, 162291, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'COST', 'Costco Wholesale Corp', 533.91998, 534.76001, 533.54999, 534.41498, 70315, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'LLY', 'Eli Lilly and Co', 552.46997, 553.06, 551.96002, 552.26001, 113423, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'DHR', 'Danaher Corp', 260.45001, 261.26999, 260.32999, 261.06, 216334, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'TXN', 'Texas Instruments Inc', 168.12019, 168.27, 167.82001, 168.09, 213695, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'AVGO', 'Broadcom Inc', 854.15997, 858.31, 853.30902, 856.38, 132255, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'UPS', 'United Parcel Service Inc', 167.995, 168.7, 167.96001, 168.52, 277432, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'ADBE', 'Adobe Inc', 528.5, 530.35999, 528.07001, 529.22498, 111507, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'AMD', 'Advanced Micro Devices Inc', 102.2799, 102.61, 102.05, 102.29, 4629672, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'WFC', 'Wells Fargo & Co', 41.68, 41.78, 41.66, 41.755, 1542531, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'PM', 'Philip Morris International Inc', 95.74, 95.92, 95.711, 95.87, 213062, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 14:30:00', 1693213200, 'CAT', 'Caterpillar Inc', 275.01001, 275.07001, 274.28, 274.57001, 154282, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'BAC', 'Bank of America Corp', 28.8736, 28.9, 28.75, 28.765, 1903003, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'CMCSA', 'Comcast Corp', 45.885, 45.92, 45.73, 45.77, 1233508, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'XOM', 'Exxon Mobil Corp', 109.33, 109.39, 108.67, 109.075, 775181, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'INTC', 'Intel Corp', 33.575, 33.6, 33.32, 33.44, 1482166, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'KO', 'Coca-Cola Co', 60.505, 60.515, 60.4, 60.485, 598754, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'NFLX', 'Netflix Inc', 418.5849, 418.84, 414.53, 414.79001, 244001, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'INTU', 'Intuit Inc.', 520.90503, 521.25, 517.29999, 517.94049, 90839, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'PFE', 'Pfizer Inc', 36.085, 36.13, 36.03, 36.085, 1470152, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'GOOGL', 'Alphabet Inc', 130.87, 130.95, 130.14, 130.59, 1419582, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'AAPL', 'Apple Inc', 179.96001, 180.0899, 179.1384, 179.5394, 3839420, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'MSFT', 'Microsoft Corp', 324.17999, 324.32999, 321.79999, 322.03491, 1211069, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'AMZN', 'Amazon.com Inc', 132.82001, 132.95, 132.03, 132.2292, 2483998, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'META', 'Meta Platforms Inc', 289.745, 289.79001, 287.42001, 288.35001, 1238485, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'TSLA', 'Tesla Inc', 239.08, 239.12, 236.03, 237.14999, 9736432, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'BRK.A', 'Berkshire Hathaway Inc', 540716.375, 540899.8125, 538055, 538602.875, 221, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'NVDA', 'NVIDIA Corp', 467.88, 469.63, 463.62, 466.48001, 8616719, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'JPM', 'JPMorgan Chase & Co', 148.16, 148.22, 147.5, 147.58, 382301, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'JNJ', 'Johnson & Johnson', 163.58, 163.58, 163.16499, 163.31, 2211562, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'V', 'Visa Inc', 244.03, 244.1599, 243.2, 243.42, 273724, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'UNH', 'UnitedHealth Group Inc', 490.92999, 491.34, 489.13, 489.17001, 94432, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'HD', 'Home Depot Inc', 327.04761, 327.42999, 324.26999, 324.57001, 181838, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'PG', 'Procter & Gamble Co', 153.82001, 153.88, 153.42, 153.5, 239372, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'MA', 'Mastercard Inc', 407.23999, 407.39999, 405.72, 405.79001, 139047, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'DIS', 'Walt Disney Co', 84.14, 84.31, 83.94, 83.975, 1160006, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'MRK', 'Merck & Co Inc', 108.96, 109.01, 108.6526, 108.72, 348777, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'CSCO', 'Cisco Systems Inc', 56.205, 56.225, 56.035, 56.075, 1115146, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'WMT', 'Walmart Inc', 158.7339, 158.78, 158.10001, 158.21001, 313266, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'ABT', 'Abbott Laboratories', 102.225, 102.415, 101.885, 102.28, 410397, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'CRM', 'Salesforce Inc', 212.21001, 212.23, 210.7, 211.14999, 342053, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'CVX', 'Chevron Corp', 159.95, 160.00999, 159.215, 159.62, 462389, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'PEP', 'PepsiCo Inc', 180.17999, 180.2, 179.69, 179.78999, 241909, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'ORCL', 'Oracle Corp', 117.47, 117.5, 116.28, 116.37, 470532, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'MS', 'Morgan Stanley', 84.785, 84.84, 84.38, 84.39, 562905, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'BA', 'Boeing Co', 226.63, 226.89999, 225.33, 225.71429, 309463, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'NKE', 'Nike Inc', 99.74, 99.7957, 99.23, 99.3, 521422, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'ABBV', 'Abbvie Inc', 147.27, 147.37, 146.8, 146.8199, 179411, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'ACN', 'Accenture PLC', 321.23001, 321.34991, 319.26999, 319.75, 110535, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'TMO', 'Thermo Fisher Scientific Inc', 545.28003, 545.34003, 542.96997, 543.67999, 41103, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'MCD', 'McDonalds Corp', 284.655, 284.81, 283.59, 283.76999, 143216, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'COST', 'Costco Wholesale Corp', 535.22998, 535.31, 533.12, 533.78003, 85706, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'LLY', 'Eli Lilly and Co', 553.52002, 554.29999, 552.06, 552.42499, 118924, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'DHR', 'Danaher Corp', 261.54501, 261.80499, 259.845, 260.42999, 218233, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'TXN', 'Texas Instruments Inc', 168.74001, 168.83, 167.58, 168.11, 151447, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'AVGO', 'Broadcom Inc', 858.0061, 858.90002, 850.82001, 854.06598, 114623, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'UPS', 'United Parcel Service Inc', 169.12, 169.17999, 168, 168.015, 260556, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'ADBE', 'Adobe Inc', 531.7807, 532.21997, 527.70001, 528.67499, 187569, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'AMD', 'Advanced Micro Devices Inc', 102.55, 102.6363, 101.7, 102.27, 4681668, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'WFC', 'Wells Fargo & Co', 41.825, 41.835, 41.66, 41.685, 784985, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'PM', 'Philip Morris International Inc', 96, 96.07, 95.67, 95.745, 170199, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 13:30:00', 1693209600, 'CAT', 'Caterpillar Inc', 275.38751, 275.45999, 274.64999, 275.01001, 258399, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'BAC', 'Bank of America Corp', 28.77, 28.905, 28.76, 28.875, 2147726, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'CMCSA', 'Comcast Corp', 45.79, 46.01, 45.75, 45.885, 995215, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'XOM', 'Exxon Mobil Corp', 109.08, 109.435, 109.03, 109.32, 853979, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'INTC', 'Intel Corp', 33.35, 33.69, 33.3418, 33.58, 1889439, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'KO', 'Coca-Cola Co', 60.425, 60.54, 60.37, 60.505, 505904, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'NFLX', 'Netflix Inc', 416.13501, 419.35001, 416.10001, 418.48511, 246366, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'INTU', 'Intuit Inc.', 518.69501, 522.48499, 518.45001, 520.83002, 111935, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'PFE', 'Pfizer Inc', 36.085, 36.12, 36.04, 36.08, 1996389, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'GOOGL', 'Alphabet Inc', 130.52, 131.39, 130.45, 130.86501, 1432983, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'AAPL', 'Apple Inc', 178.82001, 180.13989, 178.75, 179.955, 3845609, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'MSFT', 'Microsoft Corp', 322.64999, 325, 322.39001, 324.13, 1140965, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'AMZN', 'Amazon.com Inc', 132.295, 133.0804, 132.14, 132.81, 3126745, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'META', 'Meta Platforms Inc', 287.48001, 290.1499, 287.25, 289.68011, 1431102, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'TSLA', 'Tesla Inc', 236.1834, 239.14999, 235.35001, 239.06, 11933765, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'BRK.A', 'Berkshire Hathaway Inc', 539500, 541464.6875, 538821, 540362.375, 186, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'NVDA', 'NVIDIA Corp', 458.8699, 468.599, 458.3049, 467.88, 10167106, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'JPM', 'JPMorgan Chase & Co', 147.83, 148.47, 147.67, 148.16, 450325, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'JNJ', 'Johnson & Johnson', 163.92999, 164.16, 163.52, 163.58, 1881535, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'V', 'Visa Inc', 243.35001, 244.34, 243.28, 244.015, 236410, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'UNH', 'UnitedHealth Group Inc', 490.92001, 491.01001, 490.06659, 490.87, 124995, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'HD', 'Home Depot Inc', 326.14761, 327.13, 325.62009, 327.01001, 151725, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'PG', 'Procter & Gamble Co', 153.50999, 153.95, 153.37, 153.78, 225553, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'MA', 'Mastercard Inc', 406.12, 407.57999, 405.89001, 407.22, 170709, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'DIS', 'Walt Disney Co', 84.135, 84.47, 84.095, 84.13, 1297621, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'MRK', 'Merck & Co Inc', 109.02, 109.14, 108.87, 108.95, 379549, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'CSCO', 'Cisco Systems Inc', 56.085, 56.28, 56.07, 56.205, 1071360, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'WMT', 'Walmart Inc', 158.3136, 158.8, 158.22, 158.73, 260633, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'ABT', 'Abbott Laboratories', 102.21, 102.51, 102.18, 102.22, 356103, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'CRM', 'Salesforce Inc', 210.69, 212.25999, 210.58, 212.19099, 425802, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'CVX', 'Chevron Corp', 160, 160.27879, 159.89, 159.96001, 355314, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'PEP', 'PepsiCo Inc', 179.75, 180.23, 179.64, 180.16, 212527, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'ORCL', 'Oracle Corp', 117.025, 117.71, 116.9542, 117.46, 645555, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'MS', 'Morgan Stanley', 84.395, 84.87, 84.33, 84.7899, 648734, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'BA', 'Boeing Co', 225.61501, 226.7, 225.07001, 226.63, 403956, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'NKE', 'Nike Inc', 99.3, 99.83, 99.26, 99.7389, 533706, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'ABBV', 'Abbvie Inc', 147.03999, 147.52, 146.77, 147.25999, 223432, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'ACN', 'Accenture PLC', 320.66, 321.92001, 320.64999, 321.12, 65391, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'TMO', 'Thermo Fisher Scientific Inc', 544.41498, 546.15002, 543.67999, 545.16998, 30495, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'MCD', 'McDonalds Corp', 284.76999, 284.99991, 284.15399, 284.62, 158881, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'COST', 'Costco Wholesale Corp', 534.70001, 536.10999, 534, 535.09998, 70338, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'LLY', 'Eli Lilly and Co', 553.54999, 554.46997, 553.15002, 553.57501, 94171, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'DHR', 'Danaher Corp', 260.20001, 261.59, 260, 261.57001, 247161, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'TXN', 'Texas Instruments Inc', 168.19, 169.28, 168.16, 168.71001, 155688, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'AVGO', 'Broadcom Inc', 851.84998, 859.77002, 851.70001, 857.90002, 111491, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'UPS', 'United Parcel Service Inc', 169.67, 169.67999, 169.03999, 169.10001, 187613, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'ADBE', 'Adobe Inc', 526.97498, 533.51001, 526.77002, 531.68988, 224881, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'AMD', 'Advanced Micro Devices Inc', 101.69, 102.87, 101.63, 102.545, 6432799, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'WFC', 'Wells Fargo & Co', 41.67, 41.895, 41.66, 41.825, 812566, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'PM', 'Philip Morris International Inc', 95.8618, 96.04, 95.78, 96, 188344, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 12:30:00', 1693206000, 'CAT', 'Caterpillar Inc', 274.70999, 275.84, 274.64999, 275.39001, 105095, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'BAC', 'Bank of America Corp', 28.8, 28.85, 28.75, 28.7726, 2184140, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'CMCSA', 'Comcast Corp', 45.63, 45.825, 45.59, 45.795, 865606, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'XOM', 'Exxon Mobil Corp', 109.21, 109.31, 108.87, 109.08, 757574, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'INTC', 'Intel Corp', 33.33, 33.38, 33.21, 33.34, 2570939, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'KO', 'Coca-Cola Co', 60.44, 60.46, 60.3692, 60.42, 487028, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'NFLX', 'Netflix Inc', 416.66, 417.88, 415.08011, 416.06, 294744, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'INTU', 'Intuit Inc.', 519.83002, 520.69, 517.23999, 518.58002, 141984, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'PFE', 'Pfizer Inc', 36.195, 36.215, 36.065, 36.09, 1605533, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'GOOGL', 'Alphabet Inc', 130.35001, 130.75999, 130.194, 130.52499, 1589202, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'AAPL', 'Apple Inc', 178.77, 179.11501, 178.545, 178.81, 3748464, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'MSFT', 'Microsoft Corp', 322.53, 323.5, 322.04001, 322.64001, 1191949, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'AMZN', 'Amazon.com Inc', 132.11011, 132.545, 131.89, 132.3, 3266715, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'META', 'Meta Platforms Inc', 286.54001, 288.10001, 285.79999, 287.535, 1304385, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'TSLA', 'Tesla Inc', 239.465, 239.86, 235.52, 236.16499, 16162243, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'BRK.A', 'Berkshire Hathaway Inc', 539178.5, 540058.375, 538176, 539277.5, 240, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'NVDA', 'NVIDIA Corp', 458.79999, 459.75, 450, 458.85001, 6037611, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'JPM', 'JPMorgan Chase & Co', 147.83, 148.08, 147.59, 147.83, 358988, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'JNJ', 'Johnson & Johnson', 164.08, 164.21001, 163.60001, 163.92, 2390005, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'V', 'Visa Inc', 243.72, 244.21001, 243.38, 243.38, 380386, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'UNH', 'UnitedHealth Group Inc', 491.26001, 492.14001, 490.6022, 490.92001, 140687, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'HD', 'Home Depot Inc', 326.42001, 327.19, 325.97, 326.01001, 174322, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'PG', 'Procter & Gamble Co', 153.13, 153.535, 153.09, 153.53, 258961, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'MA', 'Mastercard Inc', 405.57001, 406.56, 405.16, 406.13501, 212225, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'DIS', 'Walt Disney Co', 84.13, 84.35, 84.095, 84.1399, 1380305, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'MRK', 'Merck & Co Inc', 109.29, 109.345, 108.9, 109.01, 365923, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'CSCO', 'Cisco Systems Inc', 56.03, 56.1, 55.96, 56.085, 1123193, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'WMT', 'Walmart Inc', 158.39999, 158.55, 158.17999, 158.32001, 270320, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'ABT', 'Abbott Laboratories', 102.19, 102.58, 102.14, 102.22, 497923, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'CRM', 'Salesforce Inc', 210.69, 211.32001, 210.3801, 210.715, 342700, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'CVX', 'Chevron Corp', 160.13, 160.28, 159.72, 159.98, 360497, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'PEP', 'PepsiCo Inc', 179.57001, 180.67, 179.38, 179.75999, 195722, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'ORCL', 'Oracle Corp', 116.375, 117.07, 116.305, 117.02, 583000, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'MS', 'Morgan Stanley', 84.17, 84.45, 84.105, 84.39, 489246, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'BA', 'Boeing Co', 226.56, 226.92999, 225.31, 225.64999, 476766, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'NKE', 'Nike Inc', 99.12, 99.46, 99.06, 99.29, 594841, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'ABBV', 'Abbvie Inc', 146.99001, 147.10001, 146.7755, 147.05499, 180231, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'ACN', 'Accenture PLC', 320.01001, 321.12, 319.54999, 320.70999, 85281, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'TMO', 'Thermo Fisher Scientific Inc', 544.90002, 545.84497, 544.13501, 544.21002, 53774, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'MCD', 'McDonalds Corp', 285.10001, 285.29999, 284.66, 284.85999, 192913, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'COST', 'Costco Wholesale Corp', 534.90997, 535.71301, 534.28998, 534.46002, 77819, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'LLY', 'Eli Lilly and Co', 553.10999, 554.15033, 552.88, 553.47998, 107613, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'DHR', 'Danaher Corp', 259.62851, 260.60001, 259.54999, 260.20499, 221721, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'TXN', 'Texas Instruments Inc', 168.57001, 168.675, 167.907, 168.2, 181581, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'AVGO', 'Broadcom Inc', 854.42999, 855.73499, 850.91998, 851.42499, 99347, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'UPS', 'United Parcel Service Inc', 169.98, 170.14, 169.34, 169.655, 171640, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'ADBE', 'Adobe Inc', 526.47498, 527.90747, 524.78003, 526.84998, 205020, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'AMD', 'Advanced Micro Devices Inc', 102.04, 102.41, 101.59, 101.695, 5575803, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'WFC', 'Wells Fargo & Co', 41.64, 41.82, 41.58, 41.675, 746311, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'PM', 'Philip Morris International Inc', 95.57, 95.89, 95.53, 95.87, 169842, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 11:30:00', 1693202400, 'CAT', 'Caterpillar Inc', 274.32999, 275.07999, 274.09, 274.57001, 107472, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'BAC', 'Bank of America Corp', 28.96, 28.98, 28.78, 28.809, 2944114, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'CMCSA', 'Comcast Corp', 45.82, 45.84, 45.6, 45.625, 895999, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'XOM', 'Exxon Mobil Corp', 109.7, 109.81, 109.11, 109.19, 854059, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'INTC', 'Intel Corp', 33.75, 33.755, 33.305, 33.3321, 2199973, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'KO', 'Coca-Cola Co', 60.555, 60.61, 60.38, 60.44, 739878, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'NFLX', 'Netflix Inc', 418.44, 418.96991, 414.89999, 416.56, 270373, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'INTU', 'Intuit Inc.', 522.13, 522.67499, 518.66418, 519.75, 156838, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'PFE', 'Pfizer Inc', 36.33, 36.37, 36.15, 36.19, 1660699, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'GOOGL', 'Alphabet Inc', 131.72, 131.8293, 130.25999, 130.35001, 2389485, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'AAPL', 'Apple Inc', 179.8, 179.8, 178.67999, 178.7782, 4693449, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'MSFT', 'Microsoft Corp', 324.32999, 324.67001, 322.10999, 322.57001, 1577947, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'AMZN', 'Amazon.com Inc', 132.99001, 133.02, 131.85001, 132.11, 4556550, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'META', 'Meta Platforms Inc', 290.42999, 290.94989, 286.42001, 286.57501, 1877077, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'TSLA', 'Tesla Inc', 240.2401, 240.87, 237.81, 239.46001, 16700354, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'BRK.A', 'Berkshire Hathaway Inc', 542578.6875, 542653.6875, 538863.0625, 538863.0625, 2122, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'NVDA', 'NVIDIA Corp', 456.435, 460.23999, 452.70999, 458.88, 9752781, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'JPM', 'JPMorgan Chase & Co', 148.28999, 148.49969, 147.69, 147.82001, 589048, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'JNJ', 'Johnson & Johnson', 165.25999, 165.785, 163.92999, 164.0825, 2378037, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'V', 'Visa Inc', 245.155, 245.2, 243.64, 243.75999, 461651, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'UNH', 'UnitedHealth Group Inc', 492.19, 492.785, 490.38, 491.20001, 125831, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'HD', 'Home Depot Inc', 325.77499, 327.44, 325.48999, 326.41, 343757, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'PG', 'Procter & Gamble Co', 153.8, 153.82001, 153.05, 153.13, 353601, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'MA', 'Mastercard Inc', 406.95999, 407.42999, 405.22, 405.595, 246946, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'DIS', 'Walt Disney Co', 84.55, 84.685, 84.0101, 84.14, 1795756, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'MRK', 'Merck & Co Inc', 109.69, 109.9573, 109.2715, 109.29, 377039, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'CSCO', 'Cisco Systems Inc', 56, 56.085, 55.922, 56.035, 1302940, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'WMT', 'Walmart Inc', 158.23, 158.63, 158.05, 158.42, 349751, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'ABT', 'Abbott Laboratories', 103.33, 103.38, 102.05, 102.18, 983301, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'CRM', 'Salesforce Inc', 210.67999, 210.83, 209.67, 210.64999, 479550, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'CVX', 'Chevron Corp', 160.71001, 161.0249, 160.06, 160.13, 527138, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'PEP', 'PepsiCo Inc', 180.17, 180.23, 179.34399, 179.57001, 257379, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'ORCL', 'Oracle Corp', 116.7, 116.71, 115.7, 116.34, 507477, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'MS', 'Morgan Stanley', 84.42, 84.61, 83.975, 84.18, 726582, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'BA', 'Boeing Co', 225.14999, 227.38989, 224.87, 226.45, 912210, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'NKE', 'Nike Inc', 99.61, 99.625, 98.865, 99.125, 787534, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'ABBV', 'Abbvie Inc', 147.58, 147.62, 146.834, 146.985, 210639, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'ACN', 'Accenture PLC', 322.23001, 322.23999, 319.70999, 320.28, 99688, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'TMO', 'Thermo Fisher Scientific Inc', 545.77002, 546.63, 543.98499, 544.90503, 46424, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'MCD', 'McDonalds Corp', 285.39999, 285.64999, 284.85999, 285.03, 358312, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'COST', 'Costco Wholesale Corp', 535.96997, 536.04999, 533.89001, 534.85999, 97813, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'LLY', 'Eli Lilly and Co', 553.40503, 553.92999, 551.60999, 553.03009, 126207, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'DHR', 'Danaher Corp', 258.88531, 259.63, 258.51999, 259.61499, 275776, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'TXN', 'Texas Instruments Inc', 169.7, 169.72, 168.17, 168.62, 209732, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'AVGO', 'Broadcom Inc', 855.07501, 857.42499, 850.25, 854.54999, 147321, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'UPS', 'United Parcel Service Inc', 170.485, 170.655, 169.89, 170, 186756, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'ADBE', 'Adobe Inc', 528.77002, 529.495, 524.95001, 526.59003, 189098, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'AMD', 'Advanced Micro Devices Inc', 102.98, 103.1, 100.8944, 102.05, 11132383, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'WFC', 'Wells Fargo & Co', 41.8294, 41.865, 41.56, 41.65, 988319, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'PM', 'Philip Morris International Inc', 95.72, 95.84, 95.445, 95.57, 197069, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 10:30:00', 1693198800, 'CAT', 'Caterpillar Inc', 275.56, 275.69, 274.26001, 274.4899, 141999, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'BAC', 'Bank of America Corp', 28.69, 29, 28.565, 28.965, 9788004, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'CMCSA', 'Comcast Corp', 45.56, 45.95, 45.56, 45.815, 1512330, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'XOM', 'Exxon Mobil Corp', 108.45, 110.04, 108.44, 109.68, 2119868, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'INTC', 'Intel Corp', 33.5, 33.78, 33.4811, 33.75, 3594049, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'KO', 'Coca-Cola Co', 60.55, 60.725, 60.55, 60.5547, 889403, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'NFLX', 'Netflix Inc', 418.04001, 419.82999, 413.26999, 418.35999, 826255, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'INTU', 'Intuit Inc.', 519.04999, 522, 513.83002, 522, 278244, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'PFE', 'Pfizer Inc', 36.44, 36.52, 36.28, 36.3235, 2292779, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'GOOGL', 'Alphabet Inc', 131.31, 132.53999, 130.78999, 131.705, 4943371, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'AAPL', 'Apple Inc', 180.09, 180.2, 178.78999, 179.78999, 8960343, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'MSFT', 'Microsoft Corp', 325.66, 326.14999, 322.3642, 324.32001, 2785324, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'AMZN', 'Amazon.com Inc', 133.78, 133.95, 131.89999, 132.99001, 8467277, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'META', 'Meta Platforms Inc', 288, 291.45001, 286.69, 290.37, 3680097, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'TSLA', 'Tesla Inc', 243.92999, 244.38, 237.2, 240.25, 33986594, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'BRK.A', 'Berkshire Hathaway Inc', 542060, 544160, 539960, 542578.6875, 4095, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'NVDA', 'NVIDIA Corp', 460.25, 464.98499, 448.88, 456.41, 18073307, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'JPM', 'JPMorgan Chase & Co', 147.57001, 148.61, 147.13, 148.28, 983247, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'JNJ', 'Johnson & Johnson', 165, 166.21001, 164.82001, 165.25999, 1956083, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'V', 'Visa Inc', 243.00999, 245.23, 242.60001, 245.13, 814744, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'UNH', 'UnitedHealth Group Inc', 490.48999, 493.05811, 490.04001, 491.87, 264585, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'HD', 'Home Depot Inc', 323.20001, 326.56, 322.87, 325.71701, 298217, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'PG', 'Procter & Gamble Co', 153.71001, 154.37, 153.66, 153.78, 1001370, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'MA', 'Mastercard Inc', 404, 406.97, 403.14999, 406.82999, 337349, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'DIS', 'Walt Disney Co', 83.83, 84.58, 83.53, 84.5557, 2833360, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'MRK', 'Merck & Co Inc', 110.23, 110.61, 109.62, 109.6972, 640470, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'CSCO', 'Cisco Systems Inc', 55.89, 56.04, 55.68, 56.01, 1709379, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'WMT', 'Walmart Inc', 157.86, 158.69, 157.86, 158.24001, 564695, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'ABT', 'Abbott Laboratories', 105.07, 105.22, 103.22, 103.34, 1204635, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'CRM', 'Salesforce Inc', 210.45, 213.4767, 209.64, 210.73, 932260, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'CVX', 'Chevron Corp', 159.53, 161.8, 159.53, 160.675, 976086, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'PEP', 'PepsiCo Inc', 180.82001, 181.17999, 180.08, 180.14999, 427352, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'ORCL', 'Oracle Corp', 116.37, 117.4, 116.06, 116.68, 746908, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'MS', 'Morgan Stanley', 83.8, 84.72, 83.77, 84.415, 1076456, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'BA', 'Boeing Co', 224.21001, 225.41, 223.2901, 225.17999, 1191146, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'NKE', 'Nike Inc', 99.59, 100.06, 99.36, 99.605, 1053067, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'ABBV', 'Abbvie Inc', 147.09, 148.065, 146.995, 147.56, 517194, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'ACN', 'Accenture PLC', 318.76001, 322.20001, 318.73499, 322.20001, 210564, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'TMO', 'Thermo Fisher Scientific Inc', 544.32001, 546.54999, 540.53003, 545.78998, 91349, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'MCD', 'McDonalds Corp', 284.57999, 286.20001, 284.51001, 285.41, 580609, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'COST', 'Costco Wholesale Corp', 536, 537.03998, 534.39001, 536.02612, 149146, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'LLY', 'Eli Lilly and Co', 550.13, 556.22998, 550.12, 553.28003, 285283, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'DHR', 'Danaher Corp', 258.20999, 259.45001, 257.51001, 259.03, 275635, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'TXN', 'Texas Instruments Inc', 169.22, 169.92, 168.48, 169.67, 284975, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'AVGO', 'Broadcom Inc', 854.27002, 864.12988, 847.10999, 855.06, 331911, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'UPS', 'United Parcel Service Inc', 169.7, 170.64, 169.42, 170.465, 250767, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'ADBE', 'Adobe Inc', 525.70001, 529.75, 523.97998, 528.77002, 311681, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'AMD', 'Advanced Micro Devices Inc', 103.47, 104.07, 101.68, 102.98, 14635322, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'WFC', 'Wells Fargo & Co', 41.41, 42.07, 41.29, 41.8299, 1879729, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'PM', 'Philip Morris International Inc', 95.4, 95.8, 95.27, 95.71, 270347, 'twelvedata');
    INSERT INTO ohlc(datetime, timestamp, ticker, name, open, high, low, close, volume, source) VALUES ('2023-08-28 09:30:00', 1693195200, 'CAT', 'Caterpillar Inc', 273.5, 276.99899, 273.035, 275.56, 333500, 'twelvedata');

    GRANT ALL PRIVILEGES
        ON ALL TABLES
        IN SCHEMA public
        TO $DB_USER;
EOSQL