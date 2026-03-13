/*
  Module: MCP Catalog
  Deploys the Azure Container App Environment and the foundry-mcp Container App.
  The foundry-mcp server exposes Azure AI Foundry tools via the Model Context Protocol.
  Integrated with VNet, Key Vault, and Log Analytics.
*/

@description('Container App Environment name.')
param environmentName string

@description('Container App name for the foundry-mcp server.')
param appName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Docker image tag for foundry-mcp.')
param mcpImageTag string = 'latest'

@description('ACR login server URL (e.g. crfoundryprod7xk2.azurecr.io).')
param acrLoginServer string

@description('ACR resource ID (used to scope the AcrPull role assignment uniquely).')
param acrResourceId string

@description('Azure AI Foundry Hub endpoint URL.')
param foundryHubEndpoint string

@description('Azure AI Services endpoint URL.')
param aiServicesEndpoint string

@description('Key Vault name (used to read secrets at runtime via MI).')
param keyVaultName string

@description('Name of the Log Analytics Workspace for diagnostic settings.')
param logAnalyticsWorkspaceName string

@description('Subnet resource ID for the MCP Container Apps environment.')
param mcpSubnetId string

@description('Minimum replica count (set to 0 for dev to scale-to-zero).')
param minReplicas int = 1

@description('Maximum replica count.')
param maxReplicas int = 10

// ─── Existing resources ───────────────────────────────────────────────────────

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// ─── Container App Environment ────────────────────────────────────────────────

module containerAppEnv 'br/public:avm/res/app/managed-environment:0.10.0' = {
  name: 'cae-deploy'
  params: {
    name: environmentName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
    vnetConfiguration: {
      infrastructureSubnetId: mcpSubnetId
      internal: false
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// ─── foundry-mcp Container App ────────────────────────────────────────────────

module foundryMcpApp 'br/public:avm/res/app/container-app:0.14.0' = {
  name: 'foundry-mcp-app'
  params: {
    name: appName
    location: location
    tags: tags
    environmentResourceId: containerAppEnv.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    ingressExternal: true
    ingressTargetPort: 8080
    ingressTransport: 'http'
    ingressAllowInsecure: false
    containers: [
      {
        name: 'foundry-mcp'
        image: '${acrLoginServer}/foundry-mcp:${mcpImageTag}'
        resources: {
          cpu: '0.5'
          memory: '1.0Gi'
        }
        env: [
          {
            name: 'AZURE_FOUNDRY_HUB_URL'
            value: foundryHubEndpoint
          }
          {
            name: 'AZURE_AI_SERVICES_ENDPOINT'
            value: aiServicesEndpoint
          }
          {
            name: 'AZURE_KEYVAULT_URL'
            value: keyVault.properties.vaultUri
          }
          {
            name: 'MCP_SERVER_PORT'
            value: '8080'
          }
          {
            name: 'MCP_TRANSPORT'
            value: 'sse'
          }
          {
            name: 'LOG_LEVEL'
            value: 'INFO'
          }
        ]
        probes: [
          {
            type: 'Liveness'
            httpGet: {
              path: '/health'
              port: 8080
            }
            initialDelaySeconds: 10
            periodSeconds: 30
          }
          {
            type: 'Readiness'
            httpGet: {
              path: '/ready'
              port: 8080
            }
            initialDelaySeconds: 5
            periodSeconds: 10
          }
        ]
      }
    ]
    scaleMinReplicas: minReplicas
    scaleMaxReplicas: maxReplicas
    scaleRules: [
      {
        name: 'http-scale'
        http: {
          metadata: {
            concurrentRequests: '100'
          }
        }
      }
    ]
  }
}

// ─── RBAC: AcrPull for the foundry-mcp managed identity ──────────────────────

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // AUDIT: AcrPull is the minimum required role for pulling images from ACR.
  name: guid(foundryMcpApp.outputs.systemAssignedMIPrincipalId, acrResourceId, 'acrpull')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull built-in role
    )
    principalId: foundryMcpApp.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ─── RBAC: Key Vault Secrets User for the foundry-mcp managed identity ───────

resource kvSecretsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(foundryMcpApp.outputs.systemAssignedMIPrincipalId, keyVault.id, 'kv-secrets-user')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User built-in role
    )
    principalId: foundryMcpApp.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('Container App Environment resource ID.')
output environmentId string = containerAppEnv.outputs.resourceId

@description('foundry-mcp Container App resource ID.')
output appId string = foundryMcpApp.outputs.resourceId

@description('foundry-mcp Container App FQDN (used to build MCP server URL).')
output appFqdn string = foundryMcpApp.outputs.fqdn

@description('Public MCP server URL (HTTPS).')
output mcpServerUrl string = 'https://${foundryMcpApp.outputs.fqdn}'

@description('foundry-mcp Container App managed identity principal ID.')
output principalId string = foundryMcpApp.outputs.systemAssignedMIPrincipalId
