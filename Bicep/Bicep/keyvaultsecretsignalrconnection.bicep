// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a signalR connection
// --------------------------------------------------------------------------------
param keyVaultName string = 'mykeyvaultname'
param keyName string = 'mykeyname'
param signalRName string = 'mysignalrname'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P10Y')

// --------------------------------------------------------------------------------
resource signalRResource 'Microsoft.SignalRService/SignalR@2022-02-01' existing = { name: signalRName }
var signalRKey = '${listKeys(signalRResource.id, signalRResource.apiVersion).primaryKey}'
var signalRConnectionString = 'Endpoint=https://${signalRName}.service.signalr.net;AccessKey=${signalRKey};Version=1.0;'

// --------------------------------------------------------------------------------
resource keyvaultResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = { 
  name: keyVaultName
  resource signalRSecret 'secrets' = {
    name: keyName
    properties: {
      value: signalRConnectionString
      attributes: {
        exp: dateTimeToEpoch(expirationDate)
        nbf: dateTimeToEpoch(enabledDate)
      }
    }
  }
}
