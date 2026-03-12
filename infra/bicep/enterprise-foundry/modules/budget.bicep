/*
  Module: Budget
  Monthly consumption budget with three forecast-based alert notifications
  at 80%, 100%, and 120% of the budget amount.
*/

@description('Budget resource name.')
param budgetName string

@description('Monthly budget amount in EUR.')
param amount int

@description('Email address to receive budget alert notifications.')
param alertEmail string

@description('Resource group name scope for the budget.')
param resourceGroupName string

// ─── Budget ───────────────────────────────────────────────────────────────────

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '${take(utcNow('yyyy-MM'), 7)}-01'
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroupName
        ]
      }
    }
    notifications: {
      ForecastAt80Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Forecasted'
        contactEmails: [
          alertEmail
        ]
      }
      ForecastAt100Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [
          alertEmail
        ]
      }
      ForecastAt120Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 120
        thresholdType: 'Forecasted'
        contactEmails: [
          alertEmail
        ]
      }
    }
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('Budget resource ID.')
output resourceId string = budget.id

@description('Budget name.')
output resourceName string = budget.name
