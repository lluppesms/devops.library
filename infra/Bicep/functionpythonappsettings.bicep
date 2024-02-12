// --------------------------------------------------------------------------------
// This BICEP file will add unique Configuration settings to a web or function app
// ----------------------------------------------------------------------------------------------------
param functionAppName string = 'myfunctionname'
param functionStorageAccountName string = 'myfunctionstoragename'
param functionInsightsKey string = 'myKey'
param customAppSettings object = {}

// ----------------------------------------------------------------------------------------------------
resource functionAppResource 'Microsoft.Web/sites@2022-03-01' existing = { name: functionAppName }

// This *should* work, but I get a "circular dependency detected" error and it doesn't work
// var BASE_SLOT_APPSETTINGS = list('${functionAppResource.id}/config/appsettings', functionAppResource.apiVersion).properties

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2019-06-01' existing = { name: functionStorageAccountName }
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'
var BASE_SLOT_APPSETTINGS = {
  AzureWebJobsStorage: storageAccountConnectionString
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageAccountConnectionString
  WEBSITE_CONTENTSHARE: functionAppName
  // APPINSIGHTS_INSTRUMENTATIONKEY: functionInsightsKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${functionInsightsKey}'
  FUNCTIONS_WORKER_RUNTIME: 'python'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
}

var updatedSettings = union(BASE_SLOT_APPSETTINGS, customAppSettings)

resource siteConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: functionAppResource
  name: 'appsettings'
  properties: updatedSettings
}
