// --------------------------------------------------------------------------------
// This BICEP file will add unique Configuration settings to a web app
// --------------------------------------------------------------------------------
param webAppName string = ''
param customAppSettings object = {}
param appInsightsKey string = 'myKey'

// there are no base settings used at this time in the webSite.Bicep, but if there were...
var BASE_SLOT_APPSETTINGS = {
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: 'InstrumentationKey=${appInsightsKey}'
}

resource siteConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${webAppName}/appsettings'
  properties: union(BASE_SLOT_APPSETTINGS, customAppSettings)
}
