<#
.SYNOPSIS
    Deploys the Enterprise Foundry infrastructure to Azure.

.DESCRIPTION
    Runs pre-flight checks, lints and builds the Bicep templates, executes
    a what-if preview, and (with confirmation) deploys to the target resource group.

.PARAMETER ResourceGroupName
    Name of the target resource group. Created if it does not exist.

.PARAMETER Location
    Azure region for the resource group (default: swedencentral).

.PARAMETER ParameterFile
    Path to the .bicepparam parameter file (default: ./main.bicepparam).

.PARAMETER WhatIf
    Preview changes only — do not deploy.

.EXAMPLE
    ./deploy.ps1 -ResourceGroupName rg-foundry-prod -WhatIf

.EXAMPLE
    ./deploy.ps1 -ResourceGroupName rg-foundry-prod
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$Location = 'swedencentral',

    [Parameter()]
    [string]$ParameterFile = './main.bicepparam',

    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# ─── Pre-flight checks ────────────────────────────────────────────────────────

Write-Host '🔍 Running pre-flight checks...' -ForegroundColor Cyan

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI not found. Install from https://aka.ms/installazurecli'
}

if (-not (az bicep version 2>$null)) {
    Write-Host '⚙️  Installing Bicep CLI...'
    az bicep install
}

$account = az account show --query 'name' -o tsv 2>$null
if (-not $account) {
    throw 'Not authenticated. Run: az login'
}
Write-Host "✅ Authenticated to subscription: $account"

# ─── Validate templates ───────────────────────────────────────────────────────

Write-Host '🔨 Building Bicep templates...' -ForegroundColor Cyan
az bicep build --file main.bicep
if ($LASTEXITCODE -ne 0) { throw 'Bicep build failed.' }

Write-Host '🔍 Linting Bicep templates...' -ForegroundColor Cyan
az bicep lint --file main.bicep
if ($LASTEXITCODE -ne 0) { throw 'Bicep lint failed.' }

# ─── Ensure resource group exists ────────────────────────────────────────────

$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq 'false') {
    Write-Host "📦 Creating resource group '$ResourceGroupName' in '$Location'..."
    az group create --name $ResourceGroupName --location $Location --output none
}

# ─── What-If preview ─────────────────────────────────────────────────────────

Write-Host '🔎 Running what-if preview...' -ForegroundColor Cyan
az deployment group what-if `
    --resource-group $ResourceGroupName `
    --template-file main.bicep `
    --parameters $ParameterFile

if ($WhatIf) {
    Write-Host '✅ What-if complete. Deployment skipped (--WhatIf).' -ForegroundColor Green
    exit 0
}

# ─── Confirm deploy ───────────────────────────────────────────────────────────

Write-Host ''
$confirm = Read-Host '⚠️  Proceed with deployment? (y/N)'
if ($confirm -notin @('y', 'Y', 'yes')) {
    Write-Host 'Deployment cancelled.' -ForegroundColor Yellow
    exit 0
}

# ─── Deploy ───────────────────────────────────────────────────────────────────

$deploymentName = "deploy-foundry-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "🚀 Deploying as '$deploymentName'..." -ForegroundColor Cyan

az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file main.bicep `
    --parameters $ParameterFile `
    --output json

if ($LASTEXITCODE -ne 0) { throw 'Deployment failed.' }

Write-Host '✅ Deployment succeeded!' -ForegroundColor Green

# ─── Show outputs ─────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '📋 Deployment outputs:' -ForegroundColor Cyan
az deployment group show `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --query 'properties.outputs' `
    -o table
