// ----------------------------------------------------------------------------------------------------
// I would love to use main.bicepparam file format instead of main.parameters.json, 
// but the AzureResourceManagerTemplateDeployment@3 task does not support it yet... :(
//   See https://github.com/microsoft/azure-pipelines-tasks/issues/18521
//   The issue is in code review on Feb 9, 2024, so it should be coming soon...
// ----------------------------------------------------------------------------------------------------

using './main.bicep'

param appName = '#{appName}#'
param environmentCode = '#{environmentNameLower}#'
param location = '#{location}#'
param storageSku = '#{storageSku}#'
param functionAppSku = '#{functionAppSku}#'
param functionAppSkuFamily = '#{functionAppSkuFamily}#'
param functionAppSkuTier = '#{functionAppSkuTier}#'
param keyVaultOwnerUserId = '#{keyVaultOwnerUserId}#'
param twilioAccountSid = '#{twilioAccountSid}#'
param twilioAuthToken = '#{twilioAuthToken}#'
param twilioPhoneNumber = '#{twilioPhoneNumber}#'
param runDateTime = '#{runDateTime}#'
