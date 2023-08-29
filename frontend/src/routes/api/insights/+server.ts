import { fetchFactory } from "$lib/utils";
import { json } from "@sveltejs/kit";

let data: TimelineData[] = [];

/**
 * Fetches the latest insights data from the server.
 * @returns {Promise<Response>}
 */
export const GET = async (): Promise<Response> => {
    try {
        console.debug("Fetching insights data...");
        const res = await fetchFactory("insights");
        const jsonData: InsightsResponse = await res.json();
        const insights = jsonData.items;
        if (insights.length === 0) {
            return json(data);
        } else if (data.length === 0) {
            // Sort by datetime in descending order
            data = insights.sort((a, b) => (a.datetime < b.datetime ? 1 : -1));
        } else {
            // Merge the two arrays and sort by datetime in descending order
            const temp = [...insights, ...data].sort((a, b) => (a.datetime < b.datetime ? 1 : -1));
            const prev = data.sort((a, b) => (a.datetime < b.datetime ? 1 : -1));
            if (temp !== prev) {
                data = temp;
            }
        }
    } catch (e) {
        console.error(e);
    }
    console.debug(`Insights data fetched:\n${JSON.stringify(data)}`);
    return json({ count: data.length, items: data });
};
