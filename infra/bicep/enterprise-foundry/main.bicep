/*
  Enterprise Foundry - Main Bicep Orchestration
  Azure AI Foundry Hub + MCP Catalog + Private Networking
  Region: swedencentral (EU GDPR-compliant)
*/

targetScope = 'resourceGroup'

// ─── Parameters ──────────────────────────────────────────────────────────────

@description('Project name used across all resource names. No default — caller must provide.')
param projectName string

@description('Deployment environment.')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

@description('Primary Azure region for all resources.')
@allowed(['swedencentral', 'germanywestcentral', 'northeurope'])
param location string = 'swedencentral'

@description('Short project name for length-constrained resources (max 8 chars).')
param shortProjectName string = take(projectName, 8)

@description('Monthly budget amount in EUR for cost guard rails.')
param budgetAmount int = 1040

@description('Email address for budget forecast alerts.')
param alertEmail string

@description('Docker image tag for the foundry-mcp container.')
param mcpImageTag string = 'latest'

@description('VNet address prefix.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Minimum TLS version for all storage and AI services.')
param minimumTlsVersion string = 'TLS1_2'

@description('Tags applied to all resources. Governance-discovered tags override these.')
param tags object = {}

// ─── Variables ────────────────────────────────────────────────────────────────

var uniqueSuffix = take(uniqueString(resourceGroup().id), 6)

var commonTags = union(tags, {
  Environment: environment
  ManagedBy: 'Bicep'
  Project: projectName
  Owner: alertEmail
})

// ─── Monitoring (deploy first — all modules depend on workspace) ──────────────

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    projectName: projectName
    environment: environment
    location: location
    tags: commonTags
  }
}

// ─── Key Vault ────────────────────────────────────────────────────────────────

module keyVault 'modules/key-vault.bicep' = {
  name: 'key-vault'
  params: {
    name: 'kv-${shortProjectName}-${environment}-${uniqueSuffix}'
    location: location
    tags: commonTags
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
  }
}

// ─── Storage Account ─────────────────────────────────────────────────────────

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: 'st${shortProjectName}${environment}${uniqueSuffix}'
    location: location
    tags: commonTags
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
    minimumTlsVersion: minimumTlsVersion
  }
}

// ─── Container Registry ───────────────────────────────────────────────────────

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry'
  params: {
    name: 'cr${shortProjectName}${environment}${uniqueSuffix}'
    location: location
    tags: commonTags
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
  }
}

// ─── Networking ───────────────────────────────────────────────────────────────

module networking 'modules/networking.bicep' = {
  name: 'networking'
  params: {
    vnetName: 'vnet-${projectName}-${environment}'
    location: location
    tags: commonTags
    addressPrefix: vnetAddressPrefix
  }
}

// ─── AI Foundry Hub ───────────────────────────────────────────────────────────

module aiHub 'modules/ai-hub.bicep' = {
  name: 'ai-hub'
  params: {
    hubName: 'hub-${projectName}-${environment}'
    location: location
    tags: commonTags
    storageAccountId: storage.outputs.resourceId
    keyVaultId: keyVault.outputs.resourceId
    containerRegistryId: containerRegistry.outputs.resourceId
    applicationInsightsId: monitoring.outputs.appInsightsId
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    privateDnsZoneId: networking.outputs.mlPrivateDnsZoneId
  }
}

// ─── AI Foundry Project ───────────────────────────────────────────────────────

module aiProject 'modules/ai-project.bicep' = {
  name: 'ai-project'
  params: {
    projectName: 'proj-${projectName}-${environment}'
    location: location
    tags: commonTags
    hubId: aiHub.outputs.resourceId
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
  }
}

// ─── MCP Catalog (Container Apps) ────────────────────────────────────────────

module mcpCatalog 'modules/mcp-catalog.bicep' = {
  name: 'mcp-catalog'
  params: {
    environmentName: 'cae-${projectName}-${environment}'
    appName: 'app-foundry-mcp-${environment}'
    location: location
    tags: commonTags
    mcpImageTag: mcpImageTag
    acrLoginServer: containerRegistry.outputs.loginServer
    acrResourceId: containerRegistry.outputs.resourceId
    foundryHubEndpoint: aiHub.outputs.endpoint
    aiServicesEndpoint: aiProject.outputs.aiServicesEndpoint
    keyVaultName: keyVault.outputs.resourceName
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
    mcpSubnetId: networking.outputs.mcpSubnetId
  }
}

// ─── Budget ───────────────────────────────────────────────────────────────────

module budget 'modules/budget.bicep' = {
  name: 'budget'
  params: {
    budgetName: 'budget-${projectName}-${environment}'
    amount: budgetAmount
    alertEmail: alertEmail
    resourceGroupName: resourceGroup().name
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('AI Foundry Hub resource ID.')
output aiHubId string = aiHub.outputs.resourceId

@description('AI Foundry Hub endpoint URL.')
output aiHubEndpoint string = aiHub.outputs.endpoint

@description('AI Foundry Project resource ID.')
output aiProjectId string = aiProject.outputs.resourceId

@description('MCP server public URL (HTTPS).')
output mcpServerUrl string = mcpCatalog.outputs.mcpServerUrl

@description('Container Registry login server.')
output acrLoginServer string = containerRegistry.outputs.loginServer

@description('Key Vault URI.')
output keyVaultUri string = keyVault.outputs.vaultUri

@description('Log Analytics Workspace ID.')
output logAnalyticsWorkspaceId string = monitoring.outputs.workspaceId
