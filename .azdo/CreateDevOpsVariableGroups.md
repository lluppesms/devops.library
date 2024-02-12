# Create Azure DevOps Variable Groups

To create variable groups to be used in Azure DevOps pipelines, customize and run this command in the Azure Cloud Shell, adding in the variables and values that you need for your project.

``` bash
   az login

   az pipelines variable-group create 
     --organization=https://dev.azure.com/<yourAzDOOrg>/ 
     --project='<yourAzDOProject>' 
     --name <yourVariableGroupName>
     --variables 
         appName='yourAppName' 
         environmentCode='dev' 
         serviceConnectionName='<yourServiceConnection>' 
         azureSubscription='<yourAzureSubscriptionName>' 
         subscriptionId='<yourSubscriptionId>' 
         location='eastus' 
         yourVariableName='yourVariableValue'
```
