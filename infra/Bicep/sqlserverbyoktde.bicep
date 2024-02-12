// --------------------------------------------------------------------------------
// This BICEP file will enable TDE Encryption on an Azure SQL Database with your key
// --------------------------------------------------------------------------------
param sqlServerName string = uniqueString('sql', resourceGroup().id)
param keyVaultName string = 'mykeyvaultname'
param keyName string
param keyUri string
param keyVersion string

// --------------------------------------------------------------------------------
resource sqlServerResource 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
}

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
