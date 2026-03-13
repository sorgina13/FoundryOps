"""Chat completion and embeddings tools.

Uses the Azure AI Services endpoint (Azure OpenAI) via the openai SDK
with DefaultAzureCredential token authentication.
"""

from __future__ import annotations

import json
import logging
import os
from functools import lru_cache

from mcp.types import TextContent
from openai import AsyncAzureOpenAI

from ..auth import get_openai_token_provider

logger = logging.getLogger(__name__)

GPT4O_DEPLOYMENT = os.environ.get("FOUNDRY_GPT4O_DEPLOYMENT", "gpt-4o-deployment")
EMBEDDING_DEPLOYMENT = os.environ.get("FOUNDRY_EMBEDDING_DEPLOYMENT", "embedding-deployment")


@lru_cache(maxsize=1)
def _get_openai_client() -> AsyncAzureOpenAI:
    """Return a cached AsyncAzureOpenAI client authenticated via Managed Identity."""
    endpoint = os.environ["AZURE_AI_SERVICES_ENDPOINT"]
    return AsyncAzureOpenAI(
        azure_endpoint=endpoint,
        azure_ad_token_provider=get_openai_token_provider(),
        api_version="2024-12-01-preview",
    )


async def chat_completion(arguments: dict) -> list[TextContent]:
    """Run a GPT-4o chat completion via Azure AI Foundry."""
    messages = arguments["messages"]
    max_tokens = arguments.get("max_tokens", 1024)
    temperature = arguments.get("temperature", 0.7)

    try:
        client = _get_openai_client()
        response = await client.chat.completions.create(
            model=GPT4O_DEPLOYMENT,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature,
        )
        content = response.choices[0].message.content
        result = {
            "content": content,
            "model": response.model,
            "usage": {
                "prompt_tokens": response.usage.prompt_tokens,
                "completion_tokens": response.usage.completion_tokens,
                "total_tokens": response.usage.total_tokens,
            },
            "finish_reason": response.choices[0].finish_reason,
        }
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as exc:
        logger.exception("Chat completion failed")
        return [TextContent(type="text", text=f"Error running chat completion: {exc}")]


async def get_embeddings(arguments: dict) -> list[TextContent]:
    """Generate text embeddings using text-embedding-3-large via Foundry."""
    texts = arguments["texts"]

    try:
        client = _get_openai_client()
        response = await client.embeddings.create(
            model=EMBEDDING_DEPLOYMENT,
            input=texts,
        )
        result = {
            "model": response.model,
            "embeddings": [
                {
                    "index": item.index,
                    "vector_length": len(item.embedding),
                    # Return first 5 values as preview — full vectors can be large
                    "preview": item.embedding[:5],
                }
                for item in response.data
            ],
            "usage": {
                "prompt_tokens": response.usage.prompt_tokens,
                "total_tokens": response.usage.total_tokens,
            },
        }
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as exc:
        logger.exception("Embeddings request failed")
        return [TextContent(type="text", text=f"Error generating embeddings: {exc}")]
