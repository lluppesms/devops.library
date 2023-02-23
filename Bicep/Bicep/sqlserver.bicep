// --------------------------------------------------------------------------------
// This BICEP file will create an Azure SQL Database
// --------------------------------------------------------------------------------
param sqlServerName string = uniqueString('sql', resourceGroup().id)
param sqlDBName string = 'SampleDB'
@allowed(['Standard','Premium','BusinessCritical'])
param sqlDbTier string = 'Standard'
param adAdminUserId string = 'somebody@somedomain.com'
param adAdminUserSid string = '12345678-1234-1234-1234-123456789012'
param adAdminTenantId string = '12345678-1234-1234-1234-123456789012'
param location string = resourceGroup().location
param commonTags object = {}
// param sqldbAdminUserId string
// @secure()
// param sqldbAdminPassword string

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~sqlserver.bicep' }
var tags = union(commonTags, templateTag)
var adminDefinition = adAdminUserId == '' ? {} : {
  administratorType: 'ActiveDirectory'
  principalType: 'Group'
  login: adAdminUserId
  sid: adAdminUserSid
  tenantId: adAdminTenantId
  azureADOnlyAuthentication: true
} 
var primaryUser =  adAdminUserId == '' ? '' : adAdminUserId

// --------------------------------------------------------------------------------
resource sqlServerResource 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administrators: adminDefinition
    primaryUserAssignedIdentityId: primaryUser
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Enabled'
    version: '12.0'
    // administratorLogin: sqldbAdminUserId
    // administratorLoginPassword: sqldbAdminPassword
    //keyId: 'string' // A CMK URI of the key to use for encryption.
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
