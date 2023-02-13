param containerRegistryName string = ''
param location string = resourceGroup().location
@allowed([ 'Basic', 'Standard', 'Premium'])
param skuName string = 'Basic'
param enableSystemAssignedManagedIdentity bool = true
param enableAdminUser bool = false
param enableDataEndpoint bool = false
param allowAnonymousPull bool = false

resource registry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
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

output containerRegistryName string = registry.name
output containerRegistryResourceId string = registry.id
output containerRegistryManagedIdentityPrincipalId string = enableSystemAssignedManagedIdentity ? registry.identity.principalId : ''
