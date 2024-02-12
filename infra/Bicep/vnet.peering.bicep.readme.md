# VirtualNetworkPeering  `[Microsoft.Network/virtualNetworks/virtualNetworkPeerings]`

This template deploys Virtual Network Peering.

## Resource types

| Resource Type | Api Version |
| :-- | :-- |
| `Microsoft.Network/virtualNetworks/virtualNetworkPeerings` | 2021-02-01 |

### Resource dependency

The following resources are required to be able to deploy this resource.

- Local Virtual Network (Identified by the `localVnetId` parameter).
- Remote Virtual Network (Identified by the `remoteVnetId` parameter)

## Parameters

| Parameter Name | Type | Default Value | Possible Values | Description |
| :-- | :-- | :-- | :-- | :-- |
| `allowForwardedTraffic` | bool | `True` |  | Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network. Default is true |
| `allowGatewayTransit` | bool |  |  | Optional. If gateway links can be used in remote virtual networking to link to this virtual network. Default is false |
| `allowVirtualNetworkAccess` | bool | `True` |  | Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space. Default is true |
| `cuaId` | string |  |  | Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered |
| `doNotVerifyRemoteGateways` | bool | `True` |  | Optional. If we need to verify the provisioning state of the remote gateway. Default is true |
| `createHubToSpokePeer` | bool | false |  | Optional. If set to true, the peering from Hub (remote) to Spoke (local) is also created. |
| `localVnetId` | string |  |  | Required. The ID of the Virtual Network to add the peering to. |
| `remoteVnetId` | string |  |  | Required. The Resource ID of the VNet that this Local VNet is being peered to. Should be in the format of a Resource ID |
| `useRemoteGateways` | bool |  |  | Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Default is false |

## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `virtualNetworkPeeringName` | string | The name of the virtual network peering |
| `virtualNetworkPeeringResourceGroup` | string | The resource group the virtual network peering was deployed into |
| `virtualNetworkPeeringResourceId` | string | The resourceId of the virtual network peering |

## Template references

- [Virtualnetworks/Virtualnetworkpeerings](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Network/2021-05-01/virtualNetworks/virtualNetworkPeerings)
