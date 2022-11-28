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

// --------------------------------------------------------------------------------
// var iotHubName            = '${orgPrefix}-${appPrefix}-hub-${environmentCode}${appSuffix}'
// var iotStorageAccountName = '${orgPrefix}${appPrefix}stghub${environmentCode}${appSuffix}'
// var iotStorageContainerName = 'iothubuploads'
var templateTag = { TemplateFile: '~iothub.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
// create a storage account for the Iot Hub to use
resource iotStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: iotStorageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}
// --------------------------------------------------------------------------------
// create a container inside that storage account
resource iotStorageContainerResource 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${iotStorageAccountName}/default/${iotStorageContainerName}'
  dependsOn: [
    iotStorageAccountResource
  ]}
var iotStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${iotStorageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(iotStorageAccountResource.id, iotStorageAccountResource.apiVersion).keys[0].value}'

// --------------------------------------------------------------------------------
// create an IoT Hub and link it to the Storage Container
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' = {
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
    features: 'None'
    minTlsVersion: '1.2'
    disableLocalAuth: false
    allowedFqdnList: []
    enableDataResidency: false
  }
}

// --------------------------------------------------------------------------------
output name string = iotHubResource.name
output id string = iotHubResource.id
output apiVersion string = iotHubResource.apiVersion
output storageAccountName string = iotStorageAccountName
output storageContainerName string = iotStorageContainerName
