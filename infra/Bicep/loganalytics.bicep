// --------------------------------------------------------------------------------
// Creates a Log Analytics Workspace
// --------------------------------------------------------------------------------
param name string = 'myLogAnalyticsWorkspaceName'
param location string = resourceGroup().location
param commonTags object = {}

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~logAnalytics.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource logWorkspaceResource 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    //you can limit the maximum daily ingestion on the Workspace by providing a value for dailyQuotaGb. 
    // Note: Bicep expects an integer, however in order to set the minimum possible value of 0.023 GB
    // you need to pass it as a string which will work just fine.
    workspaceCapping: {
      dailyQuotaGb: '0.023'
    }
  }
}

// --------------------------------------------------------------------------------
output name string = logWorkspaceResource.name
output id string = logWorkspaceResource.id
