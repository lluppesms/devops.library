// --------------------------------------------------------------------------------
// Creates the logic app service and associated resources
// --------------------------------------------------------------------------------
param logicAppServiceName string = 'myLogicAppServiceName'
param logicAppStorageAccountName string = 'myLogicAppStorageAccountName'
param location string = resourceGroup().location
param commonTags object = {}
param logicAnalyticsWorkspaceId string = 'myLogicAnalyticsWorkspaceId'
param minimumElasticSize int = 1
@allowed(['Allow','Deny'])
param allowStorageNetworkAccess string = 'Allow'

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~logic-app-service.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
// Storage account for the service
resource storageResource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: logicAppStorageAccountName
  location: location
  sku: {
      name: 'Standard_GRS'
  }
  tags: tags
  kind: 'StorageV2'
  properties: {
      networkAcls: {
          bypass: 'AzureServices'
          defaultAction: allowStorageNetworkAccess
          ipRules: []
          // ipRules: (empty(ipRules) ? json('[]') : ipRules)
          virtualNetworkRules: []
          //virtualNetworkRules: ((virtualNetworkType == 'External') ? json('[{"id": "${subscription().id}/resourceGroups/${vnetResource}/providers/Microsoft.Network/virtualNetworks/${vnetResource.name}/subnets/${subnetName}"}]') : json('[]'))
      }
      supportsHttpsTrafficOnly: true
      encryption: {
          services: {
              file: {
                  keyType: 'Account'
                  enabled: true
              }
              blob: {
                  keyType: 'Account'
                  enabled: true
              }
          }
          keySource: 'Microsoft.Storage'
      }
      accessTier: 'Hot'
      allowBlobPublicAccess: false
      minimumTlsVersion: 'TLS1_2'
  }
}
// Dedicated app plan for the service
resource logicAppPlanResource 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: logicAppServiceName
  location: location
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  tags: tags
  properties: {
    targetWorkerCount: minimumElasticSize
    maximumElasticWorkerCount: 20
    isSpot: false
    zoneRedundant: false
  }
}

// Create application insights
resource appInsightsResource 'Microsoft.Insights/components@2020-02-02' = {
  name: logicAppServiceName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    RetentionInDays: 30
    WorkspaceResourceId: logicAnalyticsWorkspaceId
  }
}

// App service containing the workflow runtime
resource logicAppSiteResource 'Microsoft.Web/sites@2021-02-01' = {
  name: logicAppServiceName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageResource.name};AccountKey=${listKeys(storageResource.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageResource.name};AccountKey=${listKeys(storageResource.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'app-${logicAppServiceName}-logicservice-a6e9'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsResource.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsResource.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
      ]
      use32BitWorkerProcess: true
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
    }
    serverFarmId: logicAppPlanResource.id
    clientAffinityEnabled: false
  }
}

// --------------------------------------------------------------------------------
output name string = logicAppSiteResource.name
output id string = logicAppSiteResource.id
output managedIdentityPrincipalId string = logicAppSiteResource.identity.principalId
output storageResourceName string = storageResource.name
output planName string = logicAppPlanResource.name
output insightsKey string = appInsightsResource.properties.InstrumentationKey
