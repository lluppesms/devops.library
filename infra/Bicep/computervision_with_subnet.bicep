// ----------------------------------------------------------------------------------------------------
// This BICEP file will create a Computer Vision Resource
// Azure Functions doesn't like this format... has trouble calling the CV APIs...
// ----------------------------------------------------------------------------------------------------
param computerVisionName string = 'xxx-computer-vision-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
@allowed(['S1','F0'])
param sku string = 'S1'
param subnetName string = 'sn1'
param virtualNetworkName string = 'virtualNetwork'
@allowed(['Internal','External'])
param virtualNetworkType string = 'External'
param ipRules array = []
param commonTags object = {}

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~computervision.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource vnetResource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }

    ]
  }
}

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
    //restore: true
    customSubDomainName: toLower(computerVisionName)
    publicNetworkAccess: ((virtualNetworkType == 'Internal') ? 'Disabled' : 'Enabled')
    networkAcls: {
      defaultAction: ((virtualNetworkType == 'External') ? 'Deny' : 'Allow')
      virtualNetworkRules: ((virtualNetworkType == 'External') ? json('[{"id": "${subscription().id}/resourceGroups/${vnetResource}/providers/Microsoft.Network/virtualNetworks/${vnetResource.name}/subnets/${subnetName}"}]') : json('[]'))
      ipRules: ((empty(ipRules) || empty(ipRules[0].value)) ? json('[]') : ipRules)
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    vnetResource
  ]
}

output id string = computerVisionResource.id
output name string = computerVisionResource.name
output location string = computerVisionResource.location 
