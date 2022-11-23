// --------------------------------------------------------------------------------
// This BICEP file will create a Service Bus
// --------------------------------------------------------------------------------
param serviceBusName string = 'myservicebusname'
param location string = resourceGroup().location
param commonTags object = {}

param queueNames array = ['queue1Name', 'queue2Name']

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~serviceBus.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource svcBusResource 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: false
  }
}

resource svcBusRootManageSharedAccessKeyResource 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: svcBusResource
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource svcBusQueueResource 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = [for queueName in queueNames: {
  parent: svcBusResource
  name: queueName
  properties: {
    maxMessageSizeInKilobytes: 256
    lockDuration: 'PT30S'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    enablePartitioning: false
    enableExpress: false
  }
}]

// --------------------------------------------------------------------------------
var serviceBusEndpoint = '${svcBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
output name string = svcBusResource.name
output id string = svcBusResource.id
output apiVersion string = svcBusResource.apiVersion
output endpoint string = serviceBusEndpoint
