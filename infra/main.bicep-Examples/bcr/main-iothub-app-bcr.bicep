// --------------------------------------------------------------------------------
// Main Bicep file that deploys the Azure Resources for an IoT Hub Application
// Note: Bicep modules are used from the repository defined in bicepconfig.json
// --------------------------------------------------------------------------------
// NOTE: To make this pipeline work, your service principal may need to be in the
//   "acr pull" role for the container registry.
// --------------------------------------------------------------------------------
// Note: To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20230213T110000Z --resource-group rg_iotdemo_dev --template-file 'main-iothub-app-bcr.bicep' --parameters orgPrefix=lll appPrefix=iotdemo environmentCode=dev keyVaultOwnerUserId1=xxxxxxxx-xxxx-xxxx keyVaultOwnerUserId2=xxxxxxxx-xxxx-xxxx
// --------------------------------------------------------------------------------
@allowed(['dev','demo','qa','stg','prod'])
param environmentCode string = 'dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '' // '-1' 
@allowed(['Standard_LRS','Standard_GRS','Standard_RAGRS'])
param storageSku string = 'Standard_LRS'
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param keyVaultOwnerUserId1 string = ''
param keyVaultOwnerUserId2 string = ''
param runDateTime string = utcNow()
param webSiteSku string = 'B1'

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {         
  LastDeployed: runDateTime
  Application: appPrefix
  Organization: orgPrefix
  Environment: environmentCode
}

// --------------------------------------------------------------------------------
module resourceNames '../../Bicep/resourcenames.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environment: environmentCode
    appSuffix: appSuffix
    webAppName: 'dashboard'
    functionName: 'func'
    functionStorageNameSuffix: 'store'
    iotStorageNameSuffix: 'hub'
  }
}

// --------------------------------------------------------------------------------
module storageModule 'br/mybicepregistry:storageaccount:LATEST' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageAccountName: resourceNames.outputs.functionStorageName
    storageSku: storageSku
    location: location
    commonTags: commonTags
  }
}

module iotHubModule 'br/mybicepregistry:iothub:LATEST' = {
  name: 'iotHub${deploymentSuffix}'
  params: {
    iotHubName: resourceNames.outputs.iotHubName
    iotStorageAccountName: resourceNames.outputs.iotStorageAccountName
    iotStorageContainerName: 'iothubuploads'
    location: location
    commonTags: commonTags
  }
}
module dpsModule 'br/mybicepregistry:dps:LATEST' = {
  name: 'dps${deploymentSuffix}'
  dependsOn: [ iotHubModule ]
  params: {
    dpsName: resourceNames.outputs.dpsName
    iotHubName: iotHubModule.outputs.name
    location: location
    commonTags: commonTags
  }
}

module signalRModule 'br/mybicepregistry:signalr:LATEST' = {
  name: 'signalR${deploymentSuffix}'
  params: {
    signalRName: resourceNames.outputs.signalRName
    location: location
    commonTags: commonTags
  }
}

module servicebusModule 'br/mybicepregistry:servicebus:LATEST' = {
  name: 'servicebus${deploymentSuffix}'
  params: {
    serviceBusName: resourceNames.outputs.serviceBusName
    queueNames: [ 'iotmsgs', 'filemsgs' ]
    location: location
    commonTags: commonTags
  }
}

module streamingModule 'br/mybicepregistry:streaming:LATEST' = {
  name: 'streaming${deploymentSuffix}'
  params: {
    saJobName: resourceNames.outputs.saJobName
    iotHubName: iotHubModule.outputs.name
    svcBusName: servicebusModule.outputs.name
    svcBusQueueName: 'iotmsgs'

    location: location
    commonTags: commonTags
  }
}

var cosmosContainerArray = [
  { name: 'DeviceData', partitionKey: '/partitionKey' }
  { name: 'DeviceInfo', partitionKey: '/partitionKey' }
]
module cosmosModule 'br/mybicepregistry:cosmosdatabase:LATEST' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    cosmosAccountName: resourceNames.outputs.cosmosAccountName
    containerArray: cosmosContainerArray
    cosmosDatabaseName: 'IoTDatabase'

    location: location
    commonTags: commonTags
  }
}

module functionModule 'br/mybicepregistry:functionapp:LATEST' = {
  name: 'function${deploymentSuffix}'
  dependsOn: [ storageModule ]
  params: {
    functionAppName: resourceNames.outputs.functionAppName
    functionAppServicePlanName: resourceNames.outputs.functionAppServicePlanName
    functionInsightsName: resourceNames.outputs.functionInsightsName

    functionKind: 'functionapp'
    functionAppSku: functionAppSku
    functionAppSkuFamily: functionAppSkuFamily
    functionAppSkuTier: functionAppSkuTier
    functionStorageAccountName: storageModule.outputs.name

    location: location
    appInsightsLocation: location
    commonTags: commonTags
  }
}

