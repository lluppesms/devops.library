// --------------------------------------------------------------------------------
// This BICEP file will add unique Configuration settings to a web app
// --------------------------------------------------------------------------------
// NOTE: See https://learn.microsoft.com/en-us/azure/app-service/configure-common?tabs=portal  
// In a Linux app service, any nested JSON app key like AppSettings:MyKey needs to be 
// configured in App Service as AppSettings__MyKey for the key name. 
// In other words, any : should be replaced by __ (double underscore).
// --------------------------------------------------------------------------------
param webAppName string = ''
param appInsightsKey string = 'myKey'
param customAppSettings object = {}

var BASE_SLOT_APPSETTINGS = {
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${appInsightsKey}'
  ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
}

resource siteConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${webAppName}/appsettings'
  properties: union(BASE_SLOT_APPSETTINGS, customAppSettings)
}
