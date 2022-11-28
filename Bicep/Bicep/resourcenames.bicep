param orgPrefix string = 'org'
param appPrefix string = 'app'
@allowed(['dev','demo','qa','stg','prod'])
param environment string = 'dev'
param appSuffix string = ''
param webAppName string = 'dashboard'
param functionName string = 'func'
param functionStorageNameSuffix string = 'store'
param iotStorageNameSuffix string = 'hub'
param dataStorageNameSuffix string = 'data'

// --------------------------------------------------------------------------------
var  sanitizedOrgPrefix = replace(replace(replace(toLower(orgPrefix), ' ', ''), '-', ''), '_', '')
var  sanitizedAppPrefix = replace(replace(replace(toLower(appPrefix), ' ', ''), '-', ''), '_', '')
var  sanitizedAppSuffix = replace(replace(replace(toLower(appSuffix), ' ', ''), '-', ''), '_', '')
var  sanitizedEnvironment = toLower(environment)

// --------------------------------------------------------------------------------
var functionAppName =                      toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-${functionName}-${sanitizedEnvironment}${sanitizedAppSuffix}')
output functionAppName string =            functionAppName
output functionAppServicePlanName string = '${functionAppName}-appsvc'
output functionInsightsName string =       '${functionAppName}-insights'

var webSiteName =                          toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-${webAppName}-${sanitizedEnvironment}${sanitizedAppSuffix}')
output webSiteName string =                webSiteName
output webSiteAppServicePlanName string =  '${webSiteName}-appsvc'
output webSiteAppInsightsName string =     '${webSiteName}-insights'

output cosmosAccountName string =          toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-cosmos-${sanitizedEnvironment}${sanitizedAppSuffix}')
output serviceBusName string =             toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-svcbus-${sanitizedEnvironment}${sanitizedAppSuffix}')

output logicAppServiceName string =                     '${sanitizedOrgPrefix}-${sanitizedAppPrefix}-${sanitizedEnvironment}'
output logAnalyticsWorkspaceName string =               '${sanitizedOrgPrefix}-${sanitizedAppPrefix}-logs-${sanitizedEnvironment}'
output blobStorageConnectionName string =               '${sanitizedOrgPrefix}-${sanitizedAppPrefix}blob${sanitizedEnvironment}-blobconnection'

output iotHubName string =                 toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-hub-${sanitizedEnvironment}${sanitizedAppSuffix}')
output dpsName string =                    toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-dps-${sanitizedEnvironment}${sanitizedAppSuffix}')
output signalRName string =                toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-signal-${sanitizedEnvironment}${sanitizedAppSuffix}')
output saJobName string =                  toLower('${sanitizedOrgPrefix}-${sanitizedAppPrefix}-stream-${sanitizedEnvironment}${sanitizedAppSuffix}')

// Key Vaults and Storage Accounts can only be 24 characters long
output keyVaultName string =               take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}vault${sanitizedEnvironment}${sanitizedAppSuffix}'), 24)
output functionStorageName string =        take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}${sanitizedEnvironment}${appSuffix}${functionStorageNameSuffix}'), 24)
output iotStorageAccountName string =      take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}${sanitizedEnvironment}${appSuffix}${iotStorageNameSuffix}'), 24)
output logicAppStorageAccountName string = take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}app${sanitizedEnvironment}'), 24)
output dataStorageName string =            take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}${sanitizedEnvironment}${appSuffix}${dataStorageNameSuffix}'), 24)
output blobStorageAccountName string =     take(toLower('${sanitizedOrgPrefix}${sanitizedAppPrefix}blob${sanitizedEnvironment}'), 24)
