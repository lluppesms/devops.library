// --------------------------------------------------------------------------------
// Main Bicep file that deploys the Azure Resources for a Function App
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20230213T110000Z --resource-group rg_functiondemo_dev --template-file 'main-function-app-bcr.bicep' --parameters orgPrefix=xxx appPrefix=fundemo environmentCode=dev keyVaultOwnerUserId1=xxxxxxxx-xxxx-xxxx keyVaultOwnerUserId2=xxxxxxxx-xxxx-xxxx
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

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {         
  LastDeployed: runDateTime
  Application: appPrefix
  Organization: orgPrefix
  Environment: environmentCode
}
var cosmosDatabaseName = 'FuncDemoDatabase'
var cosmosOrdersContainerDbName = 'orders'
var cosmosOrdersContainerDbKey = '/customerNumber'
var cosmosProductsContainerDbName = 'products'
var cosmosProductsContainerDbKey = '/category'

var svcBusQueueOrders = 'orders-received'
var svcBusQueueERP =  'orders-to-erp' 

// --------------------------------------------------------------------------------
module resourceNames '../../Bicep/resourcenames.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environment: environmentCode
    appSuffix: appSuffix
    functionName: 'process'
    functionStorageNameSuffix: 'store'
    dataStorageNameSuffix: 'data'
  }
}

// --------------------------------------------------------------------------------
module functionStorageModule '../../Bicep/storageaccount.bicep' = {
  name: 'functionstorage${deploymentSuffix}'
  params: {
    storageSku: storageSku
    storageAccountName: resourceNames.outputs.functionStorageName
    location: location
    commonTags: commonTags
  }
}

module servicebusModule '../../Bicep/servicebus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
  params: {
    serviceBusName: resourceNames.outputs.serviceBusName
    queueNames: [ svcBusQueueOrders, svcBusQueueERP ]
    location: location
    commonTags: commonTags
  }
}

var cosmosContainerArray = [
  { name: cosmosProductsContainerDbName, partitionKey: cosmosProductsContainerDbKey }
  { name: cosmosOrdersContainerDbName, partitionKey: cosmosOrdersContainerDbKey }
]

module cosmosModule '../../Bicep/cosmosdatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    cosmosAccountName: resourceNames.outputs.cosmosAccountName
    containerArray: cosmosContainerArray
    cosmosDatabaseName: cosmosDatabaseName

    location: location
    commonTags: commonTags
  }
}
module functionModule '../../Bicep/functionapp.bicep' = {
  name: 'function${deploymentSuffix}'
  dependsOn: [ functionStorageModule ]
  params: {
    functionAppName: resourceNames.outputs.functionAppName
    functionAppServicePlanName: resourceNames.outputs.functionAppServicePlanName
    functionInsightsName: resourceNames.outputs.functionInsightsName

    appInsightsLocation: location
    location: location
    commonTags: commonTags

    functionKind: 'functionapp,linux'
    functionAppSku: functionAppSku
    functionAppSkuFamily: functionAppSkuFamily
    functionAppSkuTier: functionAppSkuTier
    functionStorageAccountName: functionStorageModule.outputs.name
  }
}
module keyVaultModule '../../Bicep/keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ functionModule ]
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    location: location
    commonTags: commonTags
    adminUserObjectIds: [ keyVaultOwnerUserId1, keyVaultOwnerUserId2 ]
    applicationUserObjectIds: [ functionModule.outputs.principalId ]
  }
}
module keyVaultSecret1 '../../Bicep/keyvaultsecret.bicep' = {
  name: 'keyVaultSecret1${deploymentSuffix}'
  dependsOn: [ keyVaultModule, functionModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'functionAppInsightsKey'
    secretValue: functionModule.outputs.insightsKey
  }
}
module keyVaultSecret2 '../../Bicep/keyvaultsecretcosmosconnection.bicep' = {
  name: 'keyVaultSecret2${deploymentSuffix}'
  dependsOn: [ keyVaultModule, cosmosModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'cosmosConnectionString'
    cosmosAccountName: cosmosModule.outputs.name
  }
}
module keyVaultSecret3 '../../Bicep/keyvaultsecretservicebusconnection.bicep' = {
  name: 'keyVaultSecret3${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'serviceBusSendConnectionString'
    serviceBusName: servicebusModule.outputs.name
    accessKeyName: 'send'
  }
}
module keyVaultSecret4 '../../Bicep/keyvaultsecretservicebusconnection.bicep' = {
  name: 'keyVaultSecret4${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'serviceBusReceiveConnectionString'
    serviceBusName: servicebusModule.outputs.name
    accessKeyName: 'listen'
  }
}
module keyVaultSecret5 '../../Bicep/keyvaultsecretstorageconnection.bicep' = {
  name: 'keyVaultSecret5${deploymentSuffix}'
  dependsOn: [ keyVaultModule, functionStorageModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'functionStorageAccountConnectionString'
    storageAccountName: functionStorageModule.outputs.name
  }
}
module functionAppSettingsModule '../../Bicep/functionappsettings.bicep' = {
  name: 'functionAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecret1, keyVaultSecret2, keyVaultSecret3, keyVaultSecret4, keyVaultSecret5, functionModule ]
  params: {
    functionAppName: functionModule.outputs.name
    functionStorageAccountName: functionModule.outputs.storageAccountName
    functionInsightsKey: functionModule.outputs.insightsKey
    customAppSettings: {
      cosmosDatabaseName: cosmosDatabaseName
      cosmosContainerName: cosmosProductsContainerDbName
      ordersContainerName: cosmosOrdersContainerDbName
      orderReceivedQueue: svcBusQueueOrders
      cosmosConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=cosmosConnectionString)'
      serviceBusReceiveConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=serviceBusReceiveConnectionString)'
      serviceBusSendConnectionStringReference: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=serviceBusSendConnectionString)'
    }
  }
}
