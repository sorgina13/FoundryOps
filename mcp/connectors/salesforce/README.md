# Salesforce MCP Connector

> Configuration and instructions for connecting the Salesforce MCP connector to
> the Enterprise Foundry platform.

## Overview

The Salesforce MCP connector exposes Salesforce CRM operations — Accounts, Contacts,
Opportunities, Cases, and SOQL queries — as MCP tools. GitHub Copilot can retrieve,
create, and update CRM records using natural language.

## Authentication

The connector authenticates using **OAuth 2.0 Connected App** credentials:

1. Create a Connected App in Salesforce Setup with OAuth 2.0 enabled
2. Use the **JWT Bearer Flow** (service-to-service) for automated auth
3. Store `client_id`, `private_key`, and `username` in Azure Key Vault

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SALESFORCE_INSTANCE_URL` | Yes | Salesforce instance URL (e.g. `https://myorg.my.salesforce.com`) |
| `SALESFORCE_CLIENT_ID` | Yes | Connected App consumer key |
| `SALESFORCE_PRIVATE_KEY` | Yes | PEM private key for JWT Bearer flow (from Key Vault) |
| `SALESFORCE_USERNAME` | Yes | Integration user's Salesforce username |
| `MCP_SERVER_PORT` | No | HTTP port (default: 8082) |

## VS Code `mcp.json` Entry

```json
{
  "salesforce": {
    "type": "http",
    "url": "${SALESFORCE_MCP_URL}",
    "headers": {
      "Authorization": "Bearer ${SALESFORCE_MCP_TOKEN}"
    }
  }
}
```

## Tools Exposed

| Tool | Purpose |
|------|---------|
| `sf_soql_query` | Execute a SOQL query and return records |
| `sf_get_account` | Retrieve a Salesforce Account by ID or name |
| `sf_list_accounts` | List Accounts matching a filter |
| `sf_get_contact` | Retrieve a Contact by ID or email |
| `sf_list_contacts` | List Contacts for an Account |
| `sf_get_opportunity` | Retrieve an Opportunity by ID |
| `sf_list_opportunities` | List open Opportunities (optionally by stage) |
| `sf_create_case` | Create a new support Case |
| `sf_get_case` | Retrieve a Case by ID |
| `sf_update_record` | Update any SObject record by ID and field values |

## Deployment on Azure Container Apps

```bash
az containerapp create \
  --name app-salesforce-mcp-prod \
  --resource-group rg-foundry-prod \
  --environment cae-foundry-prod \
  --image ghcr.io/modelcontextprotocol/server-salesforce:latest \
  --target-port 8082 \
  --ingress external \
  --env-vars \
    SALESFORCE_INSTANCE_URL=secretref:salesforce-instance-url \
    SALESFORCE_CLIENT_ID=secretref:salesforce-client-id \
    SALESFORCE_PRIVATE_KEY=secretref:salesforce-private-key \
    SALESFORCE_USERNAME=secretref:salesforce-username
```

## Key Vault Secrets Required

| Secret Name | Value |
|-------------|-------|
| `salesforce-instance-url` | Salesforce org URL |
| `salesforce-client-id` | Connected App consumer key |
| `salesforce-private-key` | JWT Bearer private key (PEM format) |
| `salesforce-username` | Integration user username |
