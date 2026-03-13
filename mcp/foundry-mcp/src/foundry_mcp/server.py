"""MCP server definition for foundry-mcp.

Registers all Azure AI Foundry tools and starts the server using
either stdio (for VS Code) or SSE / HTTP transport (for Container Apps).
"""

from __future__ import annotations

import logging
import os

from mcp.server import Server
from mcp.server.models import InitializationOptions
from mcp.types import ServerCapabilities, Tool

from .tools.catalog import (
    get_catalog_tool,
    list_catalog_tools,
)
from .tools.completion import (
    chat_completion,
    get_embeddings,
)
from .tools.project import (
    get_deployment_status,
    get_project_info,
    list_model_deployments,
    list_prompt_flows,
    run_prompt_flow,
)

logger = logging.getLogger(__name__)

# ─── Server instance ──────────────────────────────────────────────────────────

app = Server("foundry-mcp")


# ─── Tool registration ────────────────────────────────────────────────────────


@app.list_tools()
async def handle_list_tools() -> list[Tool]:
    """Return all registered Foundry tools."""
    return [
        Tool(
            name="list_catalog_tools",
            description=(
                "List all tools registered in the Azure AI Foundry Catalog. "
                "Returns tool names, descriptions, and versions."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "filter": {
                        "type": "string",
                        "description": "Optional keyword filter for tool names.",
                    }
                },
            },
        ),
        Tool(
            name="get_catalog_tool",
            description="Get details of a specific tool from the Foundry Catalog by name.",
            inputSchema={
                "type": "object",
                "properties": {
                    "tool_name": {"type": "string", "description": "Exact tool name."}
                },
                "required": ["tool_name"],
            },
        ),
        Tool(
            name="chat_completion",
            description=(
                "Run a GPT-4o chat completion via Azure AI Foundry. "
                "Supports system and user messages."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "messages": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "role": {"type": "string", "enum": ["system", "user", "assistant"]},
                                "content": {"type": "string"},
                            },
                            "required": ["role", "content"],
                        },
                        "description": "Conversation messages.",
                    },
                    "max_tokens": {
                        "type": "integer",
                        "default": 1024,
                        "description": "Maximum tokens to generate.",
                    },
                    "temperature": {
                        "type": "number",
                        "default": 0.7,
                        "description": "Sampling temperature (0–2).",
                    },
                },
                "required": ["messages"],
            },
        ),
        Tool(
            name="get_embeddings",
            description="Generate text embeddings using text-embedding-3-large via Foundry.",
            inputSchema={
                "type": "object",
                "properties": {
                    "texts": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of text strings to embed (max 2048 per call).",
                    }
                },
                "required": ["texts"],
            },
        ),
        Tool(
            name="list_model_deployments",
            description="List active model deployments in the AI Foundry Project.",
            inputSchema={"type": "object", "properties": {}},
        ),
        Tool(
            name="get_deployment_status",
            description="Check the provisioning status of a model deployment.",
            inputSchema={
                "type": "object",
                "properties": {
                    "deployment_name": {"type": "string", "description": "Deployment name."}
                },
                "required": ["deployment_name"],
            },
        ),
        Tool(
            name="list_prompt_flows",
            description="List prompt flows defined in the AI Foundry Project.",
            inputSchema={"type": "object", "properties": {}},
        ),
        Tool(
            name="run_prompt_flow",
            description="Execute a named prompt flow with provided inputs.",
            inputSchema={
                "type": "object",
                "properties": {
                    "flow_name": {"type": "string", "description": "Name of the prompt flow."},
                    "inputs": {
                        "type": "object",
                        "description": "Key-value pairs matching the flow's input schema.",
                    },
                },
                "required": ["flow_name", "inputs"],
            },
        ),
        Tool(
            name="get_project_info",
            description="Get Azure AI Foundry Project metadata (name, hub, region, deployments).",
            inputSchema={"type": "object", "properties": {}},
        ),
    ]


@app.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list:
    """Dispatch tool calls to the correct handler."""
    dispatch = {
        "list_catalog_tools": list_catalog_tools,
        "get_catalog_tool": get_catalog_tool,
        "chat_completion": chat_completion,
        "get_embeddings": get_embeddings,
        "list_model_deployments": list_model_deployments,
        "get_deployment_status": get_deployment_status,
        "list_prompt_flows": list_prompt_flows,
        "run_prompt_flow": run_prompt_flow,
        "get_project_info": get_project_info,
    }
    handler = dispatch.get(name)
    if handler is None:
        raise ValueError(f"Unknown tool: {name}")
    return await handler(arguments)


# ─── Server startup ───────────────────────────────────────────────────────────


def create_initialization_options() -> InitializationOptions:
    return InitializationOptions(
        server_name="foundry-mcp",
        server_version="1.0.0",
        capabilities=ServerCapabilities(tools={}),
    )


async def run_stdio() -> None:
    """Run the MCP server using stdio transport (VS Code)."""
    from mcp.server.stdio import stdio_server

    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            create_initialization_options(),
        )


async def run_sse(port: int) -> None:
    """Run the MCP server using SSE / HTTP transport (Container Apps)."""
    from mcp.server.sse import SseServerTransport
    from starlette.applications import Starlette
    from starlette.requests import Request
    from starlette.responses import JSONResponse
    from starlette.routing import Mount, Route

    sse_transport = SseServerTransport("/messages/")

    async def handle_sse(request: Request):
        async with sse_transport.connect_sse(
            request.scope, request.receive, request.send
        ) as streams:
            await app.run(streams[0], streams[1], create_initialization_options())

    async def health(_request: Request) -> JSONResponse:
        return JSONResponse({"status": "ok", "server": "foundry-mcp"})

    async def ready(_request: Request) -> JSONResponse:
        return JSONResponse({"status": "ready"})

    starlette_app = Starlette(
        routes=[
            Route("/health", health),
            Route("/ready", ready),
            Route("/sse", handle_sse),
            Mount("/messages/", app=sse_transport.handle_post_message),
        ]
    )

    import uvicorn

    config = uvicorn.Config(starlette_app, host="0.0.0.0", port=port, log_level="info")
    server = uvicorn.Server(config)
    await server.serve()


def get_transport() -> str:
    return os.environ.get("MCP_TRANSPORT", "stdio").lower()


def get_port() -> int:
    return int(os.environ.get("MCP_SERVER_PORT", "8080"))
