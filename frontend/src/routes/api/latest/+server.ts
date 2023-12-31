import loggerFactory from "$lib/logger";
import { cachedFetch } from "$lib/utils";
import { json } from "@sveltejs/kit";

const logger = loggerFactory("Latest OHLC API");

/**
 * Fetches the latest OHLC data from the server.
 * @returns {Promise<Response>}
 */
export const GET = async (): Promise<Response> => {
    try {
        logger.info("Fetching latest ohlc data...");
        const res = await cachedFetch("latest");
        const jsonData: OHLCOriginalResponse = await res.json();
        if (jsonData === undefined) {
            return dummyData();
        }
        const transformedData = jsonData.items.map((item) => {
            return {
                datetime: item.datetime,
                timestamp: item.timestamp,
                ticker: item.ticker,
                company: item.name,
                open: item.open,
                high: item.high,
                low: item.low,
                close: item.close,
                volume: item.volume
            };
        });
        const response: OHLCResponse = {
            count: jsonData.count,
            items: transformedData
        };
        logger.success("Latest data ohlc fetched.");
        logger.debug(JSON.stringify(response));
        return json(response);
    } catch (e) {
        return dummyData();
    }
};

const dummyData = (): Response => {
    const dummyOHLC = {
        datetime: null,
        timestamp: null,
        ticker: null,
        company: null,
        open: null,
        high: null,
        low: null,
        close: null,
        volume: null
    };
    return json({
        count: 0,
        items: [...Array(50)].map(() => dummyOHLC)
    });
};
