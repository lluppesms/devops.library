// --------------------------------------------------------------------------------
// This BICEP file will add rights to KeyVault secrets/keys/certs
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
// this string parm is nice for testing so you can pass in a string instead of an array...
@description('One identity that should needs key vault access')
param onePrincipalId string = ''
@description('If true, will grant full admin rights to the one user to the key vault')
param onePrincipalAdminRights bool = false
@description('If true, will grant rights to the one user to get and unwrap certificates in the key vault')
param onePrincipalCertificateRights bool = false
@description('Array of identities that need key vault access')
param manyPrincipalIds array = []
@description('If true, will grant full admin rights to the many users to the key vault')
param manyPrincipalsAdminRights bool = false
@description('If true, will grant rights to the many users to get and unwrap certificates in the key vault')
param manyPrincipalsCertificateRights bool = false

// --------------------------------------------------------------------------------
var subTenantId = subscription().tenantId

// Note: Azure SQL needs permissions for TDE with Customer Managed Keys  -> keys: [ 'get', 'wrapKey', 'unwrapKey' ]
var readOnlyPermissionArray = {
  secrets: [ 'get', 'list' ]
}
var readAndCertPermissionArray = {
  secrets: [ 'get', 'list' ]
  keys: [ 'get', 'wrapKey', 'unwrapKey' ]
}
var adminPermissionArray = {
  certificates: [ 'all' ]
  secrets: [ 'all' ]
  keys: [ 'all' ]
}

var permissionsToApplyForOneUser = onePrincipalAdminRights ? adminPermissionArray : onePrincipalCertificateRights ? readAndCertPermissionArray : readOnlyPermissionArray
var singleUserPolicy = (onePrincipalId == '') ? [] : [{
  objectId: onePrincipalId
  tenantId: subTenantId
  permissions: permissionsToApplyForOneUser
}]

var permissionsToApplyForManyUsers = manyPrincipalsAdminRights ? adminPermissionArray : manyPrincipalsCertificateRights ? readAndCertPermissionArray : readOnlyPermissionArray
var multipleUserPolicies = [ for principalId in manyPrincipalIds: {
  objectId: principalId
  tenantId: subTenantId
  permissions: permissionsToApplyForManyUsers
}]
var accessPolicies = union(singleUserPolicy, multipleUserPolicies)

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}
resource keyVaultAccessPolicyResource 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' =  {
  name: 'add'
  parent: keyVaultResource
  properties: {
    accessPolicies: accessPolicies
  }
}
