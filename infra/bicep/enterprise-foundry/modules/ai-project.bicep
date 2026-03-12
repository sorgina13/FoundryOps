/*
  Module: AI Foundry Project
  Deploys an AI Foundry Project workspace connected to the Hub.
  Includes GPT-4o and text-embedding-3-large model deployments via
  Azure AI Services (Cognitive Services).
*/

@description('AI Project workspace name.')
param projectName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('AI Foundry Hub resource ID to connect this project to.')
param hubId string

@description('Name of the Log Analytics Workspace for diagnostic settings.')
param logAnalyticsWorkspaceName string

@description('GPT-4o tokens-per-minute capacity (in thousands).')
param gpt4oCapacityK int = 150

@description('Text embedding tokens-per-minute capacity (in thousands).')
param embeddingCapacityK int = 350

// ─── AI Services (Cognitive Services) ────────────────────────────────────────

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

// Azure AI Services endpoint — required by the Foundry Project for model access
module aiServices 'br/public:avm/res/cognitive-services/account:0.10.0' = {
  name: 'ai-services-deploy'
  params: {
    name: 'ais-${projectName}'
    location: location
    tags: tags
    kind: 'AIServices'
    sku: 'S0'
    publicNetworkAccess: 'Disabled'
    customSubDomainName: 'ais-${projectName}'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    managedIdentities: {
      systemAssigned: true
    }
    deployments: [
      {
        name: 'gpt-4o-deployment'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-11-20'
        }
        sku: {
          name: 'Standard'
          capacity: gpt4oCapacityK
        }
      }
      {
        name: 'embedding-deployment'
        model: {
          format: 'OpenAI'
          name: 'text-embedding-3-large'
          version: '1'
        }
        sku: {
          name: 'Standard'
          capacity: embeddingCapacityK
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

// ─── AI Foundry Project ───────────────────────────────────────────────────────

module aiProject 'br/public:avm/res/machine-learning-services/workspace:0.10.0' = {
  name: 'ai-project-deploy'
  params: {
    name: projectName
    location: location
    tags: tags
    kind: 'Project'
    sku: 'Basic'
    hubResourceId: hubId
    publicNetworkAccess: 'Disabled'
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('AI Project resource ID.')
output resourceId string = aiProject.outputs.resourceId

@description('AI Project resource name.')
output resourceName string = aiProject.outputs.name

@description('Azure AI Services endpoint URL.')
output aiServicesEndpoint string = aiServices.outputs.endpoint

@description('Azure AI Services resource ID.')
output aiServicesId string = aiServices.outputs.resourceId

@description('Azure AI Services principal ID.')
output aiServicesPrincipalId string = aiServices.outputs.systemAssignedMIPrincipalId
