# Microsoft 365 MCP Connector

> Configuration and instructions for connecting the M365 MCP connector to
> the Enterprise Foundry platform.

## Overview

The M365 MCP connector wraps the **Microsoft Graph API** as MCP tools, enabling
GitHub Copilot to read emails, calendar events, Teams messages, SharePoint files,
and OneDrive documents — all through natural language.

## Authentication

Uses **OAuth 2.0 Client Credentials** flow with an Azure AD Application registration:

1. Register an Azure AD app with the required Microsoft Graph application permissions
2. Grant admin consent for all scopes
3. Store `tenant_id`, `client_id`, and `client_secret` in Azure Key Vault

### Required Graph Permissions (Application)

| Permission | Purpose |
|------------|---------|
| `Mail.Read` | Read mailbox messages |
| `Calendars.Read` | Read calendar events |
| `Files.Read.All` | Read SharePoint / OneDrive files |
| `ChannelMessage.Read.All` | Read Teams channel messages |
| `User.Read.All` | Read user profiles |
| `Group.Read.All` | Read group memberships |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `M365_TENANT_ID` | Yes | Azure AD tenant ID |
| `M365_CLIENT_ID` | Yes | App registration client ID |
| `M365_CLIENT_SECRET` | Yes | App registration client secret (from Key Vault) |
| `MCP_SERVER_PORT` | No | HTTP port (default: 8083) |

## VS Code `mcp.json` Entry

```json
{
  "m365": {
    "type": "http",
    "url": "${M365_MCP_URL}",
    "headers": {
      "Authorization": "Bearer ${M365_MCP_TOKEN}"
    }
  }
}
```

## Tools Exposed

| Tool | Purpose |
|------|---------|
| `m365_list_emails` | List recent emails from a mailbox |
| `m365_get_email` | Get full content of a specific email |
| `m365_list_calendar_events` | List upcoming calendar events for a user |
| `m365_get_calendar_event` | Get details of a specific calendar event |
| `m365_list_teams_channels` | List channels in a Teams team |
| `m365_get_teams_messages` | Get recent messages from a Teams channel |
| `m365_list_sharepoint_files` | List files in a SharePoint document library |
| `m365_get_file_content` | Get text content of a SharePoint / OneDrive file |
| `m365_search_content` | Search across M365 (mail, files, sites) |
| `m365_get_user_profile` | Get profile information for an Entra ID user |

## Deployment on Azure Container Apps

```bash
az containerapp create \
  --name app-m365-mcp-prod \
  --resource-group rg-foundry-prod \
  --environment cae-foundry-prod \
  --image ghcr.io/modelcontextprotocol/server-m365:latest \
  --target-port 8083 \
  --ingress external \
  --env-vars \
    M365_TENANT_ID=secretref:m365-tenant-id \
    M365_CLIENT_ID=secretref:m365-client-id \
    M365_CLIENT_SECRET=secretref:m365-client-secret
```

## Key Vault Secrets Required

| Secret Name | Value |
|-------------|-------|
| `m365-tenant-id` | Azure AD tenant ID |
| `m365-client-id` | App registration client ID |
| `m365-client-secret` | App registration client secret |
