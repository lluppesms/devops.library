// --------------------------------------------------------------------------------
// This BICEP file will add KeyVault secrets rights to a container app if it exists
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param containerAppName string = 'mycontainerappname'

// --------------------------------------------------------------------------------
resource containerAppResource 'Microsoft.App/containerApps@2022-03-01' existing = {
  name: containerAppName
}
var principalId = containerAppResource.identity.principalId

var singleUserPolicy = [{
  objectId: principalId
  tenantId: subscription().tenantId
  permissions: {
    secrets: [ 'get', 'list' ]
  }
}]

resource keyVaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicyResource 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' =  {
  name: 'add'
  parent: keyVaultResource
  properties: {
    accessPolicies: singleUserPolicy
  }
}

output principalId string = principalId
