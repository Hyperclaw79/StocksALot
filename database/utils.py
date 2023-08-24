"""A module containing utility functions."""

from functools import wraps
import logging


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
    handler.setFormatter(logging.Formatter('[%(levelname)s] [%(name)s] %(message)s'))
    logger.addHandler(handler)
    return logger


def ensure_session(func: callable):
    """Ensure that the connection is open."""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        """Wrapper function."""
        if args[0].session is None:
            await args[0].connect()
        return await func(*args, **kwargs)
    return wrapper
