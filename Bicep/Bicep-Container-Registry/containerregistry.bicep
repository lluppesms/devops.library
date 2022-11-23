// ------------------------------------------------------------------------------------------------------------------------
// Deploy Azure Container Registry for THIS repository
// ------------------------------------------------------------------------------------------------------------------------
// To deploy this Bicep manually:
//   az deployment group create -n main-deploy-20221103T090000Z --resource-group rg_bicep_registry --template-file '.infrastructure/containerregistry.bicep' --parameters registryName=xxxbicepregistry
// --------------------------------------------------------------------------------
param registryName string = ''
param location string = resourceGroup().location
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'

// --------------------------------------------------------------------------------
module registry '../Bicep/containerregistry2.bicep' = {
  name: 'registry-${deploymentSuffix}'
  params: {
    containerRegistryName: registryName
    location: location
    skuName: 'Basic'
  }
}
