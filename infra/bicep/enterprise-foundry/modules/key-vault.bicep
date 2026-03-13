/*
  Module: Key Vault
  Deploys Azure Key Vault with RBAC authorization, soft-delete,
  purge protection, diagnostic settings, and no public network access.
*/

@description('Key Vault name (max 24 chars).')
@maxLength(24)
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Name of the Log Analytics Workspace for diagnostic settings.')
param logAnalyticsWorkspaceName string

@description('Object IDs of users or groups granted Key Vault Secrets User role.')
param secretsUserObjectIds array = []

// ─── Key Vault ────────────────────────────────────────────────────────────────

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

module keyVault 'br/public:avm/res/key-vault/vault:0.11.0' = {
  name: 'key-vault-deploy'
  params: {
    name: name
    location: location
    tags: tags
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
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
    roleAssignments: [
      for objectId in secretsUserObjectIds: {
        roleDefinitionIdOrName: 'Key Vault Secrets User'
        principalId: objectId
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('Key Vault resource ID.')
output resourceId string = keyVault.outputs.resourceId

@description('Key Vault resource name.')
output resourceName string = keyVault.outputs.name

@description('Key Vault URI.')
output vaultUri string = keyVault.outputs.uri
