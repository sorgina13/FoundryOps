"""Azure credential provider for foundry-mcp.

Uses DefaultAzureCredential which supports:
- Managed Identity (when running on Azure Container Apps)
- Azure CLI (local development: az login)
- Service Principal via environment variables
"""

from __future__ import annotations

import logging
from functools import lru_cache

from azure.identity import DefaultAzureCredential, get_bearer_token_provider

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def get_credential() -> DefaultAzureCredential:
    """Return a cached Azure credential instance."""
    logger.debug("Creating DefaultAzureCredential")
    return DefaultAzureCredential()


def get_openai_token_provider():
    """Return a token provider compatible with the openai SDK's azure_ad_token_provider."""
    return get_bearer_token_provider(
        get_credential(),
        "https://cognitiveservices.azure.com/.default",
    )
