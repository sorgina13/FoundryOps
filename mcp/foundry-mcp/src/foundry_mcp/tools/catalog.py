"""Foundry Catalog tools.

Exposes tools for discovering and inspecting tools registered in the
Azure AI Foundry Catalog.
"""

from __future__ import annotations

import json
import logging
import os

from mcp.types import TextContent

from ..auth import get_credential

logger = logging.getLogger(__name__)


def _get_ml_client():
    """Return an authenticated Azure ML client for Foundry operations."""
    from azure.ai.ml import MLClient

    credential = get_credential()
    subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID", "")
    resource_group = os.environ.get("AZURE_RESOURCE_GROUP", "")
    workspace_name = os.environ.get("FOUNDRY_PROJECT_NAME", "")

    return MLClient(
        credential=credential,
        subscription_id=subscription_id,
        resource_group_name=resource_group,
        workspace_name=workspace_name,
    )


async def list_catalog_tools(arguments: dict) -> list[TextContent]:
    """List tools from the AI Foundry Catalog."""
    keyword_filter = arguments.get("filter", "").lower()
    try:
        client = _get_ml_client()
        # Azure AI Foundry catalog components are registered as ML components
        components = list(client.components.list())
        results = []
        for component in components:
            if keyword_filter and keyword_filter not in component.name.lower():
                continue
            results.append(
                {
                    "name": component.name,
                    "version": component.version,
                    "description": getattr(component, "description", ""),
                    "type": getattr(component, "type", "unknown"),
                }
            )
        return [TextContent(type="text", text=json.dumps(results, indent=2))]
    except Exception as exc:
        logger.exception("Failed to list catalog tools")
        return [TextContent(type="text", text=f"Error listing catalog tools: {exc}")]


async def get_catalog_tool(arguments: dict) -> list[TextContent]:
    """Get details of a specific Foundry Catalog tool."""
    tool_name = arguments["tool_name"]
    try:
        client = _get_ml_client()
        component = client.components.get(name=tool_name)
        details = {
            "name": component.name,
            "version": component.version,
            "description": getattr(component, "description", ""),
            "type": getattr(component, "type", "unknown"),
            "inputs": getattr(component, "inputs", {}),
            "outputs": getattr(component, "outputs", {}),
            "creation_context": str(getattr(component, "creation_context", "")),
        }
        return [TextContent(type="text", text=json.dumps(details, indent=2))]
    except Exception as exc:
        logger.exception("Failed to get catalog tool '%s'", tool_name)
        return [TextContent(type="text", text=f"Error getting catalog tool '{tool_name}': {exc}")]
