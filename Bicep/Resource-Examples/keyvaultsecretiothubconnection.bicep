// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for an IoT Hub Connection
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param keyName string = 'mykeyname'
param iotHubName string = 'myiothubname'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')

// --------------------------------------------------------------------------------
resource iotHubResource 'Microsoft.Devices/IotHubs@2021-07-02' existing = { name: iotHubName }
var iotHubConnectionString = 'HostName=${iotHubResource.name}.azure-devices.net;SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iotHubResource.id, iotHubResource.apiVersion).value[0].primaryKey}'

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName
  resource iotHubSecret 'secrets' = {
    name: keyName
    properties: {
      value: iotHubConnectionString
      attributes: {
        exp: dateTimeToEpoch(expirationDate)
        nbf: dateTimeToEpoch(enabledDate)
      }
    }
  }
}
