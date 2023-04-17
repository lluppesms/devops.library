// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a Forms Recognizer account
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param keyName string = 'mykeyname'
param formsRecognizerName string = 'myformsrecognizername'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')

// --------------------------------------------------------------------------------
resource formsRecognizerResource 'Microsoft.CognitiveServices/accounts@2022-10-01' existing = { name: formsRecognizerName }
var formsRecognizerKey = formsRecognizerResource.listKeys().key1

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName
  resource storageSecret 'secrets' = {
    name: keyName
    properties: {
      value: formsRecognizerKey
      attributes: {
        exp: dateTimeToEpoch(expirationDate)
        nbf: dateTimeToEpoch(enabledDate)
      }
    }
  }
}
