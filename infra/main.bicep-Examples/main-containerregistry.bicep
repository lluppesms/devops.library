// ------------------------------------------------------------------------------------------------------------------------
// Main Bicep File for Azure Container App Project
// ------------------------------------------------------------------------------------------------------------------------
param orgName string = ''
param envName string = 'DEMO'

param runDateTime string = utcNow()
param location string = resourceGroup().location

// ------------------------------------------------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {         
  LastDeployed: runDateTime
  Organization: orgName
  Environment: envName
}

// --------------------------------------------------------------------------------
module resourceNames 'resourceNames.bicep' = {
  name: 'resourceNames${deploymentSuffix}'
  params: {
    orgName: orgName
    environmentName: toLower(envName)
  }
}

// ------------------------------------------------------------------------------------------------------------------------
module containerRegistryModule 'containerRegistry.bicep' = {
  name: 'containerRegistry${deploymentSuffix}'
  params: {
    containerRegistryName: resourceNames.outputs.containerRegistryName
    location: location
    skuName: 'Premium'
    commonTags: commonTags
  }
}
