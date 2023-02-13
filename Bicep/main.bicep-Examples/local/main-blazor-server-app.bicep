// --------------------------------------------------------------------------------
// Main Bicep File to deploy all Azure Resources for a Blazor Server Web app
// --------------------------------------------------------------------------------
// Note: To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20230213T110000Z --resource-group rg_blazor_dev --template-file 'main-blazor-server-app.bicep' --parameters orgPrefix=lll appPrefix=blazordemo environmentCode=dev keyVaultOwnerUserId1=xxxxxxxx-xxxx-xxxx
// --------------------------------------------------------------------------------
param environmentCode string = 'dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '' // '-1' 
param storageSku string = 'Standard_LRS'
param keyVaultOwnerUserId1 string = ''
param runDateTime string = utcNow()
param webSiteSku string = 'B1'
param webAppName string = 'dashboard'

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var insightKeyName = 'webSiteInsightsKey${webAppName}' 
var commonTags = {         
  LastDeployed: runDateTime
  Application: appPrefix
  Organization: orgPrefix
  Environment: environmentCode
}

// --------------------------------------------------------------------------------
module resourceNames '../Bicep/resourcenames.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    orgPrefix: orgPrefix
    appPrefix: appPrefix
    environment: environmentCode
    appSuffix: appSuffix
    webAppName: webAppName
  }
}
// --------------------------------------------------------------------------------
module storageModule '../Bicep/storageaccount.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageSku: storageSku
    storageAccountName: resourceNames.outputs.dataStorageName
    location: location
    commonTags: commonTags
  }
}

var cosmosContainerArray = [
  { name: 'DeviceData', partitionKey: '/partitionKey' }
]
module cosmosModule '../Bicep/cosmosdatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    cosmosAccountName: resourceNames.outputs.cosmosAccountName 
    location: location
    commonTags: commonTags
    containerArray: cosmosContainerArray
    cosmosDatabaseName: 'MyDatabase'
  }
}

module webSiteModule '../Bicep/website.bicep' = {
  name: 'webSite${deploymentSuffix}'
  params: {
    webSiteName: resourceNames.outputs.webSiteName
    location: location
    appInsightsLocation: location
    commonTags: commonTags
    sku: webSiteSku
  }
}

module keyVaultModule '../Bicep/keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ webSiteModule ]
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    location: location
    commonTags: commonTags
    adminUserObjectIds: [ keyVaultOwnerUserId1 ]
    applicationUserObjectIds: [ webSiteModule.outputs.principalId ]
  }
}

module keyVaultSecret1 '../Bicep/keyvaultsecret.bicep' = {
  name: 'keyVaultSecret1${deploymentSuffix}'
  dependsOn: [ keyVaultModule, webSiteModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: insightKeyName
    secretValue: webSiteModule.outputs.insightsKey
  }
}  
module keyVaultSecretCosmos '../Bicep/keyvaultsecretcosmosconnection.bicep' = {
  name: 'keyVaultSecretCosmos${deploymentSuffix}'
  dependsOn: [ keyVaultModule, cosmosModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'cosmosConnectionString'
    cosmosAccountName: cosmosModule.outputs.name
  }
}

module webSiteAppSettingsModule '../Bicep/websiteappsettings.bicep' = {
  name: 'webSiteAppSettings${deploymentSuffix}'
  dependsOn: [ keyVaultSecret1 ]
  params: {
    webAppName: webSiteModule.outputs.name
    customAppSettings: {
      EnvironmentName: environmentCode
      CosmosConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=cosmosConnectionString)'
      ApplicationInsightsKey: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=${insightKeyName})'
    }
  }
}
