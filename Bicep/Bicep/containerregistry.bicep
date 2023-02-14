// ----------------------------------------------------------------------------------------------------
// This BICEP file will create an Azure Container Registry
// ----------------------------------------------------------------------------------------------------
param containerRegistryName string = 'bcr${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
@allowed([ 'Basic', 'Standard', 'Premium'])
param skuName string = 'Premium'
param enableSystemAssignedManagedIdentity bool = true
param enableAdminUser bool = false
param enableDataEndpoint bool = false
param allowAnonymousPull bool = false
param commonTags object = {}

// ----------------------------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~container-registry.bicep' }
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
    dataEndpointEnabled: enableDataEndpoint
  }
  identity: {
   type: enableSystemAssignedManagedIdentity ? 'SystemAssigned' : 'None'
  }
}

// ----------------------------------------------------------------------------------------------------
output containerRegistryName string = registry.name
output containerRegistryResourceId string = registry.id
output containerRegistryManagedIdentityPrincipalId string = enableSystemAssignedManagedIdentity ? registry.identity.principalId : ''
