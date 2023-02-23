// --------------------------------------------------------------------------------
// Main Bicep file that deploys an Azure SQL Database with BYOK TDE enabled
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n cli-sqldb-deploy-20230223T080000Z -g rg_sqldb -f 'main.bicep' -p orgName=xxx appName=byok environmentCode=dev adminLoginUser=yourUser@yourcompany.com adminLoginSid=<yourUserSid> adminLoginTenantId=<yourAdTenantId>
// --------------------------------------------------------------------------------
param orgName string = 'org'
param appName string = 'app'
@allowed(['dev','demo','qa','stg','prod'])
param environmentCode string = 'dev'
param databaseName string = 'myDatabase'
@allowed(['Standard','Premium','BusinessCritical'])
param sqlDbTier string = 'Standard'
param location string = resourceGroup().location
param adminLoginUser string = ''
param adminLoginSid string = ''
param adminLoginTenantId string = ''
param runDateTime string = utcNow()
// param sqldbAdminLogin string = ''
// @secure()
// param sqldbAdminPassword string = ''

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {         
  Organization: orgName
  Application: appName
  Environment: environmentCode
  LastDeployed: runDateTime
}
// --------------------------------------------------------------------------------
module resourceNames '../../Bicep/resourcenames.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    orgPrefix: orgName
    appPrefix: appName
    environment: environmentCode
  }
}

// --------------------------------------------------------------------------------
module sqldbModule '../../Bicep/sqlserver.bicep' = {
  name: 'sql-server${deploymentSuffix}'
  params: {
    sqlServerName: resourceNames.outputs.sqlServerName
    sqlDBName: databaseName
    sqlDbTier: sqlDbTier
    location: location
    commonTags: commonTags
    adAdminLoginUser: adminLoginUser
    adAdminLoginSid: adminLoginSid
    adAdminLoginTenantId: adminLoginTenantId
    // localAdminLogin: sqldbAdminLogin
    // localAdminPassword: sqldbAdminPassword
  }
}

module keyVaultModule '../../Bicep/keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ sqldbModule ]
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    location: location
    commonTags: commonTags
    adminUserObjectIds: [ adminLoginSid ]
    applicationUserObjectIds: [ sqldbModule.outputs.serverPrincipalId ]
  }
}

module keyVaultKeySqlDte '../../Bicep/keyvaultkeysqldte.bicep' = {
  name: 'keyVaultKeyDte${deploymentSuffix}'
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'sqlserver-keyvault-encryption'
  }
}

module sqlDbEncryption '../../Bicep/sqlserverbyoktde.bicep' = {
  name: 'sql-server-tde${deploymentSuffix}'
  params: {
    sqlServerName: sqldbModule.outputs.serverName
    keyVaultName: keyVaultModule.outputs.name
    keyName: keyVaultKeySqlDte.outputs.name
    keyUri: keyVaultKeySqlDte.outputs.keyUriWithVersion
    keyVersion: keyVaultKeySqlDte.outputs.keyVersion
  }
}
