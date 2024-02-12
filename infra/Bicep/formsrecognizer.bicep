// ----------------------------------------------------------------------------------------------------
// This BICEP file will create a Forms Recognizer Resource
// FYI: To purge a Forms Recognizer resource with soft delete enabled:
//   az resource delete --ids /subscriptions/{subscriptionId}/providers/Microsoft.CognitiveServices/locations/{location}/resourceGroups/{resourceGroup}/deletedAccounts/{resourceName}
// ----------------------------------------------------------------------------------------------------
param formsRecognizerName string = 'xxx-forms-recognizer-${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
@allowed(['S0','F0'])
param sku string = 'S0'
param commonTags object = {}

@allowed(['Enabled','Disabled'])
param publicNetworkAccess string = 'Enabled'
@allowed(['Allow','Deny'])
param allowNetworkAccess string = 'Allow'
@description('The IP Addresses that are allowed access to this storage account.')
param ipRules array = []

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~formsrecognizer.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource formsRecognizerResource 'Microsoft.CognitiveServices/accounts@2022-10-01' = {
  name: formsRecognizerName
  location: location
  sku: {
    name: sku
  }
  kind: 'FormRecognizer'
  tags: tags
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    // restore: true
    customSubDomainName: toLower(formsRecognizerName)
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

output id string = formsRecognizerResource.id
output name string = formsRecognizerResource.name
output location string = formsRecognizerResource.location 
