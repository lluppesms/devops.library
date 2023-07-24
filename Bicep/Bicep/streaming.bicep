// --------------------------------------------------------------------------------
// This BICEP file will create a Stream Analytics Job 
// --------------------------------------------------------------------------------
param saJobName string = 'mystreamingjobname'
param location string = resourceGroup().location
param commonTags object = {}

param sku string = 'StandardV2'
param iotHubName string = ''
param svcBusName string = ''
param svcBusQueueName string = ''

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~streaming.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotHubAccessKey = iotHubResource.listKeys().value[0].primaryKey

resource svcBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: svcBusName }
var svcBusAccessKeyEndpoint = '${svcBusResource.id}/AuthorizationRules/RootManageSharedAccessKey'
var svcBusAccessKey = '${listKeys(svcBusAccessKeyEndpoint, svcBusResource.apiVersion).primaryKey}'

// --------------------------------------------------------------------------------
resource streamingResource 'Microsoft.StreamAnalytics/streamingjobs@2021-10-01-preview' = {
  name: saJobName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: sku
    }
    outputStartMode: 'CustomTime'
    outputStartTime: '2022-06-20T18:37:42Z'
    eventsOutOfOrderPolicy: 'Adjust'
    outputErrorPolicy: 'Stop'
    eventsOutOfOrderMaxDelayInSeconds: 0
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
    compatibilityLevel: '1.2'
    contentStoragePolicy: 'SystemAccount'
    jobType: 'Cloud'
    inputs: [
      {
        name: 'iothub'
        properties: {
          type: 'Stream'
          datasource: {
            type: 'Microsoft.Devices/IotHubs'
            properties: {
              iotHubNamespace: iotHubName
              sharedAccessPolicyName: 'iothubowner'
              sharedAccessPolicyKey: iotHubAccessKey
              endpoint: 'messages/events'
              consumerGroupName: '$Default'
            }
          }
          compression: {
            type: 'None'
          }
          serialization: {
            type: 'Json'
            properties: {
              encoding: 'UTF8'
            }
          }
        }
      }
    ]
    outputs:  [
      {
        name: 'svcbus'
        properties: {
          datasource: {
            type: 'Microsoft.ServiceBus/Queue'
            properties: {
              queueName: svcBusQueueName
              propertyColumns: []
              systemPropertyColumns: {
              }
              serviceBusNamespace: svcBusName
              sharedAccessPolicyName: 'RootManageSharedAccessKey'
              sharedAccessPolicyKey: svcBusAccessKey
              authenticationMode: 'ConnectionString'
            }
          }
          serialization: {
            type: 'Json'
            properties: {
              encoding: 'UTF8'
              format: 'LineSeparated'
            }
          }
        }
      }
    ]
    transformation: {
      name: 'basequery'
      properties: {
        query: 'SELECT * INTO [svcbus] FROM [iothub]'
        streamingUnits: 3
      }
    }  
  }
}

// --------------------------------------------------------------------------------
resource streamingAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${streamingResource.name}-auditlogs'
  scope: streamingResource
  properties: {
    workspaceId: workspaceId
    logs: [
      // { category: 'AllLogs' //  tried several, but can't find the right keyword for this to work...?
      {
        category: 'Execution'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
      {
        category: 'Authoring'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

resource streamingMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${streamingResource.name}-metrics'
  scope: streamingResource
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
output name string = streamingResource.name
output id string = streamingResource.id
