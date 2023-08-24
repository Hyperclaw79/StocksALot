"""Module for Kubernetes API related functions."""
import contextlib
from kubernetes import client, config

from base_connector import BaseConnector
from utils import logger_factory, ensure_session


logger = logger_factory("Kubernetes API")


class KubernetesAPI(BaseConnector):
    """Connector for Kubernetes API."""
    def __init__(self):
        super().__init__()
        self.session: client.ApiClient
        self.api_instance = None
        self.validated_clients = []

    async def connect(self):
        """Connect to the Kubernetes API."""
        logger.info("Connecting to Kubernetes API...")
        with contextlib.suppress(config.ConfigException):
            config.load_incluster_config()
        self.session = client.ApiClient()
        self.api_instance = client.AuthenticationV1Api(self.session)

    async def disconnect(self):
        """Disconnect from the Kubernetes API."""
        logger.info("Disconnecting from Kubernetes API...")
        await super().disconnect()

    @ensure_session
    async def validate_token(self, client_name: str, token: str) -> bool:
        """Validates if a token is a valid kubernetes serviceaccount
        token running in the same cluster.
        """
        if client_name in self.validated_clients:
            return True
        token_review = client.V1TokenReview(spec=client.V1TokenReviewSpec(token=token))
        success = False
        try:
            response = self.api_instance.create_token_review(
                body=token_review, async_req=True, pretty="true"
            ).get()
            if response.status.authenticated:
                logger.success("Received valid token from %s.", client_name)
                self.validated_clients.append(client_name)
                success = True
        except client.ApiException:
            success = False
        if not success:
            logger.warning("Received invalid token from %s", client_name)
        return success
