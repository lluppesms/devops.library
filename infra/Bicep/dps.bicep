// --------------------------------------------------------------------------------
// This BICEP file will create a linked IoT Hub and DPS Service
// --------------------------------------------------------------------------------
// NOTE: there is no way yet to automate DPS Enrollment Group creation.
//   After DPS is created, you will need to manually create a group based on
//   the certificate that is created.
// --------------------------------------------------------------------------------
param dpsName string = 'myDpsName'
param iotHubName string = 'myIoTHubName'
param location string = resourceGroup().location
param commonTags object = {}

@allowed(['F1','S1','S2','S3'])
param sku string = 'S1'

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~dps.bicep' }
var tags = union(commonTags, templateTag)

// --------------------------------------------------------------------------------
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotKey = iotHubResource.listKeys().value[0].primaryKey
var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${iotKey}'

// --------------------------------------------------------------------------------
// create a Device Provisioning Service and link it to the IoT Hub
resource dpsResource 'Microsoft.Devices/provisioningServices@2022-02-05' = {
  name: dpsName
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: 1
  }
  properties: {
    state: 'Active'
    provisioningState: 'Succeeded'
    iotHubs: [
      {
        connectionString: iotHubConnectionString
        location: location
      }
    ]
    allocationPolicy: 'Hashed'
    enableDataResidency: false
  }
}

// // NOTE: this certificate data is just the base-64 contents of simple self-signed X509 .pem file
// // WARNING: This works find the first time. Since this is auto-magically set to verified, the SECOND
// //          time you run this, it will fail with an ETAG mismatch.
// resource dpsGroupCertificate 'Microsoft.Devices/provisioningServices/certificates@2022-02-05' = {
//   name: certName
//   parent: dpsResource
//   properties: {
//     certificate: 'MIICDjCCAXcCFGr1kIjSec...base64stuff...='
//     isVerified: true
//   }
// }

// NOTE: as of Jan 2021: creating enrollment groups via ARM templates it is not yet available. 
// This is a known and understood request - no committed timeframe for this yet.
// See github.com/MicrosoftDocs/azure-docs/issues/56161
// Need to automate running a script like this...: 
//   az iot dps enrollment-group create -g {resourceGroupName} --dps-name {dps_name} --enrollment-id {enrollment_id} --certificate-path /certificates/{CertificateName}.pem

// See: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep
// resource runPowerShellInline 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'runPowerShellInline'
//   location: location
//   kind: 'AzurePowerShell'
//   // identity: {
//   //   type: 'UserAssigned'
//   //   userAssignedIdentities: {
//   //     '/subscriptions/01234567-89AB-CDEF-0123-456789ABCDEF/resourceGroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID': {}
//   //   }
//   // }
//   properties: {
//     azPowerShellVersion: '6.4' // or azCliVersion: '2.28.0'
//     // forceUpdateTag: '1'
//     // containerSettings: {
//     //   containerGroupName: 'mycustomaci'
//     // }
//     // storageAccountSettings: {
//     //   storageAccountName: 'myStorageAccount'
//     //   storageAccountKey: 'myKey'
//     // }
//     // arguments: '-name \\"John Dole\\"'
//     // environmentVariables: [
//     //   {
//     //     name: 'UserName'
//     //     value: 'jdole'
//     //   }
//     //   {
//     //     name: 'Password'
//     //     secureValue: 'jDolePassword'
//     //   }
//     // ]
//     scriptContent: '''
//       param([string] $name)
//       az iot dps enrollment-group create -g ${Env:resourceGroupName} --dps-name ${Env:dps_name} --enrollment-id ${Env:enrollment_id} --certificate-path /certificates/${Env:CertificateName}.pem
//     '''
//     supportingScriptUris: []
//     timeout: 'PT30M'
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//   }
// }

// --------------------------------------------------------------------------------
resource dpsAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dpsResource.name}-auditlogs'
  scope: dpsResource
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'DeviceOperations'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
      {
        category: 'ServiceOperations'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true 
        }
      }
    ]
  }
}

resource dpsMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dpsResource.name}-metrics'
  scope: dpsResource
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
output id string = dpsResource.id
output name string = dpsResource.name
