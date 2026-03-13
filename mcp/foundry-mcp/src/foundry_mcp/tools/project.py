"""AI Foundry Project management tools.

Exposes model deployment status, prompt flow listing and execution,
and project metadata via the Azure ML SDK.
"""

from __future__ import annotations

import json
import logging
import os
from functools import lru_cache

from mcp.types import TextContent

from ..auth import get_credential

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _get_ml_client():
    from azure.ai.ml import MLClient

    return MLClient(
        credential=get_credential(),
        subscription_id=os.environ.get("AZURE_SUBSCRIPTION_ID", ""),
        resource_group_name=os.environ.get("AZURE_RESOURCE_GROUP", ""),
        workspace_name=os.environ.get("FOUNDRY_PROJECT_NAME", ""),
    )


async def list_model_deployments(arguments: dict) -> list[TextContent]:  # noqa: ARG001
    """List active model deployments in the AI Foundry Project."""
    try:
        client = _get_ml_client()
        deployments = list(client.online_deployments.list(endpoint_name=None))
        result = [
            {
                "name": d.name,
                "endpoint": getattr(d, "endpoint_name", ""),
                "model": str(getattr(d, "model", "")),
                "instance_type": getattr(d, "instance_type", ""),
                "provisioning_state": getattr(d, "provisioning_state", ""),
            }
            for d in deployments
        ]
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as exc:
        logger.exception("Failed to list model deployments")
        return [TextContent(type="text", text=f"Error listing deployments: {exc}")]


async def get_deployment_status(arguments: dict) -> list[TextContent]:
    """Get the provisioning status of a named model deployment."""
    deployment_name = arguments["deployment_name"]
    try:
        client = _get_ml_client()
        # Try online endpoints first
        endpoints = list(client.online_endpoints.list())
        for endpoint in endpoints:
            deployment = client.online_deployments.get(
                name=deployment_name, endpoint_name=endpoint.name
            )
            result = {
                "deployment_name": deployment.name,
                "endpoint": endpoint.name,
                "provisioning_state": getattr(deployment, "provisioning_state", "Unknown"),
                "model": str(getattr(deployment, "model", "")),
                "instance_type": getattr(deployment, "instance_type", ""),
                "instance_count": getattr(deployment, "instance_count", 0),
            }
            return [TextContent(type="text", text=json.dumps(result, indent=2))]
        return [TextContent(type="text", text=f"Deployment '{deployment_name}' not found.")]
    except Exception as exc:
        logger.exception("Failed to get deployment status for '%s'", deployment_name)
        return [TextContent(type="text", text=f"Error getting deployment status: {exc}")]


async def list_prompt_flows(arguments: dict) -> list[TextContent]:  # noqa: ARG001
    """List prompt flows in the AI Foundry Project."""
    try:
        client = _get_ml_client()
        # Prompt flows are stored as ML flows
        flows = list(client.flows.list())
        result = [
            {
                "name": f.name,
                "version": getattr(f, "version", ""),
                "description": getattr(f, "description", ""),
                "type": getattr(f, "type", ""),
            }
            for f in flows
        ]
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as exc:
        logger.exception("Failed to list prompt flows")
        return [TextContent(type="text", text=f"Error listing prompt flows: {exc}")]


async def run_prompt_flow(arguments: dict) -> list[TextContent]:
    """Execute a named prompt flow with the provided inputs."""
    flow_name = arguments["flow_name"]
    inputs = arguments["inputs"]
    try:
        client = _get_ml_client()
        run = client.flows.invoke(flow_name=flow_name, inputs=inputs)
        result = {
            "flow_name": flow_name,
            "run_id": getattr(run, "name", ""),
            "status": getattr(run, "status", ""),
            "outputs": getattr(run, "outputs", {}),
        }
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as exc:
        logger.exception("Failed to run prompt flow '%s'", flow_name)
        return [TextContent(type="text", text=f"Error running prompt flow '{flow_name}': {exc}")]


async def get_project_info(arguments: dict) -> list[TextContent]:  # noqa: ARG001
    """Get AI Foundry Project metadata."""
    try:
        client = _get_ml_client()
        workspace = client.workspaces.get(client.workspace_name)
        result = {
            "name": workspace.name,
            "location": workspace.location,
            "resource_group": workspace.resource_group,
            "kind": getattr(workspace, "kind", ""),
            "hub_resource_id": getattr(workspace, "hub_resource_id", ""),
            "discovery_url": getattr(workspace, "discovery_url", ""),
            "provisioning_state": getattr(workspace, "provisioning_state", ""),
        }
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    except Exception as exc:
        logger.exception("Failed to get project info")
        return [TextContent(type="text", text=f"Error getting project info: {exc}")]
