// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a storage account connection
//   if existingSecretNames list is supplied: 
//     ONLY create if secretName is not in existingSecretNames list
//     OR forceSecretCreation is true
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param storageAccountName string = 'myStorageAccountName'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P2Y')
param existingSecretNames string = ''
param forceSecretCreation bool = false

// --------------------------------------------------------------------------------
var secretExists = contains(toLower(existingSecretNames), ';${toLower(trim(secretName))};')

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { name: storageAccountName }
var accountKey = storageAccountResource.listKeys().keys[0].value
var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountResource.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${accountKey}'

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource createSecretValue 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if (!secretExists || forceSecretCreation) {
  name: secretName
  parent: keyVaultResource
  properties: {
    value: storageAccountConnectionString
    attributes: {
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
  }
}

var createMessage = secretExists ? 'Secret ${secretName} already exists!' : 'Added secret ${secretName}!'
output message string = secretExists && forceSecretCreation ? 'Secret ${secretName} already exists but was recreated!' : createMessage
output secretCreated bool = !secretExists
