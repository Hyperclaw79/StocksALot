/**
 * This file is used to create a logger instance that can be used throughout the application.
 */
import { env } from "$env/dynamic/private";
import { createLogger, format, transports, type Logger, type LeveledLogMethod } from "winston";

const { combine, colorize, timestamp, label, printf } = format;

const customLevels = {
    levels: {
        success: 0,
        error: 1,
        warn: 2,
        info: 3,
        debug: 4
    },
    colors: {
        debug: "cyan",
        info: "blue",
        warn: "yellow",
        error: "red",
        success: "green"
    }
};

const colorizer = colorize({ all: true });
colorizer.addColors(customLevels.colors);

/**
 * Creates a logger instance with the given module name.
 * @param {string} modname The name of the module.
 * @returns The logger instance.
 */
const loggerFactory = (modname: string) => {
    const logFormat = combine(
        timestamp({
            format: "YY-MM-DD HH:mm:ss"
        }),
        label({
            label: modname
        }),
        printf(({ level, message, timestamp, label }) => {
            return `[${timestamp}] [${level.toUpperCase()}] [${label}] ${message}`;
        })
    );

    const logger = createLogger({
        level: env.LOG_LEVEL || "info",
        levels: customLevels.levels,
        transports: [
            new transports.Console({
                format: combine(logFormat, colorizer)
            })
        ]
    });

    return logger as Logger & Record<keyof typeof customLevels.levels, LeveledLogMethod>;
};

export default loggerFactory;
