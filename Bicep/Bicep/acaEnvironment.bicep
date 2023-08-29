// --------------------------------------------------------------------------------------------------------------
// Bicep for deploying a Container Apps Environment
// --------------------------------------------------------------------------------------------------------------
param name string
param location string
param logAnalyticsName string
param logicAppEndpoint string
param appInsightsName string
param redisName string
//param serviceBusName string -- you'll need this if you are storing secrets in the components
param keyVaultName string
param keyVaultPrincipalId string
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

// previous version where the secrets were stored in the component, not in the Key Vault...
// resource redis 'Microsoft.Cache/redis@2022-06-01' existing = { 
//   name: redisName
// }
// var redisPrimaryKey = redis.listKeys().primaryKey
// resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' existing = { 
//   name: serviceBusName
// }
// resource serviceBusResourceRules 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-06-01-preview' existing = {
//   name: 'RootManageSharedAccessKey'
//   parent: serviceBusResource
// }
// var serviceBusConnectString = serviceBusResourceRules.listKeys().primaryConnectionString

// --------------------------------------------------------------------------------------------------------------
resource appInsightsResource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
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

// For more info on KeyVaults in DAPR Components, see:
//   https://endjin.com/blog/2022/05/adventures-in-dapr-ep02
//   https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets?tabs=arm-template
//   https://learn.microsoft.com/en-us/azure/templates/microsoft.app/managedenvironments/daprcomponents?pivots=deployment-language-bicep
resource daprSecretStore 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: 'secretstore'
  parent: acaEnvironment
  properties: {
    componentType: 'secretstores.azure.keyvault'
    version: 'v1'
    ignoreErrors: false
    metadata: [
      {
        name: 'vaultName'
        value: keyVaultName
      }
      {
        name: 'azureClientId'
        value: keyVaultPrincipalId
      }
    ]
    scopes: [ 'trafficcontrolservice', 'finecollectionservice', 'vehicleregistrationservice' ]
  }
}

resource daprStateStore 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: 'statestore'
  parent: acaEnvironment
  properties: {
    componentType: 'state.redis'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    secretStoreComponent: daprSecretStore.name
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
    scopes: [ 'trafficcontrolservice' ]
  }
}

// -- TODO: come up with a way to deploy either/or pubsub (cosmos or svcbus) based on a parameter
// resource daprPubSubCosmos 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = (if pubSubTypeParm == 'cosmos') {
//   name: 'pubsub'
//   parent: acaEnvironment
//   properties: {
//     componentType: 'pubsub.azure.cosmodb'
//     ...
//   }
// }
// resource daprPubSubRabbit 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = (if pubSubTypeParm == 'svcbus') {
//   name: 'pubsub'
//   parent: acaEnvironment
//   properties: {
//     componentType: 'pubsub.azure.servicebus'
//     ...
//   }
// }
// resource daprPubSubRabbit 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = (if pubSubTypeParm == 'rabbitmq') {
//   name: 'pubsub'
//   parent: acaEnvironment
//   properties: {
//     componentType: 'pubsub.rabbitmq' ???
//     ...
//   }
// }

resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: 'pubsub'
  parent: acaEnvironment
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    secretStoreComponent: daprSecretStore.name
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'servicebusconnectionstring'
      }
    ]
    scopes: [ 'trafficcontrolservice', 'finecollectionservice' ]
  }
}
resource daprLogicAppEmailBinding 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
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
        value: logicAppEndpoint
      }
    ]
    scopes: [ 'finecollectionservice' ]
  }
}

// --------------------------------------------------------------------------------------------------------------
output id string = acaEnvironment.id
output name string = acaEnvironment.name
