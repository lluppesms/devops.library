// --------------------------------------------------------------------------------
// Creates a Log Analytics Workspace
// --------------------------------------------------------------------------------
param lowerAppPrefix string = ''
param longAppName string = ''
param environment string = ''
param location string = resourceGroup().location
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var workspaceName = '${lowerAppPrefix}-${longAppName}-${environment}'
var templateFileName = 'log-analytics.bicep'

// --------------------------------------------------------------------------------
resource logWorkspaceResource 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  tags: {
    LastDeployed: runDateTime
    TemplateFile: templateFileName
    AppPrefix: lowerAppPrefix
    AppName: longAppName
    Environment: environment
  }
  properties: {
    sku: {
        name: 'PerGB2018' // Standard
    }
  }
}

// --------------------------------------------------------------------------------
output id string = logWorkspaceResource.id
