/**
 * This file contains utility functions that are used in the frontend.
 */
import { env } from "$env/dynamic/private";
import { readFileSync } from "fs";
import path from "path";
import { redisClient } from "./redisclient";

let saToken = "";

/**
 * Returns the service account token.
 * @returns {string} The service account token.
 */
const getSAToken = (): string => {
    if (saToken !== "") {
        return saToken;
    }
    try {
        const dirname = path.resolve();
        const tokenFilePath = path.join(
            dirname,
            "../../../var/run/secrets/kubernetes.io/serviceaccount/token"
        );
        const token = readFileSync(tokenFilePath, "utf8").trim();
        saToken = token;
        return token;
    } catch (e) {
        // In case of non-Kubernetes deployment
        return "";
    }
};

/**
 * Creates a fetch object with the correct headers.
 * @param {string} endpoint The endpoint to fetch from.
 * @returns {Promise<Response>} The response from the server.
 */
export const cachedFetch = async (endpoint: string): Promise<Response> => {
    let data;
    data = await redisClient.prefetch(endpoint);
    if (data !== null) {
        return new Response(data, {
            headers: {
                "Content-Type": "application/json"
            }
        });
    }
    const response = await fetch(`http://${env.DB_SERVER_HOST}/${endpoint}`, {
        method: "GET",
        headers: {
            "Content-Type": "application/json",
            Authorization: "Bearer Internal",
            "X-Internal-Client": "Frontend",
            "X-Internal-Token": getSAToken()
        }
    });
    data = (await response.json()) as InsightsResponse | OHLCResponse | Movers;
    if (data && data.count > 0 && data.items.length > 0) {
        await redisClient.cache(endpoint, JSON.stringify(data));
    }
    return new Response(JSON.stringify(data), {
        headers: {
            "Content-Type": "application/json"
        }
    });
};
