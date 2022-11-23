// --------------------------------------------------------------------------------
// This BICEP file will add unique Configuration settings to a web app
// --------------------------------------------------------------------------------
param webAppName string = ''
param customAppSettings object = {}

// there are no base settings used at this time in the webSite.Bicep, but if there were...
var BASE_SLOT_APPSETTINGS = {
}

resource siteConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  name: '${webAppName}/appsettings'
  properties: union(BASE_SLOT_APPSETTINGS, customAppSettings)
}
