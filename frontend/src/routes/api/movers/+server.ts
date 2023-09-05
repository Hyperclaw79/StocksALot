import loggerFactory from "$lib/logger";
import { cachedFetch } from "$lib/utils";
import { json } from "@sveltejs/kit";

const logger = loggerFactory("Movers API");

/**
 * Fetches the latest movers data from the server.
 * @returns {Promise<Movers>}
 */
export const GET = async (): Promise<Response> => {
    try {
        logger.info("Fetching movers data...");
        const res = await cachedFetch("movers");
        const jsonData: Movers = await res.json();
        if (jsonData === undefined) {
            return dummyData();
        }
        const response: Movers = jsonData;
        logger.success("Movers data fetched.");
        logger.debug(JSON.stringify(response));
        return json(response);
    } catch (e) {
        return dummyData();
    }
};

const dummyData = (): Response => {
    const dummyMover = {
        profile: {
            ticker: null,
            name: null,
            website: null,
            country: null,
            logo: null,
            industry: null,
            exchange: null,
            phone: null,
            market_cap: null,
            num_shares: null
        },
        current_metrics: {
            open: null,
            high: null,
            low: null,
            close: null,
            volume: null
        },
        metric_deltas: {
            open: null,
            high: null,
            low: null,
            close: null,
            volume: null
        }
    };
    return json({
        count: 0,
        items: [...Array(10)].map(() => dummyMover)
    });
};
