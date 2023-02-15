// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Front Door Resource
// ----------------------------------------------------------------------------------------------------
targetScope = 'resourceGroup'

// ----------------------------------------------------------------------------------------------------
@description('The name of the Front Door.')
param name string = deployment().name

@allowed([
  'Premium'
  'Standard'
])
@description('The SKU of the Front Door.')
param sku string = 'Standard'

@description('Configure TLS certificates for custom domains.')
param certificates array = []

@metadata({
  strongType: 'Microsoft.OperationalInsights/workspaces'
  example: '/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.OperationalInsights/workspaces/<workspace_name>'
})
@description('The resource ID to a Log Analytics workspace.')
param workspaceId string = ''

@description('Configures the log categories to send to the Log Analytics workspace.')
param diagnosticLogs array = [
  'FrontDoorAccessLog'
]

@description('Tags to apply to the resource.')
param commonTags object = {}

// ----------------------------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~frontdoor.bicep' }
var tags = union(templateTag, commonTags)
var skuName = '${sku}_AzureFrontDoor'

// ----------------------------------------------------------------------------------------------------
@description('Create or update a Front Door.')
resource profile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: name
  location: 'Global'
  sku: {
    #disable-next-line BCP036
    name: skuName
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
  tags: tags
}

@description('Configure diagnostics logs to send to a workspace.')
resource logs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(workspaceId) && !empty(diagnosticLogs)) {
  name: 'logs'
  scope: profile
  properties: {
    workspaceId: workspaceId
    logs: [for item in diagnosticLogs: {
      category: item
      enabled: true
    }]
  }
}

@description('Configure TLS certificates for custom domains.')
resource certificate 'Microsoft.Cdn/profiles/secrets@2021-06-01' = [for item in certificates: {
  parent: profile
  name: '${split(item, '/')[8]}-${last(split(item, '/'))}'
  properties: {
    parameters: {
      type: 'CustomerCertificate'
      secretSource: {
        id: item
      }
      useLatestVersion: true
    }
  }
}]

// ----------------------------------------------------------------------------------------------------
@description('A unique identifier for the Front Door.')
output id string = profile.id
@description('The name of the Resource Group where the Front Door is deployed.')
output resourceGroupName string = resourceGroup().name
@description('The guid for the subscription where the Front Door is deployed.')
output subscriptionId string = subscription().subscriptionId
@description('A unique guid for the Front Door included in forwarded headers.')
output frontDoorId string = profile.properties.frontDoorId
