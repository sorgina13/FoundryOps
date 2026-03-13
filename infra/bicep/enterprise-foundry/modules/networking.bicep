/*
  Module: Networking
  Virtual Network with three subnets and seven private DNS zones for
  Azure AI Foundry, Azure OpenAI, Storage, Key Vault, ACR, and Container Apps.
*/

@description('Virtual Network name.')
param vnetName string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

@description('VNet address prefix.')
param addressPrefix string = '10.0.0.0/16'

// ─── Virtual Network + Subnets ────────────────────────────────────────────────

module vnet 'br/public:avm/res/network/virtual-network:0.5.0' = {
  name: 'vnet-deploy'
  params: {
    name: vnetName
    location: location
    tags: tags
    addressPrefixes: [
      addressPrefix
    ]
    subnets: [
      {
        name: 'snet-foundry'
        addressPrefix: cidrSubnet(addressPrefix, 24, 1)
      }
      {
        name: 'snet-mcp'
        addressPrefix: cidrSubnet(addressPrefix, 24, 2)
        delegations: [
          {
            name: 'containerAppsDelegation'
            properties: {
              serviceName: 'Microsoft.App/environments'
            }
          }
        ]
      }
      {
        name: 'snet-private-endpoints'
        addressPrefix: cidrSubnet(addressPrefix, 24, 3)
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}

// ─── Private DNS Zones ────────────────────────────────────────────────────────

var storageSuffix = environment().suffixes.storage
var privateDnsZoneNames = [
  'privatelink.api.azureml.ms'
  'privatelink.notebooks.azure.net'
  'privatelink.openai.azure.com'
  'privatelink.blob.${storageSuffix}'
  'privatelink.vaultcore.azure.net'
  'privatelink.azurecr.io'
  'privatelink.azurecontainerapps.io'
]

module privateDnsZones 'br/public:avm/res/network/private-dns-zone:0.7.0' = [
  for zoneName in privateDnsZoneNames: {
    name: 'dns-${replace(replace(zoneName, '.', '-'), 'privatelink-', '')}'
    params: {
      name: zoneName
      tags: tags
      virtualNetworkLinks: [
        {
          virtualNetworkResourceId: vnet.outputs.resourceId
          registrationEnabled: false
        }
      ]
    }
  }
]

// ─── Outputs ──────────────────────────────────────────────────────────────────

@description('Virtual Network resource ID.')
output vnetId string = vnet.outputs.resourceId

@description('Subnet resource ID for the foundry tier.')
output foundrySubnetId string = vnet.outputs.subnetResourceIds[0]

@description('Subnet resource ID for the MCP Container Apps tier.')
output mcpSubnetId string = vnet.outputs.subnetResourceIds[1]

@description('Subnet resource ID for private endpoints.')
output privateEndpointSubnetId string = vnet.outputs.subnetResourceIds[2]

@description('Private DNS Zone resource ID for Azure ML / AI Hub.')
output mlPrivateDnsZoneId string = privateDnsZones[0].outputs.resourceId

@description('Private DNS Zone resource ID for Azure OpenAI.')
output openAiPrivateDnsZoneId string = privateDnsZones[2].outputs.resourceId

@description('Private DNS Zone resource ID for Blob Storage.')
output blobPrivateDnsZoneId string = privateDnsZones[3].outputs.resourceId

@description('Private DNS Zone resource ID for Key Vault.')
output kvPrivateDnsZoneId string = privateDnsZones[4].outputs.resourceId

@description('Private DNS Zone resource ID for ACR.')
output acrPrivateDnsZoneId string = privateDnsZones[5].outputs.resourceId
