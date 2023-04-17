// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a computer vision account
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param keyName string = 'mykeyname'
param computerVisionName string = 'mycomputervisionname'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')

// --------------------------------------------------------------------------------
resource computerVisionResource 'Microsoft.CognitiveServices/accounts@2022-10-01' existing = { name: computerVisionName }
//var computerVisionKey = '${listKeys(computerVisionResource.id, computerVisionResource.apiVersion).key1}'
var computerVisionKey = computerVisionResource.listKeys().key1

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName
  resource storageSecret 'secrets' = {
    name: keyName
    properties: {
      value: computerVisionKey
      attributes: {
        exp: dateTimeToEpoch(expirationDate)
        nbf: dateTimeToEpoch(enabledDate)
      }
    }
  }
}
