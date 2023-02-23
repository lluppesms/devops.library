// --------------------------------------------------------------------------------
// This BICEP file will create an encryption key for an Azure SQL Database
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param keyName string
@allowed(['RSA', 'RSA-HSM', 'EC', 'EC-HSM', 'oct','oct-HSM'])
param keyType string = 'RSA'         // RSA, RSA-HSM, EC, EC-HSM, oct, oct-HSM
@allowed([2048, 3072, 4096])
param keySize int = 2048
@allowed(['P-256', 'P-256K', 'P-384', 'P-521'])
param curveName string = 'P-256'

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource keyResource 'Microsoft.KeyVault/vaults/keys@2021-11-01-preview' = {
  parent: keyVaultResource
  name: keyName
  properties: {
    kty: keyType
    keySize: keySize
    curveName: curveName
    // keyOps: // no value = ALL ops (encrypt, decrypt, sign, verify, wrapKey, unwrapKey)
  }
}

// --------------------------------------------------------------------------------
output name string = keyName
output keyId string = keyResource.id
output keyVersion string = substring(keyResource.properties.keyUriWithVersion, length(keyResource.properties.keyUriWithVersion) - 32, 32) 
output keyUri string = keyResource.properties.keyUri
output keyUriWithVersion string = keyResource.properties.keyUriWithVersion
