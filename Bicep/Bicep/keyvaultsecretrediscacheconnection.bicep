// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a Redis Cache connection
//   if existingSecretNames list is supplied: 
//     ONLY create if secretName is not in existingSecretNames list
//     OR forceSecretCreation is true
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretNameKey string = 'mySecretNameKey'
param secretNameConnection string = 'mySecretNameConnection'
param redisCacheName string = 'myredisCachename'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P2Y')
param existingSecretNames string = ''
param forceSecretCreation bool = false

// --------------------------------------------------------------------------------
var keySecretExists = contains(toLower(existingSecretNames), ';${toLower(trim(secretNameKey))};')
var connectionSecretExists = contains(toLower(existingSecretNames), ';${toLower(trim(secretNameConnection))};')

resource redisCacheResource 'Microsoft.Cache/redis@2023-04-01' existing = { name: redisCacheName }
var redisCacheKey = redisCacheResource.listKeys().primaryKey
var redisCacheConnectionString = '${redisCacheResource.name}.redis.cache.windows.net:6380,password=${redisCacheKey},ssl=True,abortConnect=False'

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource createSecretValue1 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if (!keySecretExists || forceSecretCreation) {
  name: secretNameKey
  parent: keyVaultResource
  properties: {
    value: redisCacheKey
    attributes: {
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
  }
}
resource createSecretValue2 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if (!connectionSecretExists || forceSecretCreation) {
  name: secretNameConnection
  parent: keyVaultResource
  properties: {
    value: redisCacheConnectionString
    attributes: {
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
  }
}


var createMessageKey = keySecretExists ? 'Secret ${secretNameKey} already exists!' : 'Added secret ${secretNameKey}!'
output messageKey string = keySecretExists && forceSecretCreation ? 'Secret ${secretNameKey} already exists but was recreated!' : createMessageKey
output secretCreatedKey bool = !keySecretExists
var createMessageConnection = connectionSecretExists ? 'Secret ${secretNameConnection} already exists!' : 'Added secret ${secretNameConnection}!'
output messageConnection string = connectionSecretExists && forceSecretCreation ? 'Secret ${secretNameConnection} already exists but was recreated!' : createMessageConnection
output secretCreatedConnection bool = !connectionSecretExists
