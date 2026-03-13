/*
  Module: Monitoring
  Deploys Log Analytics Workspace and Application Insights.
  All other modules depend on the workspace name output.
*/

@description('Project name used in resource naming.')
param projectName string

@description('Deployment environment.')
param environment string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('Log retention in days.')
param retentionInDays int = 90

// ─── Log Analytics Workspace ──────────────────────────────────────────────────

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  name: 'log-analytics'
  params: {
    name: 'log-${projectName}-${environment}'
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: retentionInDays
  }
}

// ─── Application Insights ─────────────────────────────────────────────────────

module appInsights 'br/public:avm/res/insights/component:0.4.1' = {
  name: 'app-insights'
  params: {
    name: 'appi-${projectName}-${environment}'
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.resourceId
    kind: 'web'
    applicationType: 'web'
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('Log Analytics Workspace resource ID.')
output workspaceId string = logAnalytics.outputs.resourceId

@description('Log Analytics Workspace name (passed to diagnostic settings).')
output workspaceName string = logAnalytics.outputs.name

@description('Application Insights resource ID.')
output appInsightsId string = appInsights.outputs.resourceId

@description('Application Insights connection string.')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('Application Insights instrumentation key.')
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
