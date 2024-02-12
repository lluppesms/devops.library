// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Container Registry
// ----------------------------------------------------------------------------------------------------
param containerRegistryName string = 'acr${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
@allowed([ 'Basic', 'Standard', 'Premium'])
param skuName string = 'Premium'
param enableSystemAssignedManagedIdentity bool = true
param enableAdminUser bool = true
//param enableDataEndpoint bool = false
param allowAnonymousPull bool = false
param enableDiagnostics bool = true
@description('The workspace to store audit logs.')
@metadata({
  strongType: 'Microsoft.OperationalInsights/workspaces'
  example: '/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.OperationalInsights/workspaces/<workspace_name>'
})
param workspaceId string = ''

param commonTags object = {}

// ----------------------------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~containerRegistry.bicep' }
var tags = union(commonTags, templateTag)

// ----------------------------------------------------------------------------------------------------
resource registry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: enableAdminUser
    anonymousPullEnabled: allowAnonymousPull
    //dataEndpointEnabled: enableDataEndpoint
  }
  identity: {
   type: enableSystemAssignedManagedIdentity ? 'SystemAssigned' : 'None'
  }
}

resource diagnostics 'microsoft.insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(workspaceId)) {
  scope: registry
  name: '${registry.name}-metrics'
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
// ----------------------------------------------------------------------------------------------------
output containerRegistryName string = registry.name
output containerRegistryResourceId string = registry.id
output containerRegistryManagedIdentityPrincipalId string = enableSystemAssignedManagedIdentity ? registry.identity.principalId : ''
