# Databricks MCP Connector

> Configuration and instructions for connecting the Databricks MCP connector to
> the Enterprise Foundry platform.

## Overview

The Databricks MCP connector exposes Databricks SQL, Jobs, and ML-flow capabilities
as MCP tools, enabling GitHub Copilot to query data warehouses, trigger ML training
jobs, and retrieve model metrics — all through natural language.

## Authentication

The connector authenticates to Databricks using a **Service Principal** with the
following OAuth 2.0 M2M flow:

1. Azure AD Service Principal (app registration)
2. SP granted `Can Use` permission on target Databricks workspace
3. Client credentials stored in Azure Key Vault

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABRICKS_HOST` | Yes | Databricks workspace URL (e.g. `https://adb-123.azuredatabricks.net`) |
| `DATABRICKS_CLIENT_ID` | Yes | Service Principal client ID |
| `DATABRICKS_CLIENT_SECRET` | Yes | SP secret (read from Key Vault at runtime) |
| `DATABRICKS_CATALOG` | No | Unity Catalog name (default: `main`) |
| `MCP_SERVER_PORT` | No | HTTP port (default: 8081) |

## VS Code `mcp.json` Entry

```json
{
  "databricks": {
    "type": "http",
    "url": "${DATABRICKS_MCP_URL}",
    "headers": {
      "Authorization": "Bearer ${DATABRICKS_MCP_TOKEN}"
    }
  }
}
```

## Tools Exposed

| Tool | Purpose |
|------|---------|
| `databricks_sql_query` | Run a SQL query against Databricks SQL warehouse |
| `databricks_list_catalogs` | List Unity Catalog catalogs |
| `databricks_list_schemas` | List schemas in a catalog |
| `databricks_list_tables` | List tables in a schema |
| `databricks_get_table_schema` | Get schema of a specific table |
| `databricks_list_jobs` | List Databricks jobs |
| `databricks_run_job` | Trigger a Databricks job by ID |
| `databricks_get_job_status` | Check the status of a job run |
| `databricks_list_models` | List registered MLflow models |
| `databricks_get_model_metrics` | Get MLflow model run metrics |

## Deployment on Azure Container Apps

```bash
az containerapp create \
  --name app-databricks-mcp-prod \
  --resource-group rg-foundry-prod \
  --environment cae-foundry-prod \
  --image ghcr.io/databrickslabs/mcp-server:latest \
  --target-port 8081 \
  --ingress external \
  --env-vars \
    DATABRICKS_HOST=secretref:databricks-host \
    DATABRICKS_CLIENT_ID=secretref:databricks-client-id \
    DATABRICKS_CLIENT_SECRET=secretref:databricks-client-secret
```

## Key Vault Secrets Required

| Secret Name | Value |
|-------------|-------|
| `databricks-host` | Databricks workspace URL |
| `databricks-client-id` | Service Principal application ID |
| `databricks-client-secret` | Service Principal client secret |
