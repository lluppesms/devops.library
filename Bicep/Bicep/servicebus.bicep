// --------------------------------------------------------------------------------
// This BICEP file will create a Service Bus
// --------------------------------------------------------------------------------
param serviceBusName string = 'myservicebusname'
param location string = resourceGroup().location
param topicNames array = [ 'topic1Name' ]
param queueNames array = ['queue1Name', 'queue2Name']
param commonTags object = {}

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~serviceBus.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
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

resource serviceBusAccessKeyResource 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: serviceBusResource
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = [for topicName in topicNames: {
  name: topicName
  parent: serviceBusResource
}]

resource serviceBusQueueResource 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = [for queueName in queueNames: {
  parent: serviceBusResource
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
resource serviceBusAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${serviceBusResource.name}-auditlogs'
  scope: serviceBusResource
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'OperationalLogs'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
      {
        category: 'RuntimeAuditLogs'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

resource serviceBusMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${serviceBusResource.name}-metrics'
  scope: serviceBusResource
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

// --------------------------------------------------------------------------------
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
output name string = serviceBusResource.name
output id string = serviceBusResource.id
output apiVersion string = serviceBusResource.apiVersion
output serviceBusEndpoint string = serviceBusEndpoint
output endpoint string = serviceBusResource.properties.serviceBusEndpoint
