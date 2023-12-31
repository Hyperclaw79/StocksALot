"""A module containing utility functions."""

import logging
import os


LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO').upper()


logging.SUCCESS = 25
logging.addLevelName(logging.SUCCESS, "SUCCESS")


class CustomLogger(logging.Logger):
    """
    A logger that supports a SUCCESS level.
    """
    def success(self, msg, *args, **kwargs):
        """
        Logs a message with level SUCCESS.
        """
        if self.isEnabledFor(logging.SUCCESS):
            # pylint: disable=protected-access
            self._log(logging.SUCCESS, msg, args, **kwargs)


def logger_factory(name: str) -> CustomLogger:
    """
    Returns a logger for the given name.
    """
    logger = CustomLogger(name)
    logger.propagate = True
    handler = logging.StreamHandler()
    handler.setFormatter(
        logging.Formatter(
            '[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s',
            "%Y-%m-%d %H:%M:%S"
        )
    )
    logger.addHandler(handler)
    logger.setLevel(LOG_LEVEL)
    return logger
