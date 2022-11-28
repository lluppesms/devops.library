// --------------------------------------------------------------------------------
// Creates a Log Analytics Workspace
// --------------------------------------------------------------------------------
param logAnalyticsWorkspaceName string = 'myLogAnalyticsWorkspaceName'
param location string = resourceGroup().location
param commonTags object = {}

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~log-analytics.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource logWorkspaceResource 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
        name: 'PerGB2018' // Standard
    }
  }
}

// --------------------------------------------------------------------------------
output id string = logWorkspaceResource.id
output name string = logWorkspaceResource.name
