// --------------------------------------------------------------------------------
// This BICEP file will create a Redis Cache
// --------------------------------------------------------------------------------
param name string
param location string = resourceGroup().location
param commonTags object = {}
param skuFamily string = 'C'
param skuName string = 'Basic'
param skuCapacity int = 1

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~redisCache.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource redisCacheResource 'Microsoft.Cache/redis@2023-04-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      capacity: skuCapacity
      family: skuFamily
      name: skuName
    }
    minimumTlsVersion: '1.2'
  }  
}


// --------------------------------------------------------------------------------
resource redisAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${redisCacheResource.name}-auditlogs'
  scope: redisCacheResource
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'connectedclientlist'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

resource redisMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${redisCacheResource.name}-metrics'
  scope: redisCacheResource
  properties: {
    workspaceId: workspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

// --------------------------------------------------------------------------------
output name string = redisCacheResource.name
