/*
Allowed Resource Types (az network private-link-resource list --help):
Microsoft.AppConfiguration/configurationStores
Microsoft.Authorization/resourceManagementPrivateLinks
Microsoft.Automation/automationAccounts
Microsoft.Batch/batchAccounts
Microsoft.BotService/botServices
Microsoft.Cache/Redis
Microsoft.CognitiveServices/accounts
Microsoft.Compute/diskAccesses
Microsoft.ContainerRegistry/registries
Microsoft.DBforMariaDB/servers
Microsoft.DBforMySQL/servers
Microsoft.DBforPostgreSQL/servers
Microsoft.Sql/servers
Microsoft.DataFactory/factories
Microsoft.Databricks/workspaces
Microsoft.Devices/IotHubs
Microsoft.DigitalTwins/digitalTwinsInstances
Microsoft.DocumentDB/databaseAccounts
Microsoft.EventGrid/domains
Microsoft.EventGrid/topics
Microsoft.EventHub/namespaces
Microsoft.HDInsight/clusters
Microsoft.HealthcareApis/services
Microsoft.HybridCompute/privateLinkScopes
Microsoft.KeyVault/managedHSMs
Microsoft.Keyvault/vaults
Microsoft.MachineLearningServices/workspaces
Microsoft.Media/mediaservices
Microsoft.Network/applicationGateways
Microsoft.PowerBI/privateLinkServicesForPowerBI
Microsoft.Purview/accounts
Microsoft.Search/searchServices
Microsoft.ServiceBus/namespaces
Microsoft.SignalRService/WebPubSub
Microsoft.SignalRService/signalr
Microsoft.Storage/storageAccounts
Microsoft.StorageSync/storageSyncServices
Microsoft.Synapse/workspaces
Microsoft.Web/hostingEnvironments
Microsoft.Web/sites
Microsoft.insights/privateLinkScopes

Sub-resource is the service "GroupID" for the corresponding resource type.
https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource
*/

@description('Required. The remote resource ID to connect via Private Link Service.')
param remoteResourceId string

@description('Required. Azure Region (location) of the Virtual Network for the Private Endpoint.')
param vnetLocation string

@description('Required. Subnet ID for the Private Endpoint.')
param subnetId string

@description('Required. The Sub-Resource "Group ID(s)" obtained from the remote resource that this private endpoint should connect to.')
param service string

@description('Optional. Array of resource IDs for the Private DNS Zone Group.')
param privateDnsZoneIds array = []

@description('Optional. Array of CustomDnsConfigProperties.')
param customDnsConfigs array = []

@description('Optional. Name of the Private Endpoint (default is "remoteResource.name-service").')
param name string = ''

@description('Optional. Resource tags.')
param tags object = {}

var resourceName = last(split(remoteResourceId, '/'))
var endpointName = empty(name) ? '${resourceName}-${service}' : name

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: endpointName
  location: vnetLocation
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: endpointName
        properties: {
          privateLinkServiceId: remoteResourceId
          groupIds: [
            service
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: subnetId
    }
    customDnsConfigs: !empty(customDnsConfigs) ? customDnsConfigs : null
  }

  resource privateDnsZoneGroups 'privateDnsZoneGroups' = if (!empty(privateDnsZoneIds)) {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [for privateDnsZoneResourceId in privateDnsZoneIds: {
        name: last(split(privateDnsZoneResourceId, '/'))
        properties: {
          privateDnsZoneId: privateDnsZoneResourceId
        }
      }]
    }
  }
}
