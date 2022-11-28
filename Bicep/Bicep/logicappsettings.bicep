// --------------------------------------------------------------------------------
// This BICEP file will add unique Configuration settings to a web or function app
// ----------------------------------------------------------------------------------------------------
// To deploy this Bicep manually:
//   az deployment group create -n main-deploy-20220820T140100Z --resource-group rg_rg_durabledemoemo_dev --template-file 'functionAppSettings.bicep' --parameters functionAppName='xxx-rg_durabledemoemo-process-dev' functionStorageAccountName='xxxrg_durabledemoemofuncdevstore' functionInsightsName='xxx-rg_durabledemoemo-process-dev-insights' customAppSettings="{'dateTested':'20220820T140100Z'}" 
// --------------------------------------------------------------------------------
param logicAppName string = 'myLogicAppName'
param logicAppStorageAccountName string = 'myStorageAccountName'
param logicAppInsightsKey string = 'myInsightsKey'
param customAppSettings object = {}

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2019-06-01' existing = { name: logicAppStorageAccountName }
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'

var BASE_SLOT_APPSETTINGS = {
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  WEBSITE_NODE_DEFAULT_VERSION: '8.11.1'

  AzureWebJobsStorage: storageAccountConnectionString
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageAccountConnectionString
  WEBSITE_CONTENTSHARE: logicAppName

  AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
  APP_KIND: 'workflowApp'

  APPINSIGHTS_INSTRUMENTATIONKEY: logicAppInsightsKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${logicAppInsightsKey}'
  ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
}

// --------------------------------------------------------------------------------
// This *should* work, but I keep getting a "circular dependency detected" error and it doesn't work
// resource appResource 'Microsoft.Web/sites@2021-03-01' existing = { name: functionAppName }
// var BASE_SLOT_APPSETTINGS = list('${appResource.id}/config/appsettings', appResource.apiVersion).properties

resource siteConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${logicAppName}/appsettings'
  properties: union(BASE_SLOT_APPSETTINGS, customAppSettings)
}
