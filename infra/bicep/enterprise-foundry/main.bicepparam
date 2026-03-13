/*
  Enterprise Foundry — Parameter File (Production defaults)
  Edit before deploying: projectName, alertEmail are required.
*/

using './main.bicep'

// Required: provide your project name (no default)
param projectName = 'foundry'

// Required: alert email for budget notifications
param alertEmail = 'platform-team@example.com'

param environment = 'prod'
param location = 'swedencentral'
param budgetAmount = 1040
param mcpImageTag = 'latest'
param vnetAddressPrefix = '10.0.0.0/16'
param minimumTlsVersion = 'TLS1_2'

param tags = {
  Environment: 'prod'
  ManagedBy: 'Bicep'
  Project: 'enterprise-foundry'
  Owner: 'platform-team@example.com'
}
