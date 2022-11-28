// ----------------------------------------------------------------------------------------------------
// This BICEP file is the main entry point for the azd command
// ----------------------------------------------------------------------------------------------------
param name string
param location string
param principalId string = ''
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
targetScope = 'subscription'

// --------------------------------------------------------------------------------
var tags = {
    Application: name
    LastDeployed: runDateTime
}
var deploymentSuffix = '-${runDateTime}'

// --------------------------------------------------------------------------------
resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
    name: 'rg-${name}'
    location: location
    tags: tags
}
module resources './Bicep/main.bicep' = {
    name: 'resources-${deploymentSuffix}'
    scope: resourceGroup
    params: {
        location: location
        appName: name
        keyVaultOwnerUserId: principalId
        environmentCode: 'azd'
    }
}
