// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a Computer Vision Account
//   if existingSecretNames list is supplied: 
//     ONLY create if secretName is not in existingSecretNames list
//     OR forceSecretCreation is true
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param computerVisionName string = 'myComputerVisionName'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P2Y')
param existingSecretNames string = ''
param forceSecretCreation bool = false

// --------------------------------------------------------------------------------
var secretExists = contains(toLower(existingSecretNames), ';${toLower(trim(secretName))};')

resource computerVisionResource 'Microsoft.CognitiveServices/accounts@2022-10-01' existing = { name: computerVisionName }
var computerVisionKey = computerVisionResource.listKeys().key1

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource createSecretValue 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = if (!secretExists || forceSecretCreation) {
  name: secretName
  parent: keyVaultResource
  properties: {
    value: computerVisionKey
    attributes: {
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
  }
}

var createMessage = secretExists ? 'Secret ${secretName} already exists!' : 'Added secret ${secretName}!'
output message string = secretExists && forceSecretCreation ? 'Secret ${secretName} already exists but was recreated!' : createMessage
output secretCreated bool = !secretExists
