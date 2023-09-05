/**
 * This file contains a helper class for handling the Redis connection and caching.
 */
import { env } from "$env/dynamic/private";
import { createClient, type RedisClientType } from "redis";
import loggerFactory from "./logger";

const REDIS_HOST = env.REDIS_HOST || "localhost";
const REDIS_PORT = env.REDIS_PORT || 6379;

const logger = loggerFactory("Redis");

/**
 * A class that handles the Redis connection.
 */
class RedisClient {
    private client: RedisClientType;
    private isReadyWarningTriggered = false;

    constructor() {
        this.client = createClient({
            url: `redis://${REDIS_HOST}:${REDIS_PORT}`
        });
        // Add listener for "error" event
        this.client.on("error", async (error) => {
            logger.error("Connection error");
            logger.debug({ message: error });
            await this.disconnect();
        });
    }

    /**
     * Connects to Redis.
     */
    public async connect(): Promise<void> {
        try {
            await this.client.connect();
        } catch (error) {
            // logger.error({ message: error });
        }
    }

    /**
     * Disconnects from Redis.
     */
    public async disconnect(): Promise<void> {
        try {
            await this.client.quit();
        } catch (error) {
            // logger.error({ message: error });
        }
    }

    /**
     * Checks if the Redis client is ready.
     * @returns {boolean} True if the Redis client is ready.
     */
    private async checkConnection(): Promise<boolean> {
        if (!this.client.isOpen) {
            await this.connect();
        }
        if (!this.client.isReady) {
            if (!this.isReadyWarningTriggered) {
                logger.warn("Redis client is not ready. Operating in uncached mode.");
                this.isReadyWarningTriggered = true;
            }
            return false;
        }
        return true;
    }

    /**
     * Prefetches the data from Redis.
     * @param key The key to fetch.
     * @returns {Promise<string | null>} The data from Redis.
     */
    public async prefetch(key: string): Promise<string | null> {
        if (!(await this.checkConnection())) {
            return null;
        }
        try {
            const existing = (await this.client.json.get(key)) as string;
            if (existing) {
                logger.success(`Data found in Redis for key: ${key}`);
                return existing;
            }
            logger.info(`No data found in Redis for key: ${key}`);
            return null;
        } catch (error) {
            logger.error({ message: error });
            return null;
        }
    }

    /**
     * Caches the data in Redis.
     * @param key The key to cache.
     * @param data The data to cache.
     */
    public async cache(key: string, data: string): Promise<void> {
        if (!(await this.checkConnection())) {
            return;
        }
        try {
            const [keyResponse, expireResponse] = (await this.client
                .multi()
                .json.set(key, "$", data)
                .expire(key, 3600)
                .exec()) as [string, boolean];
            if (keyResponse !== "OK" || expireResponse !== true) {
                logger.warn(`Failed to cache data for key: ${key}`);
            } else {
                logger.success(`Data cached for key: ${key}`);
            }
        } catch (error) {
            logger.error({ message: error });
        }
    }
}

export const redisClient = new RedisClient();
await redisClient.connect();
