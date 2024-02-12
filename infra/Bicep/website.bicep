// --------------------------------------------------------------------------------
// This BICEP file will create a Azure Website
// --------------------------------------------------------------------------------
param webSiteName string = 'myWebSiteName'
param webSiteAppServicePlanName string = 'myWebSiteAppServicePlanName'
param webSiteAppInsightsName string = 'myWebSiteAppInsightsName'
param location string = resourceGroup().location
param commonTags object = {}

param appInsightsLocation string = resourceGroup().location
@allowed(['F1','B1','B2','S1','S2','S3'])
param sku string = 'F1'
param linuxFxVersion string = 'DOTNETCORE|6.0'

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~website.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource appInsightsResource 'Microsoft.Insights/components@2020-02-02' = {
  name: webSiteAppInsightsName
  location: appInsightsLocation
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: workspaceId
  }
}

resource appServiceResource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: webSiteAppServicePlanName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webSiteResource 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    serverFarmId: appServiceResource.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      remoteDebuggingEnabled: false
      appSettings: [
        { 
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsResource.properties.InstrumentationKey 
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsResource.properties.InstrumentationKey}'
        }
      ]
    }
  }
}

resource webSiteAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webSiteResource
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

// can't seem to get this to work right... tried multiple ways...  keep getting this error:
//    No route registered for '/api/siteextensions/Microsoft.ApplicationInsights.AzureWebSites'.
// resource webSiteAppInsightsExtension 'Microsoft.Web/sites/siteextensions@2020-06-01' = {
//   parent: webSiteResource
//   name: 'Microsoft.ApplicationInsights.AzureWebSites'
//   dependsOn: [ appInsightsResource] or [ appInsightsResource, webSiteAppSettings ]
// }

resource webSiteMetricsLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webSiteResource.name}-metrics'
  scope: webSiteResource
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
resource webSiteAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webSiteResource.name}-auditlogs'
  scope: webSiteResource
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
      {
        category: 'AppServiceAuditLogs'
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

output principalId string = webSiteResource.identity.principalId
output name string = webSiteResource.name
output insightsName string = webSiteAppInsightsName
output insightsKey string = appInsightsResource.properties.InstrumentationKey
