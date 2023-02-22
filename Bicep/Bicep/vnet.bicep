@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. An Array of 1 or more IP Address Prefixes for the Virtual Network.')
@minLength(1)
param vNetAddressPrefixes array

@description('Required. An Array of subnets to deploy to the Virtual Network.')
@minLength(1)
param subnets array

@description('Required. The 1-character code representing the environment (Production, Development, Test, Staging, Reference).')
@allowed([
  'p'
  'd'
  't'
  's'
  'r'
])
param envCode string

@description('Optional. Application workload segment name.')
param applicationName string = ''

@description('Optional. Instance number (1-999).')
@minValue(1)
@maxValue(999)
param instanceNum int = 1

@description('Optional. DNS Servers associated to the Virtual Network.')
param dnsServers array = []

@description('Optional. Resource Id of the DDoS protection plan to assign the VNET to. If it\'s left blank, DDoS protection will not be configured. If it\'s provided, the VNET created by this template will be attached to the referenced DDoS protection plan. The DDoS protection plan can exist in the same or in a different subscription.')
param ddosProtectionPlanId string = ''

@description('Optional. Virtual Network Peerings configurations')
param virtualNetworkPeerings array = []

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource identifier of the Diagnostic Storage Account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource identifier of Log Analytics.')
param workspaceId string = ''

@description('Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param eventHubAuthorizationRuleId string = ''

@description('Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param eventHubName string = ''

@description('Optional. Specify the type of lock.')
@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
param lock string = 'CanNotDelete'

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'VMProtectionAlerts'
])
param logsToEnable array = [
  'VMProtectionAlerts'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

var prefix = empty(applicationName) ? 'dowaz${envCode}' : 'dowaz${envCode}-${applicationName}'
var name = '${prefix}-vnet-${padLeft(instanceNum, 3, '0')}'

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var dhcpOptions = {
  dnsServers: dnsServers
}
var ddosProtectionPlan = {
  id: ddosProtectionPlanId
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: vNetAddressPrefixes
    }
    ddosProtectionPlan: !empty(ddosProtectionPlanId) ? ddosProtectionPlan : null
    dhcpOptions: !empty(dnsServers) ? dhcpOptions : null
    enableDdosProtection: !empty(ddosProtectionPlanId)
    subnets: [for item in subnets: {
      name: contains(item, 'nameSuffix') ? '${prefix}-${item.nameSuffix}' : item.name
      properties: {
        addressPrefix: item.addressPrefix
        networkSecurityGroup: contains(item, 'networkSecurityGroupName') ? (empty(item.networkSecurityGroupName) ? null : json('{"id": "${resourceId('Microsoft.Network/networkSecurityGroups', item.networkSecurityGroupName)}"}')) : null
        routeTable: contains(item, 'routeTableName') ? (empty(item.routeTableName) ? null : json('{"id": "${resourceId('Microsoft.Network/routeTables', item.routeTableName)}"}')) : null
        serviceEndpoints: contains(item, 'serviceEndpoints') ? (empty(item.serviceEndpoints) ? null : item.serviceEndpoints) : null
        delegations: contains(item, 'delegations') ? (empty(item.delegations) ? null : item.delegations) : null
        natGateway: contains(item, 'natGatewayName') ? (empty(item.natGatewayName) ? null : json('{"id": "${resourceId('Microsoft.Network/natGateways', item.natGatewayName)}"}')) : null
        privateEndpointNetworkPolicies: contains(item, 'privateEndpointNetworkPolicies') ? (empty(item.privateEndpointNetworkPolicies) ? null : item.privateEndpointNetworkPolicies) : null
        privateLinkServiceNetworkPolicies: contains(item, 'privateLinkServiceNetworkPolicies') ? (empty(item.privateLinkServiceNetworkPolicies) ? null : item.privateLinkServiceNetworkPolicies) : null
      }
    }]
  }
}

module virtualNetworkPeerings_resource 'vnet.peering.bicep' = [for (vnetPeering, index) in virtualNetworkPeerings: {
  name: '${uniqueString(deployment().name, location)}-virtualNetworkPeering-${index}'
  params: {
    localVnetId: virtualNetwork.id
    remoteVnetId: vnetPeering.remoteVirtualNetworkId
    allowVirtualNetworkAccess: contains(vnetPeering, 'allowVirtualNetworkAccess') ? vnetPeering.allowVirtualNetworkAccess : true
    allowForwardedTraffic: contains(vnetPeering, 'allowForwardedTraffic') ? vnetPeering.allowForwardedTraffic : true
    allowGatewayTransit: contains(vnetPeering, 'allowGatewayTransit') ? vnetPeering.allowGatewayTransit : false
    useRemoteGateways: contains(vnetPeering, 'useRemoteGateways') ? vnetPeering.useRemoteGateways : false
    doNotVerifyRemoteGateways: contains(vnetPeering, 'doNotVerifyRemoteGateways') ? vnetPeering.doNotVerifyRemoteGateways : true
    createPairedPeer: contains(vnetPeering, 'createPairedPeer') ? vnetPeering.createPairedPeer : true
  }
}]

resource virtualNetwork_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${virtualNetwork.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: virtualNetwork
}

resource appServiceEnvironment_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(workspaceId) || !empty(eventHubAuthorizationRuleId) || !empty(eventHubName)) {
  name: '${virtualNetwork.name}-diagnosticSettings'
  properties: {
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    workspaceId: empty(workspaceId) ? null : workspaceId
    eventHubAuthorizationRuleId: empty(eventHubAuthorizationRuleId) ? null : eventHubAuthorizationRuleId
    eventHubName: empty(eventHubName) ? null : eventHubName
    metrics: empty(diagnosticStorageAccountId) && empty(workspaceId) && empty(eventHubAuthorizationRuleId) && empty(eventHubName) ? null : diagnosticsMetrics
    logs: empty(diagnosticStorageAccountId) && empty(workspaceId) && empty(eventHubAuthorizationRuleId) && empty(eventHubName) ? null : diagnosticsLogs
  }
  scope: virtualNetwork
}

@description('The resource group the virtual network was deployed into')
output virtualNetworkResourceGroup string = resourceGroup().name

@description('The resourceId of the virtual network')
output virtualNetworkResourceId string = virtualNetwork.id

@description('The name of the virtual network')
output virtualNetworkName string = virtualNetwork.name

@description('The names of the deployed subnets')
output subnetNames array = [for subnet in subnets: contains(subnet, 'nameSuffix') ? '${prefix}-${subnet.nameSuffix}' : subnet.name]

@description('The resourceIds of the deployed subnets')
output subnetIds array = [for subnet in subnets: resourceId('Microsoft.Network/virtualNetworks/subnets', name, contains(subnet, 'nameSuffix') ? '${prefix}-${subnet.nameSuffix}' : subnet.name)]
