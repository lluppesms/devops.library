// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a storage account connection
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param keyName string = 'mykeyname'
param storageAccountName string = 'mystorageaccountname'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')

// --------------------------------------------------------------------------------
resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: storageAccountName }
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value}'

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName
  resource storageSecret 'secrets' = {
    name: keyName
    properties: {
      value: storageAccountConnectionString
      attributes: {
        exp: dateTimeToEpoch(expirationDate)
        nbf: dateTimeToEpoch(enabledDate)
      }
    }
  }
}
