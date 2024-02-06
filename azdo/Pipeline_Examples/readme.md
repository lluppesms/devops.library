# Azure DevOps Deployment Template Notes

## 1. Azure DevOps Template Definitions

Typically, you would want to set up either the first option or the second and third option, but not all three jobs.

- **infra-and-function-pipeline.yml:** Deploys the main.bicep template, builds the function app, then deploys the function app to the Azure Function
- **infra-only-pipeline.yml:** Deploys the main.bicep template and does nothing else
- **function-only-pipeline.yml:** Builds the function app and then deploys the function app to the Azure Function
- **deploy-only-pipeline.yml:** Deploys a PREVIOUSLY BUILT function app to the Azure Function

---

## 2. Deploy Environments

These Azure DevOps YML files were designed to run as multi-stage environment deploys (i.e. DEV/QA/PROD). Each Azure DevOps environments can have permissions and approvals defined. For example, DEV can be published upon change, and QA/PROD environments can require an approval before any changes are made.

---

## 3. Setup Steps

- [Create Azure DevOps Service Connections](https://docs.luppes.com/CreateServiceConnections/)

- [Create Azure DevOps Environments](https://docs.luppes.com/CreateDevOpsEnvironments/)

- Create Azure DevOps Variable Groups - see next step in this document (the variables are unique to this project)

- [Create Azure DevOps Pipeline(s)](https://docs.luppes.com/CreateNewPipeline/)

- [Deploy the Azure Resources and Application](./Docs/DeployApplication.md)

---

## 4. Creating the variable group "Dadabase.Function.Keys"

To create this variable groups, customize and run this command in the Azure Cloud Shell.

Alternatively, you could define these variables in the Azure DevOps Portal on each pipeline, but a variable group is a more repeatable and scriptable way to do it.

``` bash
   az login

   az pipelines variable-group create 
     --organization=https://dev.azure.com/<yourAzDOOrg>/ 
     --project='<yourAzDOProject>' 
     --name Dadabase.Function.Keys 
     --variables 
         appName='<yourInitials>-net8-func' 
         serviceConnectionName='<yourServiceConnection>' 
```

## 5. Update the vars\var-common.yml File with your settings

To customize this deploy for your liking, edit the var-common.yml file in the vars folder. This file contains the following variables.

``` bash
resourceGroupPrefix='rg_func_net8'
applicationTitle='Net8 Isolated Function Demo'
location='eastus' 
storageSku='Standard_LRS' 
functionAppSku='Y1' 
functionAppSkuFamily='Y' 
functionAppSkuTier='Dynamic' 
functionKind='functionapp,linux'
storageSku='Standard_LRS'
```

This file also contains some hard-coded things that are specific to this project, like the location of the project folder and solution name, which are used in the build steps. If you change the source location or project names, simply update this one file and the builds should continue to work.

``` bash
appFolderName='src/DadABase.Function'
appSolutionName='DadaBase.Function.Net8'
appProjectFolderName='src/DadABase.Function'
appProjectExtension='csproj'
workingDirectoryInfra='/infra/bicep'
workingDirectoryIgnore='/Docs'
```

---
<!-- 
## 6. Running the Application

[How to run the application](../Docs/RunApplication.md)

--- 

[Reference: Using Azurite Local Storage](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?toc=%2Fazure%2Fstorage%2Fblobs%2Ftoc.json&tabs=visual-studio) -->
