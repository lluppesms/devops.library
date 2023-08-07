// --------------------------------------------------------------------------------
// This BICEP file will add rights for an application to read KeyVault secrets
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
@description('Application Managed Identity that needs to read key vault secrets')
param applicationPrincipalId string = ''
@description('Tenant for Application Managed Identity')
param applicationTenantId string = ''

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}
resource keyVaultAccessPolicyResource 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyVaultResource
  properties: {
    accessPolicies: [
      {
        permissions: {
          secrets: ['get','list']
        }
        tenantId: applicationTenantId
        objectId: applicationPrincipalId
      }
    ]
  }
}
