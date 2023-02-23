// --------------------------------------------------------------------------------
// This BICEP file will create an encryption key for an Azure SQL Database
// --------------------------------------------------------------------------------

param sqlServerName string = uniqueString('sql', resourceGroup().id)
param keyVaultName string = 'mykeyvaultname'
param keyName string
param keyUri string
param keyVersion string

resource sqlServerResource 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}
// https://lllsqlvaultdev.vault.azure.net/keys/sqlserver-keyvault-encryption/4d202a08beba45e1b09b3501874c21df
// length = 106
// should be... '4d202a08beba45e1b09b3501874c21df'
//var keyVersion = substring(keyUri, length(keyUri) - 24, 24)
//skip(originalValue, numberToSkip)
// substring(stringToParse, startIndex, length)
// length(keyUri)

resource sqlServerKeyResource 'Microsoft.Sql/servers/keys@2022-05-01-preview' = {
  name: '${keyVaultName}_${keyName}_${keyVersion}'
  parent: sqlServerResource
  properties: {
    serverKeyType: 'AzureKeyVault'
    uri: keyUri
  }
}

resource encryptionResource 'Microsoft.Sql/servers/encryptionProtector@2022-05-01-preview' = {
  name: 'current'
  parent: sqlServerResource
  properties: {
    serverKeyType: 'AzureKeyVault'
    serverKeyName: sqlServerKeyResource.name
  }
}
