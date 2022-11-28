// --------------------------------------------------------------------------------
// This BICEP file will add unique Configuration settings to a web or function app
// --------------------------------------------------------------------------------
param functionAppName string = 'myfunctionname'
param functionStorageAccountName string = 'myfunctionstoragename'
param functionInsightsKey string = 'myKey'
param customAppSettings object = {}

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2019-06-01' existing = { name: functionStorageAccountName }
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'

var BASE_SLOT_APPSETTINGS = {
  AzureWebJobsDashboard: storageAccountConnectionString
  AzureWebJobsStorage: storageAccountConnectionString
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageAccountConnectionString
  WEBSITE_CONTENTSHARE: functionAppName
  APPINSIGHTS_INSTRUMENTATIONKEY: functionInsightsKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${functionInsightsKey}'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  FUNCTIONS_EXTENSION_VERSION: '~4'
  WEBSITE_NODE_DEFAULT_VERSION: '8.11.1'
}

// This *should* work, but I keep getting a "circular dependency detected" error and it doesn't work
// resource appResource 'Microsoft.Web/sites@2021-03-01' existing = { name: functionAppName }
// var BASE_SLOT_APPSETTINGS = list('${appResource.id}/config/appsettings', appResource.apiVersion).properties

resource siteConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${functionAppName}/appsettings'
  properties: union(BASE_SLOT_APPSETTINGS, customAppSettings)
}
