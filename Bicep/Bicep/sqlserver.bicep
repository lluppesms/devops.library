// --------------------------------------------------------------------------------
// This BICEP file will create an Azure SQL Database
// --------------------------------------------------------------------------------
param sqlServerName string = uniqueString('sql', resourceGroup().id)
param sqlDBName string = 'SampleDB'
@allowed(['Standard','Premium','BusinessCritical'])
param sqlDbTier string = 'Standard'
// param localAdminLogin string
// @secure()
// param localAdminPassword string
param adAdminLoginUser string = 'somebody@somedomain.com'
param adAdminLoginSid string = '12345678-1234-1234-1234-123456789012'
param adAdminLoginTenantId string = '12345678-1234-1234-1234-123456789012'

param location string = resourceGroup().location
param commonTags object = {}

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~sqlserver.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource sqlServerResource 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    // administratorLogin: localAdminLogin
    // administratorLoginPassword: localAdminPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: adAdminLoginUser
      sid: adAdminLoginSid
      tenantId: adAdminLoginTenantId
      azureADOnlyAuthentication: true // AAD only authentication enabled
    }

    //keyId: 'string' // A CMK URI of the key to use for encryption.
    minimalTlsVersion: '1.2'
    //primaryUserAssignedIdentityId: 'string' // The resource id of a user assigned identity to be used by default.
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Enabled'
    version: '12.0' // the version of the server
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource sqlDBResource 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServerResource
  name: sqlDBName
  location: location
  sku: {
    name: sqlDbTier
    tier: sqlDbTier
  }
}


// --------------------------------------------------------------------------------
output serverName string = sqlServerResource.name
output serverId string = sqlServerResource.id
output serverPrincipalId string = sqlServerResource.identity.principalId
output apiVersion string = sqlServerResource.apiVersion
output databaseName string = sqlDBResource.name
output databaseId string = sqlDBResource.id
