# Set up GitHub Secrets

The GitHub workflows in this project require several secrets set at the repository level.

---

## Azure Resource Creation Credentials

You need to set up the Azure Credentials secret in the GitHub Secrets at the Repository level before you do anything else.

See https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions for more info.

It should look something like this:

AZURE_CREDENTIALS:

``` bash
{
  "clientId": "<GUID>", 
  "clientSecret": "<GUID>", 
  "subscriptionId": "<GUID>", 
  "tenantId": "<GUID>"
}
```

---

## Bicep Configuration Values

These variables and secrets are used by the Bicep templates to configure the resource names that are deployed.  Make sure the App_Name variable is unique to your deploy. It will be used as the basis for the website name and for all the other Azure resources, which must be globally unique.
To create these additional secrets and variables, customize and run this command:

Required Values:

``` bash
gh auth login

gh variable set APP_NAME -b 'xxx-dadabase'
gh variable set AZURE_LOCATION -b 'eastus'
gh variable set RESOURCE_GROUP_PREFIX -b 'rg_dadabase'
gh variable set RESOURCE_GROUP_NETWORK -b 'rg_network'

gh variable set WEBSITE_SKU -b 'B1'
gh variable set STORAGE_SKU -b 'Standard_LRS'

gh variable set AZURE_SUBSCRIPTION_ID -b '<yourAzureSubscriptionId>'
gh variable set AZURE_SUBSCRIPTION_NAME -b '<yourAzureSubscriptionName>'
gh variable set SERVICE_CONNECTION_NAME -b '<yourServiceConnection>'
gh variable set KEYVAULT_OWNER_USERID -b '<owner1SID>'

gh variable set AZURE_AD_DOMAIN -b '<yourDomain.onmicrosoft.com>'
gh variable set AZURE_AD_CLIENTID -b '<yourClientId>'
gh variable set AZURE_AD_TENANTID -b '<yourTenantId>'
```

---

## References

[Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)

[GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)
