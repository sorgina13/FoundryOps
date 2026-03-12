/*
  Module: Storage Account
  Standard_ZRS storage for Foundry artifacts (model checkpoints, datasets).
  HTTPS-only, TLS 1.2, no public blob access, no public network access.
*/

@description('Storage account name (max 24 chars, lowercase alphanumeric only).')
@maxLength(24)
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Name of the Log Analytics Workspace for diagnostic settings.')
param logAnalyticsWorkspaceName string

@description('Minimum TLS version.')
param minimumTlsVersion string = 'TLS1_2'

// ─── Storage Account ──────────────────────────────────────────────────────────

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.18.0' = {
  name: 'storage-account-deploy'
  params: {
    name: name
    location: location
    tags: tags
    skuName: 'Standard_ZRS'
    kind: 'StorageV2'
    accessTier: 'Hot'
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    blobServices: {
      deleteRetentionPolicy: {
        enabled: true
        days: 7
      }
      containerDeleteRetentionPolicy: {
        enabled: true
        days: 7
      }
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
            category: 'Transaction'
          }
        ]
      }
    ]
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('Storage Account resource ID.')
output resourceId string = storageAccount.outputs.resourceId

@description('Storage Account resource name.')
output resourceName string = storageAccount.outputs.name

@description('Storage Account primary blob endpoint.')
output primaryBlobEndpoint string = storageAccount.outputs.primaryBlobEndpoint
