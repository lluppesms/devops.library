// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a service bus connection
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param keyName string = 'mykeyname'
param serviceBusName string = 'myservicebusname'
param accessKeyName string = 'RootManageSharedAccessKey'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')

// --------------------------------------------------------------------------------
resource serviceBusResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = { name: serviceBusName }
var serviceBusEndpoint = '${serviceBusResource.id}/AuthorizationRules/RootManageSharedAccessKey' 
var serviceBusConnectionString       = 'Endpoint=sb://${serviceBusResource.name}.servicebus.windows.net/;SharedAccessKeyName=${accessKeyName};SharedAccessKey=${listKeys(serviceBusEndpoint, serviceBusResource.apiVersion).primaryKey}' 

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName
  resource serviceBusSecret 'secrets' = {
    name: keyName
    properties: {
      value: serviceBusConnectionString
      attributes: {
        exp: dateTimeToEpoch(expirationDate)
        nbf: dateTimeToEpoch(enabledDate)
      }
    }
  }
}
