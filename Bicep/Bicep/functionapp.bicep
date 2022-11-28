// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Function
// ----------------------------------------------------------------------------------------------------
param functionAppName string = 'myfunctionname'
param functionAppServicePlanName string = 'myfunctionappserviceplanname'
param functionInsightsName string = 'myfunctioninsightsname'

param location string = resourceGroup().location
param appInsightsLocation string = resourceGroup().location
param commonTags object = {}

@allowed([ 'functionapp', 'functionapp,linux' ])
param functionKind string = 'functionapp'
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param functionStorageAccountName string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~functionapp.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2019-06-01' existing = { name: functionStorageAccountName }
var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'

resource appInsightsResource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: functionInsightsName
  location: appInsightsLocation
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    //RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appServiceResource 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: functionAppServicePlanName
  location: location
  kind: functionKind
  tags: tags
  sku: {
    name: functionAppSku
    tier: functionAppSkuTier
    size: functionAppSku
    family: functionAppSkuFamily
    capacity: 0
  }
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

resource functionAppResource 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: functionKind
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: appServiceResource.id
    reserved: false
    isXenon: false
    hyperV: false
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsDashboard'
          value: functionStorageAccountConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: functionStorageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: functionStorageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsResource.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsResource.properties.InstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '8.11.1'
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
        scmSiteAlsoStopped: false
        clientAffinityEnabled: false
        clientCertEnabled: false
        hostNamesDisabled: false
        dailyMemoryTimeQuota: 0
        httpsOnly: true
        redundancyMode: 'None'
  }
}

// resource functionAppConfig 'Microsoft.Web/sites/config@2018-11-01' = {
//     name: '${functionAppResource.name}/web'
//     properties: {
//         numberOfWorkers: -1
//         defaultDocuments: [
//             'Default.htm'
//             'Default.html'
//             'Default.asp'
//             'index.htm'
//             'index.html'
//             'iisstart.htm'
//             'default.aspx'
//             'index.php'
//             'hostingstart.html'
//         ]
//         netFrameworkVersion: 'v4.0'
//         linuxFxVersion: 'dotnet|6.0'
//         requestTracingEnabled: false
//         remoteDebuggingEnabled: false
//         httpLoggingEnabled: false
//         logsDirectorySizeLimit: 35
//         detailedErrorLoggingEnabled: false
//         publishingUsername: '$${functionAppName}'
//         azureStorageAccounts: {            
//         }
//         scmType: 'None'
//         use32BitWorkerProcess: false
//         webSocketsEnabled: false
//         alwaysOn: false
//         managedPipelineMode: 'Integrated'
//         virtualApplications: [
//             {
//                 virtualPath: '/'
//                 physicalPath: 'site\\wwwroot'
//                 preloadEnabled: true
//             }
//         ]
//         loadBalancing: 'LeastRequests'
//         experiments: {
//             rampUpRules: [                
//             ]
//         }
//         autoHealEnabled: false
//         cors: {
//             allowedOrigins: [
//                 'https://functions.azure.com'
//                 'https://functions-staging.azure.com'
//                 'https://functions-next.azure.com'
//             ]
//             supportCredentials: false
//         }
//         localMySqlEnabled: false
//         ipSecurityRestrictions: [
//             {
//                 ipAddress: 'Any'
//                 action: 'Allow'
//                 priority: 1
//                 name: 'Allow all'
//                 description: 'Wide open to the world :)'
//             }
//         ]
//         scmIpSecurityRestrictions: [
//             {
//                 ipAddress: 'Any'
//                 action: 'Allow'
//                 priority: 1
//                 name: 'Allow all'
//                 description: 'Wide open to the world :)'
//             }            
//         ]
//         scmIpSecurityRestrictionsUseMain: false
//         http20Enabled: true
//         minTlsVersion: '1.2'
//         ftpsState: 'AllAllowed'
//         reservedInstanceCount: 0
//     }
// }

// resource functionAppBinding 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
//     name: '${functionAppResource.name}/${functionAppResource.name}.azurewebsites.net'
//     properties: {
//         siteName: functionAppName
//         hostNameType: 'Verified'
//     }
// }

output principalId string = functionAppResource.identity.principalId
output id string = functionAppResource.id
output name string = functionAppName
output insightsName string = functionInsightsName
output insightsKey string = appInsightsResource.properties.InstrumentationKey
output storageAccountName string = functionStorageAccountName
