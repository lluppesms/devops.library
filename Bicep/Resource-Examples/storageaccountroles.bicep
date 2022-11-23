// --------------------------------------------------------------------------------
// Logic Apps - RBAC Contributor Access to Integration Storage Account
// --------------------------------------------------------------------------------
param logicAppServiceName string = 'myLogicAppServiceName'
param logicAppServicePrincipalId string = 'myLogicAppServicePrincipalId'
param storageAccountName string = 'myStorageAccountName'
param blobStorageConnectionName string = 'myBlobStorageConnectionName'
param location string = resourceGroup().location

// --------------------------------------------------------------------------------
var blobStorageContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// --------------------------------------------------------------------------------
resource blobStorageAccountResource 'Microsoft.Storage/storageAccounts@2021-04-01' existing = { 
  name: storageAccountName 
}

resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  scope: blobStorageAccountResource
  name: guid('${logicAppServiceName}-${blobStorageContributorRoleId}-ra')
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobStorageContributorRoleId)
    principalId: logicAppServicePrincipalId
  }
}

resource connectionAccessPolicy 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  name: '${blobStorageConnectionName}/${logicAppServiceName}'
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: subscription().tenantId
        objectId: logicAppServicePrincipalId
      }
    }
  }
}
