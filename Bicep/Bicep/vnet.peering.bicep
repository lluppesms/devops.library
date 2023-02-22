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

@description('Optional. If set to true, the peering from Remote (e.g Hub) to Local (e.g Spoke) is also created. Default is true')
param createPairedPeer bool = true

@description('Optional. Specify the types of locks (CanNotDelete, ReadOnly).')
param locks array = [
  'CanNotDelete'
  'ReadOnly'
]


module localVnetPeering 'vnet.peering.single.bicep' = {
  name: 'localVnetPeering'
  params: {
    localVnetId: localVnetId
    remoteVnetId: remoteVnetId
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    doNotVerifyRemoteGateways: doNotVerifyRemoteGateways
    locks: locks
  }
}

var remoteVnetArr = split(remoteVnetId, '/')
@description('Peering from Remote (e.g. Hub) to Local (e.g. Spoke). Note: gateway settings are opposite for Hub-to-Spoke vs. Spoke-to-Hub Peering.')
module remoteVnetPeering 'vnet.peering.single.bicep' = if(createPairedPeer) {
  name: 'remoteVnetPeering'
  // Set scope for paired peer to the Remove VNet Subscription and Resource Group
  scope: resourceGroup(remoteVnetArr[2], remoteVnetArr[4])
  params: {
    localVnetId: remoteVnetId
    remoteVnetId: localVnetId
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: useRemoteGateways
    useRemoteGateways: allowGatewayTransit
    doNotVerifyRemoteGateways: doNotVerifyRemoteGateways
    locks: locks
  }
}

@description('The resource group the virtual network peering was deployed into')
output virtualNetworkPeeringResourceGroup string = resourceGroup().name
@description('The name of the virtual network peering')
output virtualNetworkPeeringName string = localVnetPeering.outputs.virtualNetworkPeeringName
@description('The resourceId of the virtual network peering')
output virtualNetworkPeeringResourceId string = localVnetPeering.outputs.virtualNetworkPeeringResourceId

@description('The resource group the Hub virtual network peering was deployed into')
output HubVirtualNetworkPeeringResourceGroup string = createPairedPeer ? remoteVnetPeering.outputs.virtualNetworkPeeringResourceGroup : ''
@description('The name of the Hub virtual network peering')
output hubVirtualNetworkPeeringName string = createPairedPeer ? remoteVnetPeering.outputs.virtualNetworkPeeringName : ''
@description('The resourceId of the Hub virtual network peering')
output hubVirtualNetworkPeeringResourceId string = createPairedPeer ? remoteVnetPeering.outputs.virtualNetworkPeeringResourceId : ''
