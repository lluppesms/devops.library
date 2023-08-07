// --------------------------------------------------------------------------------------------------------------
// Bicep for deploying a Container Apps Environment
// --------------------------------------------------------------------------------------------------------------
param name string
param location string
param serviceBusName string
param logAnalyticsName string
//param logicAppEmailUrl string
param logicAppEndpoint string
param appInsightsName string
param redisName string
@description('The workspace to store audit logs.')
@metadata({
  strongType: 'Microsoft.OperationalInsights/workspaces'
  example: '/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.OperationalInsights/workspaces/<workspace_name>'
})
param workspaceId string = ''
param commonTags object = {}


// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~acaEnvironment.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------------------------------------
resource logAnalyticsResource 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' existing = {
  name: logAnalyticsName
}
var logAnalyticsKey = logAnalyticsResource.listKeys().primarySharedKey
var logAnalyticsResourceCustomerId = logAnalyticsResource.properties.customerId

resource redis 'Microsoft.Cache/redis@2022-06-01' existing = { 
  name: redisName
}
var redisPrimaryKey = redis.listKeys().primaryKey

resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' existing = { 
  name: serviceBusName
}
resource serviceBusResourceRules 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-06-01-preview' existing = {
  name: 'RootManageSharedAccessKey'
  parent: serviceBusResource
}
var serviceBusConnectString = serviceBusResourceRules.listKeys().primaryConnectionString

// --------------------------------------------------------------------------------------------------------------
resource appInsightsResource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    //RetentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: workspaceId
  }
}

resource acaEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    daprAIInstrumentationKey: appInsightsResource.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsResourceCustomerId
        sharedKey: logAnalyticsKey
      }
    }
  }
}

resource daprStateStore 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'statestore'
  parent: acaEnvironment
  properties: {
    componentType: 'state.redis'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    secrets: [
      {
        name: 'redispassword'
        value: redisPrimaryKey
      }
      // See https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets?tabs=arm-template
      // See https://learn.microsoft.com/en-us/azure/templates/microsoft.app/managedenvironments/daprcomponents?pivots=deployment-language-bicep
      // {
      //   name: 'redispassword'
      //   keyVaultUrl: 'https://myvaultname.vault.azure.net/secrets/cosmosConnectionString' ???
      //   identity: 'System'
      // }
    ]
    metadata: [
      {
        name: 'redisHost'
        value: '${redisName}.redis.cache.windows.net:6380'
      }
      {
        name: 'redisPassword'
        secretRef: 'redispassword'
      }
      {
        name: 'actorStateStore'
        value: 'true'
      }
      {
        name: 'enableTLS'
        value: 'true'
      }
    ]
    scopes: [
      'trafficcontrolservice'
    ]
  }
}

// -- TODO: come up with a way to deploy either/or pubsub (cosmos or svcbus) based on a parameter
// ( if pubsub = cosmos)
// resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
//   name: 'pubsub'
//   parent: acaEnvironment
//   properties: {
//     componentType: 'pubsub.azure.cosmodb'
//     version: 'v1'
//   }
// }

// ( if pubsub != rabbitmq)
// resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
//   name: 'pubsub'
//   parent: acaEnvironment
//   properties: {
//     componentType: 'pubsub.rabbitmq'
//     version: 'v1'
//   }
// }


// ( if pubsub = svcbus)
resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'pubsub'
  parent: acaEnvironment
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    secrets: [
      {
        name: 'servicebusconnectionstring'
        value: serviceBusConnectString
      }
    ]
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'servicebusconnectionstring'
      }
    ]
    scopes: [ 'trafficcontrolservice', 'finecollectionservice' ]
  }
}

// this syntax is totally a guess and is probably wrong...
// resource daprSecretStore 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
//   name: 'secretstore'
//   parent: acaEnvironment
//   properties: {
//     componentType: 'keyvault'
//     version: 'v1'
//   }


resource daprLogicAppEmailBinding 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'sendmail'
  parent: acaEnvironment
  properties: {
    componentType: 'bindings.http'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    metadata: [
      {
        name: 'url'
        //value: logicAppEmailUrl
        value: logicAppEndpoint
      }
    ]
    scopes: [
      'finecollectionservice'
    ]
  }
}

// --------------------------------------------------------------------------------------------------------------
output id string = acaEnvironment.id
output name string = acaEnvironment.name
