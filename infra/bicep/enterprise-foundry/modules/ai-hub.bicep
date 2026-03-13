/*
  Module: AI Foundry Hub
  Deploys the Azure AI Foundry Hub workspace — the enterprise AI control plane.
  Kind: Hub. System-assigned managed identity. Private endpoint.
  Linked to Storage, Key Vault, ACR, and Application Insights.
*/

@description('AI Hub workspace name.')
param hubName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Storage Account resource ID.')
param storageAccountId string

@description('Key Vault resource ID.')
param keyVaultId string

@description('Container Registry resource ID.')
param containerRegistryId string

@description('Application Insights resource ID.')
param applicationInsightsId string

@description('Name of the Log Analytics Workspace for diagnostic settings.')
param logAnalyticsWorkspaceName string

@description('Private endpoint subnet resource ID.')
param privateEndpointSubnetId string

@description('Private DNS Zone resource ID for Azure ML API.')
param privateDnsZoneId string

// ─── AI Foundry Hub ───────────────────────────────────────────────────────────

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

module aiHub 'br/public:avm/res/machine-learning-services/workspace:0.10.0' = {
  name: 'ai-hub-deploy'
  params: {
    name: hubName
    location: location
    tags: tags
    kind: 'Hub'
    sku: 'Basic'
    associatedStorageAccountResourceId: storageAccountId
    associatedKeyVaultResourceId: keyVaultId
    associatedContainerRegistryResourceId: containerRegistryId
    associatedApplicationInsightsResourceId: applicationInsightsId
    publicNetworkAccess: 'Disabled'
    managedNetworkSettings: {
      isolationMode: 'AllowInternetOutbound'
    }
    managedIdentities: {
      systemAssigned: true
    }
    privateEndpoints: [
      {
        subnetResourceId: privateEndpointSubnetId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZoneId
            }
          ]
        }
      }
    ]
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

@description('AI Hub resource ID.')
output resourceId string = aiHub.outputs.resourceId

@description('AI Hub resource name.')
output resourceName string = aiHub.outputs.name

@description('AI Hub workspace endpoint URL.')
output endpoint string = aiHub.outputs.workspaceDiscoveryEndpoint

@description('AI Hub system-assigned managed identity principal ID.')
output principalId string = aiHub.outputs.systemAssignedMIPrincipalId
