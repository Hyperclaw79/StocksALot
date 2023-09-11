"""A module containing utility functions."""

from functools import wraps
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


def ensure_session(func: callable):
    """Ensure that the connection is open."""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        """Wrapper function."""
        if args[0].session is None:
            await args[0].connect()
        return await func(*args, **kwargs)
    return wrapper


def fetch_password(pwd_name: str, default: str = None) -> str:
    """Get the password for the database."""
    if pwd := os.getenv(pwd_name):
        return pwd
    if pwd_file := os.getenv(f"{pwd_name}_FILE"):
        with open(pwd_file, encoding='utf-8') as password_file:
            return password_file.read().strip()
    return default
