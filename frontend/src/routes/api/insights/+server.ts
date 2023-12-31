import loggerFactory from "$lib/logger";
import { cachedFetch } from "$lib/utils";
import { json } from "@sveltejs/kit";

const logger = loggerFactory("Insights API");

let data: TimelineData[] = [];

/**
 * Fetches the latest insights data from the server.
 * @returns {Promise<Response>}
 */
export const GET = async (): Promise<Response> => {
    try {
        logger.info("Fetching insights data...");
        const res = await cachedFetch("insights");
        const jsonData: InsightsResponse = await res.json();
        const insights = jsonData.items;
        if (insights.length === 0) {
            return json(data);
        } else if (data.length === 0) {
            // Sort by datetime in descending order and filter records for the latest date part of the datetime.
            data = insights
                .sort((a, b) => (a.datetime < b.datetime ? 1 : -1))
                .filter((item, _, self) => {
                    const date = item.datetime.split("T")[0];
                    return self.findIndex((t) => t.datetime.split("T")[0] === date) === 0;
                });
        } else {
            // Merge the two arrays and sort by datetime in descending order.
            const temp = [...insights, ...data]
                .sort((a, b) => (a.datetime < b.datetime ? 1 : -1))
                .filter((item, index, self) => {
                    const date = item.datetime.split("T")[0];
                    return index === self.findIndex((t) => t.datetime.split("T")[0] === date);
                });
            const prev = data.sort((a, b) => (a.datetime < b.datetime ? 1 : -1));
            if (temp !== prev) {
                data = temp;
            }
        }
    } catch (error) {
        logger.error({ message: error });
    }
    logger.success("Insights data fetched.");
    logger.debug(JSON.stringify(data));
    return json({ count: data.length, items: data });
};
