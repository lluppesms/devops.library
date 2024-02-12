// ----------------------------------------------------------------------------------------------------
// Bicep to deploy a module from a Container Registry to an Azure Container App
// ----------------------------------------------------------------------------------------------------
param orgName string = ''
param envName string = 'DEMO'
param serviceName string = 'myService'
param serviceTag string = 'latest'
param subFolderName string = 'dapr-hack'
param containerPort int = 6001
param useExternalIngress bool = false
param acrAdminUserName string
@secure()
param acrAdminPassword string

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

// ----------------------------------------------------------------------------------------------------
// you can't deploy these apps until after the container image is built...!
module appDeployModule 'acaApp.bicep' = {
  name: '${serviceName}-deploy-${deploymentSuffix}'
  params: {
    containerAppEnvironmentName: resourceNames.outputs.acaEnvironmentName
    serviceName: serviceName
    serviceTag: serviceTag
    subFolderName: subFolderName
    containerPort: containerPort
    useExternalIngress: useExternalIngress
    location: location
    acrName: resourceNames.outputs.containerRegistryName
    acrAdminUserName: acrAdminUserName
    acrAdminPassword: acrAdminPassword
    commonTags: commonTags
  }
}

module keyVaultAppRightsModule 'keyvaultadminrights.bicep' = {
  name: '${serviceName}-keyVault${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    onePrincipalId: appDeployModule.outputs.principalId
    onePrincipalAdminRights: false
    onePrincipalCertificateRights: false
  }
}
