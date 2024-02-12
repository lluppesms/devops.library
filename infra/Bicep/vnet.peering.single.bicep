@description('Required. The Resource ID of the Virtual Network to add the peering to. Should be in the format of a Resource ID.')
param localVnetId string

@description('Required. The Resource ID of the VNet that this Local VNet is being peered to. Should be in the format of a Resource ID.')
param remoteVnetId string

@description('Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space. Default is true')
param allowVirtualNetworkAccess bool = true

@description('Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network. Default is true')
param allowForwardedTraffic bool = true

@description('Optional. If gateway links can be used in remote virtual networking to link to this virtual network. Default is false')
param allowGatewayTransit bool = false

@description('Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Default is false')
param useRemoteGateways bool = false

@description('Optional. If we need to verify the provisioning state of the remote gateway. Default is true')
param doNotVerifyRemoteGateways bool = true

@description('Optional. Specify the types of locks (CanNotDelete, ReadOnly).')
param locks array = [
  'CanNotDelete'
  'ReadOnly'
]

var localVnetName = last(split(localVnetId, '/'))
var remoteVnetName = last(split(remoteVnetId, '/'))
var peeringName = '${localVnetName}-TO-${remoteVnetName}'


resource virtualNetworkPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${localVnetName}/${peeringName}'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    doNotVerifyRemoteGateways: doNotVerifyRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}

resource vNetPeering_locks 'Microsoft.Authorization/locks@2017-04-01' = [for lock in locks: {
  name: '${peeringName}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: virtualNetworkPeering
}]

@description('The resource group the virtual network peering was deployed into')
output virtualNetworkPeeringResourceGroup string = resourceGroup().name
@description('The name of the virtual network peering')
output virtualNetworkPeeringName string = virtualNetworkPeering.name
@description('The resourceId of the virtual network peering')
output virtualNetworkPeeringResourceId string = virtualNetworkPeering.id
