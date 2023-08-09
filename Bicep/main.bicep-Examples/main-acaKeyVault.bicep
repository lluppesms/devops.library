// ----------------------------------------------------------------------------------------------------
// Bicep to re-deploy Key Vault access rights for a list of Container Apps
// ----------------------------------------------------------------------------------------------------
param orgName string = ''
param envName string = 'DEMO'
param serviceName string = ''
param runDateTime string = utcNow()

// ------------------------------------------------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'

// --------------------------------------------------------------------------------
module resourceNames 'resourceNames.bicep' = {
  name: 'resourceNames${deploymentSuffix}'
  params: {
    orgName: orgName
    environmentName: toLower(envName)
  }
}

module keyVaultAppRightsModule 'keyvaultcontainerapprights.bicep' = {
  name: '${serviceName}-keyVault${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    containerAppName: serviceName
  }
}
