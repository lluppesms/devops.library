// ----------------------------------------------------------------------------------------------------
// This BICEP file will create a Computer Vision Resource
// FYI: To purge a Computer Vision resource with soft delete enabled:
//   az resource delete --ids /subscriptions/{subscriptionId}/providers/Microsoft.CognitiveServices/locations/{location}/resourceGroups/{resourceGroup}/deletedAccounts/{resourceName}
// ----------------------------------------------------------------------------------------------------
param computerVisionName string = 'xxx-computer-vision-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
@allowed(['S1','F0'])
param sku string = 'S1'
param commonTags object = {}

@allowed(['Enabled','Disabled'])
param publicNetworkAccess string = 'Enabled'
@allowed(['Allow','Deny'])
param allowNetworkAccess string = 'Allow'
@description('The IP Addresses that are allowed access to this storage account.')
param ipRules array = []

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~computervision.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource computerVisionResource 'Microsoft.CognitiveServices/accounts@2022-10-01' = {
  name: computerVisionName
  location: location
  sku: {
    name: sku
  }
  kind: 'ComputerVision'
  tags: tags
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    // restore: true
    customSubDomainName: toLower(computerVisionName)
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: allowNetworkAccess
      ipRules: ((empty(ipRules) || empty(ipRules[0].value)) ? json('[]') : ipRules)
      virtualNetworkRules: []
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output id string = computerVisionResource.id
output name string = computerVisionResource.name
output location string = computerVisionResource.location 
