// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Function
// ----------------------------------------------------------------------------------------------------
param functionAppName string = 'myfunctionname'
param functionAppServicePlanName string = 'myfunctionappserviceplanname'
param functionInsightsName string = 'myfunctioninsightsname'

param location string = resourceGroup().location
param appInsightsLocation string = resourceGroup().location
param commonTags object = {}

// @allowed([ 'functionapp', 'functionapp,linux' ])
// param functionKind string = 'functionapp,linux'
param functionAppSku string = 'Y1'
param functionAppSkuFamily string = 'Y'
param functionAppSkuTier string = 'Dynamic'
param functionStorageAccountName string = ''

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~functionapp.bicep' }
var tags = union(commonTags, templateTag)
var publishingUsername = '$${functionAppName}'

var functionKind = 'functionapp,linux'
var linuxFxVersion = 'Python|3.9'

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2019-06-01' existing = { name: functionStorageAccountName }
var accountKey = storageAccountResource.listKeys().keys[0].value
var functionStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${accountKey}'

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
    WorkspaceResourceId: workspaceId
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
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

resource functionAppResource 'Microsoft.Web/sites@2022-03-01' = {
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
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    storageAccountRequired: false
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: functionStorageAccountConnectionString
        }
        // {
        //   name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        //   value: appInsightsResource.properties.InstrumentationKey
        // }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsResource.properties.InstrumentationKey}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
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
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
  }
}

resource functionAppConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionAppResource
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: linuxFxVersion
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: publishingUsername
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
      supportCredentials: false
    }
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 200
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {
    }
  }
}

resource functionAppBinding 'Microsoft.Web/sites/hostNameBindings@2018-11-01' = {
    name: '${functionAppResource.name}/${functionAppResource.name}.azurewebsites.net'
    properties: {
        siteName: functionAppName
        hostNameType: 'Verified'
    }
}

resource functionAppMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${functionAppResource.name}-metrics'
  scope: functionAppResource
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

// https://learn.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs
resource functionAppAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${functionAppResource.name}-logs'
  scope: functionAppResource
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}
resource appServiceMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appServiceResource.name}-metrics'
  scope: appServiceResource
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

output principalId string = functionAppResource.identity.principalId
output id string = functionAppResource.id
output name string = functionAppName
output insightsName string = functionInsightsName
output insightsKey string = appInsightsResource.properties.InstrumentationKey
output storageAccountName string = functionStorageAccountName
