"""Entry point for foundry-mcp server."""

from __future__ import annotations

import asyncio
import logging
import os

from .server import get_port, get_transport, run_sse, run_stdio

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


def main() -> None:
    transport = get_transport()
    logger.info("Starting foundry-mcp server (transport=%s)", transport)

    if transport == "stdio":
        asyncio.run(run_stdio())
    elif transport in ("sse", "http"):
        port = get_port()
        logger.info("Listening on port %d", port)
        asyncio.run(run_sse(port))
    else:
        raise ValueError(f"Unknown MCP_TRANSPORT: {transport!r}. Use 'stdio' or 'sse'.")


if __name__ == "__main__":
    main()
