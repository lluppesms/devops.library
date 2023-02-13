// --------------------------------------------------------------------------------
// Main Bicep file that deploys the Azure Resources for a Logic Apps Standard App
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n main-deploy-20230213T110000Z --resource-group rg_functiondemo_dev --template-file 'main-logic-app-std-app.bicep' --parameters orgPrefix=xxx appPrefix=fundemo environmentCode=dev keyVaultOwnerUserId1=xxxxxxxx-xxxx-xxxx keyVaultOwnerUserId2=xxxxxxxx-xxxx-xxxx
// --------------------------------------------------------------------------------
@allowed(['dev','demo','qa','stg','prod'])
param environmentCode string = 'dev'
param location string = resourceGroup().location
param orgPrefix string = 'org'
param appPrefix string = 'app'
param appSuffix string = '' // '-1' 
param keyVaultOwnerUserId string = ''

param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
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
  }
}

// --------------------------------------------------------------------------------
module blobStorageAccountModule '../Bicep/storageaccount2.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageAccountName: resourceNames.outputs.blobStorageAccountName
    blobStorageConnectionName: resourceNames.outputs.blobStorageConnectionName
    location: location
    commonTags: commonTags
  }
}

module logAnalyticsModule '../Bicep/loganalyticsworkspace.bicep' = {
  name: 'logAnalytics${deploymentSuffix}' 
  params: {
    logAnalyticsWorkspaceName: resourceNames.outputs.logAnalyticsWorkspaceName
    location: location
    commonTags: commonTags
  }
}

module logicAppServiceModule '../Bicep/logicappservice.bicep' = {
  name: 'logicappservice${deploymentSuffix}'
  params: {
    logicAppServiceName:  resourceNames.outputs.logicAppServiceName
    logicAppStorageAccountName: resourceNames.outputs.logicAppStorageAccountName
    logicAnalyticsWorkspaceId: logAnalyticsModule.outputs.id
    location: location
    commonTags: commonTags
  }
}

module storageAccountRoleModule '../Bicep/storageaccountroles.bicep' = {
  name: 'storageaccountroles${deploymentSuffix}' 
  params: {
    logicAppServiceName: logicAppServiceModule.outputs.name
    storageAccountName: blobStorageAccountModule.outputs.name
    logicAppServicePrincipalId: logicAppServiceModule.outputs.managedIdentityPrincipalId
    blobStorageConnectionName: blobStorageAccountModule.outputs.blobStorageConnectionName
    location: location
  }
}

module keyVaultModule '../Bicep/keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    adminUserObjectIds: [ keyVaultOwnerUserId ]
    applicationUserObjectIds: [ logicAppServiceModule.outputs.managedIdentityPrincipalId ]
    location: location
    commonTags: commonTags
  }
}

module keyVaultSecret1 '../Bicep/keyvaultsecretstorageconnection.bicep' = {
  name: 'keyVaultSecret1${deploymentSuffix}'
  dependsOn: [ keyVaultModule, blobStorageAccountModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'BlobStorageConnectionString'
    storageAccountName: blobStorageAccountModule.outputs.name
  }
}

module logicAppSettingsModule '../Bicep/logicappsettings.bicep' = {
  name: 'logicAppSettings${deploymentSuffix}'
  // dependsOn: [  keyVaultSecrets ]
  params: {
    logicAppName: logicAppServiceModule.outputs.name
    logicAppStorageAccountName: logicAppServiceModule.outputs.storageResourceName
    logicAppInsightsKey: logicAppServiceModule.outputs.insightsKey
    customAppSettings: {
      BLOB_CONNECTION_RUNTIMEURL: blobStorageAccountModule.outputs.connectionRuntimeUrl
      BLOB_STORAGE_CONNECTION_NAME: blobStorageAccountModule.outputs.blobStorageConnectionName
      BLOB_STORAGE_ACCOUNT_NAME: blobStorageAccountModule.outputs.name
      WORKFLOWS_SUBSCRIPTION_ID: subscription().subscriptionId
      WORKFLOWS_RESOURCE_GROUP_NAME: resourceGroup().name
      WORKFLOWS_LOCATION_NAME: location
    }
  }
}
