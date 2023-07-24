// --------------------------------------------------------------------------------
// This BICEP file will create a linked IoT Hub and DPS Service
// --------------------------------------------------------------------------------
// NOTE: there is no way yet to automate DPS Enrollment Group creation.
//   After DPS is created, you will need to manually create a group based on
//   the certificate that is created.
// --------------------------------------------------------------------------------
param iotHubName string = 'myIoTHubAccountName'
param iotStorageAccountName string = 'myIotStorageAccountName'
param iotStorageContainerName string = 'iothubuploads'
param location string = resourceGroup().location
param commonTags object = {}
@allowed(['F1','S1','S2','S3'])
param sku string = 'S1'
@allowed(['Allow','Deny'])
param allowStorageNetworkAccess string = 'Allow'

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~iothub.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
// create a storage account for the Iot Hub to use
resource iotStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: iotStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  tags: tags
  kind: 'StorageV2'
  properties: {
      networkAcls: {
          bypass: 'AzureServices'
          defaultAction: allowStorageNetworkAccess
          ipRules: []
          // ipRules: (empty(ipRules) ? json('[]') : ipRules)
          virtualNetworkRules: []
          //virtualNetworkRules: ((virtualNetworkType == 'External') ? json('[{"id": "${subscription().id}/resourceGroups/${vnetResource}/providers/Microsoft.Network/virtualNetworks/${vnetResource.name}/subnets/${subnetName}"}]') : json('[]'))
      }
      supportsHttpsTrafficOnly: true
      encryption: {
          services: {
              file: {
                  keyType: 'Account'
                  enabled: true
              }
              blob: {
                  keyType: 'Account'
                  enabled: true
              }
          }
          keySource: 'Microsoft.Storage'
      }
      accessTier: 'Hot'
      allowBlobPublicAccess: false
      minimumTlsVersion: 'TLS1_2'
  }
}

var iotStorageKey = iotStorageAccountResource.listKeys().keys[0].value
var iotStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${iotStorageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${iotStorageKey}'

// --------------------------------------------------------------------------------
// create a container inside that storage account
resource iotStorageBlobResource 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
  parent: iotStorageAccountResource
  name: 'default'
  properties: {
      cors: {
          corsRules: [
          ]
      }
      deleteRetentionPolicy: {
          enabled: true
          days: 7
      }
  }
}
resource iotStorageContainerResource 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: iotStorageBlobResource
  name: iotStorageContainerName
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

// --------------------------------------------------------------------------------
// create an IoT Hub and link it to the Storage Container
resource iotHubResource 'Microsoft.Devices/IotHubs@2022-04-30-preview' = {
  name: iotHubName
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: 1
  }
  identity: {
    type: 'None'
  }
  properties: {
    // routing: {
    //   endpoints: {
    //     serviceBusQueues: [
    //       {
    //         connectionString: svcBusConnectionString
    //         authenticationType: 'keyBased'
    //         name: 'datatosvcbusroute'
    //         // id: 'faadc3d2-62e3-40a6-b3b0-13d4c9994018'
    //         // subscriptionId: subscription().id  
    //         // resourceGroup: resourceGroup().name
    //       }
    //     ]
    //     serviceBusTopics: []
    //     eventHubs: []
    //     storageContainers: []
    //   }
    //   routes: [
    //     {
    //       name: 'RouteToEventGrid'
    //       source: 'DeviceMessages'
    //       condition: 'true'
    //       endpointNames: [
    //         'eventgrid'
    //       ]
    //       isEnabled: true
    //     }
    //   ]
    //   fallbackRoute: {
    //     name: '$fallback'
    //     source: 'DeviceMessages'
    //     condition: 'true'
    //     endpointNames: [
    //       'events'
    //     ]
    //     isEnabled: true
    //   }
    // }
    storageEndpoints: {
      '$default': {
        sasTtlAsIso8601: 'PT1H'
        connectionString: iotStorageAccountConnectionString
        containerName: iotStorageContainerName
        authenticationType: 'keyBased'
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    enableFileUploadNotifications: true
    cloudToDevice: {
      maxDeliveryCount: 10
      defaultTtlAsIso8601: 'PT1H'
      feedback: {
        lockDurationAsIso8601: 'PT1M'
        ttlAsIso8601: 'PT1H'
        maxDeliveryCount: 10
      }
    }
    // Old IoT Hub defaults to Baltimore CyberTrust Root which will expire in 2025 
    // You must migrate to the DigiCert Global G2 root and these next two lines will do that.
    // To avoid service disruption it must be migrated by September 15th 2023.
    features: 'RootCertificateV2'
    rootCertificate: {
      enableRootCertificateV2: true
    }
    minTlsVersion: '1.2'
    disableLocalAuth: false
    allowedFqdnList: []
    enableDataResidency: false
  }
}

// --------------------------------------------------------------------------------
resource iotHubAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${iotHubResource.name}-auditlogs'
  scope: iotHubResource
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'C2DCommands'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
      {
        category: 'DirectMethods'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

resource iotHubMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${iotHubResource.name}-metrics'
  scope: iotHubResource
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
output name string = iotHubResource.name
output id string = iotHubResource.id
output apiVersion string = iotHubResource.apiVersion
output storageAccountName string = iotStorageAccountName
output storageContainerName string = iotStorageContainerName
