// --------------------------------------------------------------------------------
// This BICEP file will create a KeyVault
// FYI: To purge a KV with soft delete enabled: > az keyvault purge --name kvName
// --------------------------------------------------------------------------------
// Remaining Cloud Defender Issue: Medium - Private endpoint should be configured for Key Vault
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param location string = resourceGroup().location
param commonTags object = {}

@description('Administrators that should have access to administer key vault')
param adminUserObjectIds array = []
@description('Application that should have access to read key vault secrets')
param applicationUserObjectIds array = []

@description('Administrator UserId that should have access to administer key vault')
param keyVaultOwnerUserId string = ''
@description('Ip Address of the KV owner so they can read the vault, such as 254.254.254.254/32')
param keyVaultOwnerIpAddress string = ''

@description('Determines if Azure can deploy certificates from this Key Vault.')
param enabledForDeployment bool = true
@description('Determines if templates can reference secrets from this Key Vault.')
param enabledForTemplateDeployment bool = true
@description('Determines if this Key Vault can be used for Azure Disk Encryption.')
param enabledForDiskEncryption bool = true
@description('Determine if soft delete is enabled on this Key Vault.')
param enableSoftDelete bool = false
@description('Determine if purge protection is enabled on this Key Vault.')
param enablePurgeProtection bool = true
@description('The number of days to retain soft deleted vaults and vault objects.')
param softDeleteRetentionInDays int = 7
@description('Determines if access to the objects granted using RBAC. When true, access policies are ignored.')
param useRBAC bool = false

@allowed(['Enabled','Disabled'])
param publicNetworkAccess string = 'Enabled'
@allowed(['Allow','Deny'])
param allowNetworkAccess string = 'Allow'

// @description('The workspace to store audit logs.')
// @metadata({
//   strongType: 'Microsoft.OperationalInsights/workspaces'
//   example: '/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.OperationalInsights/workspaces/<workspace_name>'
// })
// param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~keyVault.bicep' }
var tags = union(commonTags, templateTag)

var ownerAccessPolicy = keyVaultOwnerUserId == '' ? [] : [
  {
    objectId: keyVaultOwnerUserId
    tenantId: subscription().tenantId
    permissions: {
      certificates: [ 'all' ]
      secrets: [ 'all' ]
      keys: [ 'all' ]
    }
  } 
]
var adminAccessPolicies = [for adminUser in adminUserObjectIds: {
  objectId: adminUser
  tenantId: subscription().tenantId
  permissions: {
    certificates: [ 'all' ]
    secrets: [ 'all' ]
    keys: [ 'all' ]
  }
}]
var applicationUserPolicies = [for appUser in applicationUserObjectIds: {
  objectId: appUser
  tenantId: subscription().tenantId
  permissions: {
    secrets: [ 'get' ]
    keys: [ 'get', 'wrapKey', 'unwrapKey' ] // Azure SQL uses these permissions to access TDE key
  }
}]
var accessPolicies = union(ownerAccessPolicy, adminAccessPolicies, applicationUserPolicies)

var kvIpRules = keyVaultOwnerIpAddress == '' ? [] : [
  {
    value: keyVaultOwnerIpAddress
  }
] 

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId

    // Use Access Policies model
    enableRbacAuthorization: useRBAC      
    // add function app and web app identities in the access policies so they can read the secrets
    accessPolicies: accessPolicies

    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment

    enablePurgeProtection: enablePurgeProtection // Not allowing to purge key vault or its objects after deletion
    enableSoftDelete: enableSoftDelete
    createMode: 'default'               // Creating or updating the key vault (not recovering)

    softDeleteRetentionInDays: softDeleteRetentionInDays
    publicNetworkAccess: publicNetworkAccess   // Allow access from all networks
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: allowNetworkAccess
      ipRules: kvIpRules
      virtualNetworkRules: []
    }
  }
}

// // Configure logging
// resource vaultName_Microsoft_Insights_service 'Microsoft.KeyVault/vaults/providers/diagnosticSettings@2016-09-01' = if (!empty(workspaceId)) {
//   name: '${name}/Microsoft.Insights/service'
//   location: location
//   properties: {
//     workspaceId: workspaceId
//     logs: [
//       {
//         category: 'AuditEvent'
//         enabled: true
//       }
//     ]
//   }
//   dependsOn: [
//     vault
//   ]
// }

output name string = keyvaultResource.name
output id string = keyvaultResource.id
