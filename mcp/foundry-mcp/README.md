# foundry-mcp

> Python MCP server that exposes Azure AI Foundry tools — models, prompt flows, and the
> Foundry Catalog — to GitHub Copilot and any MCP-compatible client.

## Quick Start

### VS Code (stdio transport)

The server is pre-configured in `.vscode/mcp.json`. After opening the devcontainer:

```bash
cd mcp/foundry-mcp
pip install -e .
```

The server starts automatically when VS Code invokes it via stdio.

### Docker (HTTP / SSE transport)

```bash
cd mcp/foundry-mcp
docker build -t foundry-mcp .
docker run -p 8080:8080 \
  -e AZURE_FOUNDRY_HUB_URL=https://hub-foundry-prod.api.azureml.ms \
  -e AZURE_AI_SERVICES_ENDPOINT=https://ais-foundry-prod.cognitiveservices.azure.com \
  foundry-mcp
```

Connect your MCP client to `http://localhost:8080/sse`.

## Authentication

The server uses **Azure Managed Identity** when running on Azure Container Apps.
For local development, set:

```bash
export AZURE_TENANT_ID=<tenant-id>
export AZURE_CLIENT_ID=<client-id>
export AZURE_CLIENT_SECRET=<client-secret>
# or: az login
```

## Tools Exposed

| Tool | Purpose | Auth |
|------|---------|------|
| `list_catalog_tools` | List all tools registered in the Foundry Catalog | MI |
| `get_catalog_tool` | Get details of a specific tool by name | MI |
| `chat_completion` | Run a GPT-4o chat completion via Foundry | MI |
| `get_embeddings` | Generate text embeddings (text-embedding-3-large) | MI |
| `list_model_deployments` | List active model deployments in the Project | MI |
| `get_deployment_status` | Check the status of a model deployment | MI |
| `list_prompt_flows` | List prompt flows in the Foundry Project | MI |
| `run_prompt_flow` | Execute a named prompt flow with inputs | MI |
| `get_project_info` | Get Foundry Project metadata | MI |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `AZURE_FOUNDRY_HUB_URL` | Yes | AI Foundry Hub workspace URL |
| `AZURE_AI_SERVICES_ENDPOINT` | Yes | Azure AI Services endpoint |
| `AZURE_KEYVAULT_URL` | No | Key Vault URL for reading secrets |
| `FOUNDRY_PROJECT_NAME` | No | AI Project name (auto-discovered if not set) |
| `MCP_SERVER_PORT` | No | HTTP port (default: 8080) |
| `MCP_TRANSPORT` | No | `stdio` or `sse` (default: stdio) |
| `LOG_LEVEL` | No | `DEBUG`, `INFO`, `WARNING` (default: INFO) |

## Project Structure

```text
mcp/foundry-mcp/
├── src/
│   └── foundry_mcp/
│       ├── __init__.py
│       ├── __main__.py          # Entry point
│       ├── server.py            # MCP server definition
│       ├── tools/
│       │   ├── __init__.py
│       │   ├── catalog.py       # Foundry Catalog tools
│       │   ├── completion.py    # Chat completion + embeddings
│       │   └── project.py       # Project / deployment management
│       └── auth.py              # Azure credential provider
├── Dockerfile
├── pyproject.toml
└── README.md
```

## License

MIT