module webSiteModule 'br/mybicepregistry:website:LATEST' = {
  name: 'webSite${deploymentSuffix}'
  params: {
    webSiteName: resourceNames.outputs.webSiteName
    webSiteAppServicePlanName: resourceNames.outputs.webSiteAppServicePlanName
    webSiteAppInsightsName: resourceNames.outputs.webSiteAppInsightsName
    sku: webSiteSku

    location: location
    appInsightsLocation: location
    commonTags: commonTags
  }
}

module keyVaultModule 'br/mybicepregistry:keyvault:LATEST' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ functionModule, webSiteModule ]
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    adminUserObjectIds: [ keyVaultOwnerUserId1, keyVaultOwnerUserId2 ]
    applicationUserObjectIds: [ functionModule.outputs.principalId, webSiteModule.outputs.principalId ]

    location: location
    commonTags: commonTags
  }
}

module keyVaultSecret1 'br/mybicepregistry:keyvaultsecretiothubconnection:LATEST' = {
  name: 'keyVaultSecret1${deploymentSuffix}'
  dependsOn: [ keyVaultModule, iotHubModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'iotHubConnectionString'
    iotHubName: iotHubModule.outputs.name
  }
}

module keyVaultSecret2 'br/mybicepregistry:keyvaultsecretstorageconnection:LATEST' = {
  name: 'keyVaultSecret2${deploymentSuffix}'
  dependsOn: [ keyVaultModule, iotHubModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'iotStorageAccountConnectionString'
    storageAccountName: iotHubModule.outputs.storageAccountName
  }
}

module keyVaultSecret3 'br/mybicepregistry:keyvaultsecretsignalrconnection:LATEST' = {
  name: 'keyVaultSecret3${deploymentSuffix}'
  dependsOn: [ keyVaultModule, signalRModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'signalRConnectionString'
    signalRName: signalRModule.outputs.name
  }
}

module keyVaultSecret4 'br/mybicepregistry:keyvaultsecretcosmosconnection:LATEST' = {
  name: 'keyVaultSecret4${deploymentSuffix}'
  dependsOn: [ keyVaultModule, cosmosModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'cosmosConnectionString'
    cosmosAccountName: cosmosModule.outputs.name
  }
}

module keyVaultSecret5 'br/mybicepregistry:keyvaultsecretservicebusconnection:LATEST' = {
  name: 'keyVaultSecret5${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'serviceBusConnectionString'
    serviceBusName: servicebusModule.outputs.name
  }
}

module keyVaultSecret6 'br/mybicepregistry:keyvaultsecret:LATEST' = {
  name: 'keyVaultSecret6${deploymentSuffix}'
  dependsOn: [ keyVaultModule, functionModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'functionInsightsKey'
    secretValue: functionModule.outputs.insightsKey
  }
}

module keyVaultSecret7 'br/mybicepregistry:keyvaultsecret:LATEST' = {
  name: 'keyVaultSecret7${deploymentSuffix}'
  dependsOn: [ keyVaultModule, webSiteModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'webSiteInsightsKey'
    secretValue: webSiteModule.outputs.insightsKey
  }
}  

module functionAppSettingsModule 'br/mybicepregistry:functionappsettings:LATEST' = {
  name: 'functionAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecret1, keyVaultSecret2, keyVaultSecret3, keyVaultSecret4, keyVaultSecret5, keyVaultSecret6, keyVaultSecret7 ]
  params: {
    functionAppName: functionModule.outputs.name
    functionStorageAccountName: functionModule.outputs.storageAccountName
    functionInsightsKey: functionModule.outputs.insightsKey
    customAppSettings: {
      ServiceBusConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=serviceBusConnectionString)'
      'MySecrets:IoTHubConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=iotHubConnectionString)'
      'MySecrets:SignalRConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=signalRConnectionString)'
      'MySecrets:ServiceBusConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=serviceBusConnectionString)'
      'MySecrets:CosmosConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=cosmosConnectionString)'
      'MySecrets:IotStorageAccountConnectionString': '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=iotStorageAccountConnectionString)'
      'MyConfiguration:WriteToCosmosYN': 'Y'
      'MyConfiguration:WriteToSignalRYN': 'N'
    }
  }
}

module webSiteAppSettingsModule 'br/mybicepregistry:websiteappsettings:LATEST' = {
  name: 'webSiteAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecret1, keyVaultSecret2, keyVaultSecret3, keyVaultSecret4, keyVaultSecret5, keyVaultSecret6, keyVaultSecret7 ]
  params: {
    webAppName: webSiteModule.outputs.name
    customAppSettings: {
      EnvironmentName: environmentCode
      IoTHubConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=iotHubConnectionString)'
      StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=iotStorageAccountConnectionString)'
      CosmosConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=cosmosConnectionString)'
      SignalRConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=signalRConnectionString)'
      ApplicationInsightsKey: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=webSiteInsightsKey)'
    }
  }
}
