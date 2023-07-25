// --------------------------------------------------------------------------------
// This BICEP file will create an Azure SQL Database
// TODO: Add support for SQL Server Firewall Rules
// TODO: Add support for Elastic Pools
// --------------------------------------------------------------------------------
param sqlServerName string = uniqueString('sql', resourceGroup().id)
param sqlDBName string = 'SampleDB'
param adAdminUserId string = '' // 'somebody@somedomain.com'
param adAdminUserSid string = '' // '12345678-1234-1234-1234-123456789012'
param adAdminTenantId string = '' // '12345678-1234-1234-1234-123456789012'
param location string = resourceGroup().location
param commonTags object = {}

// basic serverless config: Tier='GeneralPurpose', Family='Gen5', Name='GP_S_Gen5'
@allowed(['Basic','Standard','Premium','BusinessCritical','GeneralPurpose'])
param sqlSkuTier string = 'GeneralPurpose'
param sqlSkuFamily string = 'Gen5'
param sqlSkuName string = 'GP_S_Gen5'
param mincores int = 2 // number of cores (from 0.5 to 40)
param autopause int = 60 // time in minutes

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
  tags: tags
  sku: {
    name: sqlSkuName
    tier: sqlSkuTier
    family: sqlSkuFamily
    capacity: 2
  }
  //kind: 'v12.0,user,vcore,serverless'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 4294967296  // 34359738368 = 32G; 4294967296 = 4G
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    autoPauseDelay: autopause
    requestedBackupStorageRedundancy: 'Geo'
    minCapacity: mincores
    isLedgerOn: false
  }
}

// --------------------------------------------------------------------------------
output serverName string = sqlServerResource.name
output serverId string = sqlServerResource.id
output serverPrincipalId string = sqlServerResource.identity.principalId
output apiVersion string = sqlServerResource.apiVersion
output databaseName string = sqlDBResource.name
output databaseId string = sqlDBResource.id
