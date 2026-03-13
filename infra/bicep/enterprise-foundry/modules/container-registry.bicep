/*
  Module: Container Registry
  Standard-tier ACR for the foundry-mcp Docker image.
  Admin user disabled — push/pull via managed identity.
  No public network access.
*/

@description('Container Registry name (max 50 chars, alphanumeric).')
@maxLength(50)
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Name of the Log Analytics Workspace for diagnostic settings.')
param logAnalyticsWorkspaceName string

// ─── Container Registry ───────────────────────────────────────────────────────

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

module acr 'br/public:avm/res/container-registry/registry:0.9.0' = {
  name: 'acr-deploy'
  params: {
    name: name
    location: location
    tags: tags
    acrSku: 'Standard'
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    managedIdentities: {
      systemAssigned: true
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalyticsWorkspace.id
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('ACR resource ID.')
output resourceId string = acr.outputs.resourceId

@description('ACR resource name.')
output resourceName string = acr.outputs.name

@description('ACR login server URL.')
output loginServer string = acr.outputs.loginServer

@description('ACR system-assigned managed identity principal ID.')
output principalId string = acr.outputs.systemAssignedMIPrincipalId
