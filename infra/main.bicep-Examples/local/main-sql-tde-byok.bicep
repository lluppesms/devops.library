// --------------------------------------------------------------------------------
// Main Bicep file that deploys the Azure Resources for an Azure SQL Database
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   Deploy a SQL Database with BYOK TDE:
//     az deployment group create -n cli-sqldb-deploy-20230223T080000Z -g rg_sqldb -f 'main.bicep' -p enableBYOKTDE=true  orgName=xxx appName=byoktde environmentCode=dev adminLoginUserId=you@yourcompany.com adminLoginUserSid=<yourObjectSID> adminLoginTenantId=<yourTenantId>
//   Deploy a SQL Database with System Managed TDE:
//     az deployment group create -n cli-sqldb-deploy-20230223T080000Z -g rg_sqldb -f 'main.bicep' -p enableBYOKTDE=false orgName=xxx appName=systde  environmentCode=dev adminLoginUserId=you@yourcompany.com adminLoginUserSid=<yourObjectSID> adminLoginTenantId=<yourTenantId>
// --------------------------------------------------------------------------------
param orgName string = 'org'
param appName string = 'app'
@allowed(['dev','demo','qa','stg','prod'])
param environmentCode string = 'dev'
param databaseName string = 'myDatabase'
@allowed(['Standard','Premium','BusinessCritical'])
param sqlDbTier string = 'Standard'
param location string = resourceGroup().location
param adminLoginUserId string = ''
param adminLoginUserSid string = ''
param adminLoginTenantId string = ''
// param sqldbAdminUserId string = ''
// @secure()
// param sqldbAdminPassword string = ''
param enableBYOKTDE bool = false
param runDateTime string = utcNow()

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
    adAdminUserId: adminLoginUserId
    adAdminUserSid: adminLoginUserSid
    adAdminTenantId: adminLoginTenantId
    // sqldbAdminUserId: sqldbAdminUserId
    // sqldbAdminPassword: sqldbAdminPassword
  }
}

// <if enableBYOKTDE> --------------------------------------------------------------------------------
module keyVaultModule '../../Bicep/keyvault.bicep' = if (enableBYOKTDE) {
  name: 'keyvault${deploymentSuffix}'
  dependsOn: [ sqldbModule ]
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    location: location
    commonTags: commonTags
    adminUserObjectIds: [ adminLoginUserSid ]
    applicationUserObjectIds: [ sqldbModule.outputs.serverPrincipalId ]
  }
}
var tdeKeyVaultName = enableBYOKTDE ? keyVaultModule.outputs.name : ''

module keyVaultKeySqlDte '../../Bicep/keyvaultkeysqldte.bicep' = if (enableBYOKTDE) {
  name: 'keyVaultKeyDte${deploymentSuffix}'
  dependsOn: [ keyVaultModule, sqldbModule ]
  params: {
    keyVaultName: tdeKeyVaultName
    keyName: '${resourceNames.outputs.sqlServerName}-tde-encryption-key'
  }
}
var tdeKeyName = enableBYOKTDE ? keyVaultKeySqlDte.outputs.name : ''
var tdeKeyUri = enableBYOKTDE ? keyVaultKeySqlDte.outputs.keyUriWithVersion : ''
var tdeKeyVersion = enableBYOKTDE ? keyVaultKeySqlDte.outputs.keyVersion : ''

module sqlDbEncryption '../../Bicep/sqlserverbyoktde.bicep' = if (enableBYOKTDE) {
  name: 'sql-server-tde${deploymentSuffix}'
  dependsOn: [ keyVaultModule, sqldbModule ]
  params: {
    sqlServerName: sqldbModule.outputs.serverName
    keyVaultName: tdeKeyVaultName
    keyName: tdeKeyName
    keyUri: tdeKeyUri
    keyVersion: tdeKeyVersion
  }
}
// </if enableBYOKTDE> --------------------------------------------------------------------------------
