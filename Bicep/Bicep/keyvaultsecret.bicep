// --------------------------------------------------------------------------------
// This BICEP file will create a KeyVault secret
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param secretName string = 'mysecretname'
@secure()
param secretValue string = ''
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')
param enabled bool = true

// --------------------------------------------------------------------------------
resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// --------------------------------------------------------------------------------
resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  parent: vault
  properties: {
    attributes: {
      enabled: enabled
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
    value: secretValue
  }
}
