// ----------------------------------------------------------------------------------------------------
// Bicep to deploy a module from a Container Registry to an Azure Container App
// ----------------------------------------------------------------------------------------------------
param containerAppEnvironmentName string
param serviceName string = 'myService'
param serviceTag string = 'latest'
param subFolderName string = 'dapr-hack'
param containerPort int = 6001
param useExternalIngress bool = false
param location string = resourceGroup().location
param acrName string
param acrAdminUserName string
@secure()
param acrAdminPassword string

// ----------------------------------------------------------------------------------------------------
// ContainerApp name must consist of lower case alphanumeric characters or '-', start with an alphabetic character, 
// and end with an alphanumeric character and cannot have '--'. The length must not be more than 32 characters.
var sanitizedserviceName = take(replace(replace(replace(toLower(serviceName), ' ', ''), '_', ''), '_', ''), 32)
var containerImage = toLower('${acrName}.azurecr.io/${subFolderName}/${sanitizedserviceName}:${serviceTag}')

// ----------------------------------------------------------------------------------------------------
resource containerAppEnvironmentResource 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppEnvironmentName
}

resource containerAppResource 'Microsoft.App/containerApps@2022-03-01' = {
  name: sanitizedserviceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentResource.id
    configuration: {
      secrets: [
        {
          name: 'acrpassword'
          value: acrAdminPassword
        }
      ]
      registries: [
        {
          server: '${acrName}.azurecr.io'
          username: acrAdminUserName
          passwordSecretRef: 'acrpassword'
        }
      ]
      ingress: {
        external: useExternalIngress
        targetPort: containerPort
      }
      dapr: {
        enabled: true
        appPort: containerPort
        appId: sanitizedserviceName
        appProtocol: 'http'
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: sanitizedserviceName
          env: [
            {
              name: 'APPLICATION_VERSION'
              value: serviceTag
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
  }
}

output fqdn string = containerAppResource.properties.configuration.ingress.fqdn
output principalId string = containerAppResource.identity.principalId
output tenantId string = containerAppResource.identity.tenantId
