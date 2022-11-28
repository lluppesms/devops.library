// ----------------------------------------------------------------------------------------------------
// This BICEP file will create a Resource Group
// ----------------------------------------------------------------------------------------------------
param appPrefix string = 'app'
@allowed([ 'dev', 'qa', 'stg', 'prod' ])
param environmentCode string = 'dev'
param location string = ''
param runDateTime string = utcNow()
param templateFileName string = '~resourceGroup.bicep'

// ----------------------------------------------------------------------------------------------------
var resourceGroupName = '$rg-${appPrefix}-${environmentCode}'

// ----------------------------------------------------------------------------------------------------
// set the target scope to subscription for this file
targetScope = 'subscription'

// ----------------------------------------------------------------------------------------------------
resource resourceGroupResource 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    Application: appPrefix
    Environment: environmentCode
  }
  properties: {}
}

output resourceGroupName string = resourceGroupResource.name
output resourceGroupLocation string = resourceGroupResource.location
