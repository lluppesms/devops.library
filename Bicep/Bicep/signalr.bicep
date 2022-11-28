// --------------------------------------------------------------------------------
// This BICEP file will create a SignalR host
// --------------------------------------------------------------------------------
param signalRName string = 'mysignalrname'
param location string = resourceGroup().location
param commonTags object = {}

param sku string = 'Free_F1'	 // Required, the name of the SKU. Allowed values: Standard_S1, Free_F1
param skuTier	string = 'Free'  // Optional tier of this particular SKU. 'Standard' or 'Free' or 'Premium'
//param skuCapacity int = 1    // Optional, integer. The unit count of the resource. 1 by default. Allowed: Free: 1; Standard: 1,2,5,10,20,50,100

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~signalr.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource signalRResource 'Microsoft.SignalRService/SignalR@2022-02-01' = {
  name: signalRName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: skuTier
    capacity: 1
  }
  kind: 'SignalR'
  properties: {
    tls: {
      clientCertEnabled: false
    }
    features: [
      {
        flag: 'ServiceMode'
        value: 'Default'
        properties: {
        }
      }
      {
        flag: 'EnableConnectivityLogs'
        value: 'True'
        properties: {
        }
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
    upstream: {
    }
    networkACLs: {
      defaultAction: 'Deny'
      publicNetwork: {
        allow: [
          'ServerConnection'
          'ClientConnection'
          'RESTAPI'
          'Trace'
        ]
      }
      privateEndpoints: []
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    disableAadAuth: false
  }
}

// --------------------------------------------------------------------------------
output name string = signalRResource.name
output id string = signalRResource.id
output apiVersion string = signalRResource.apiVersion
