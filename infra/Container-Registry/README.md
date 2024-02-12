# Bicep Container Registries

To share Bicep files among development teams, they can be published to a Container Registry.

*For an example on how to publish them, see the ".infrastructure/publish-bicep-modules.yml" file in this project.*

**Note:** File names are case sensitive, so using all lowercase filenames is recommended.

---

## Referencing a Containerized template

Normally, a bicep file is referenced in a YML file using this syntax:

``` bash
module servicebusModule 'Bicep/servicebus.bicep' = { ...
```

To reference a bicep file in a container registry, the syntax changes to:

``` bash
module servicebusModule 'br/<yourRegistryAlias>:servicebus:<tag>' = {
```

Note: The "yourRegistryAlias" in front of the module name is defined in your bicep.config file as defined below.  The 'tag' can be an explicit value or something pre-defined like "LATEST".

---

## bicep.config file

A bicep.config file will need to be added to a project that refers to the registry defining the location of the registry, like this:

``` base
{
    "moduleAliases": {
        "br": {
            "yourRegistryAlias": {
                "registry": "yourRegistryName.azurecr.io",
                "modulePath": "bicep"
            }
        }
    }
}
```

---

## Security

In order for the pipeline to access the bicep container registry, it will need an "az login" command to be executed before the bicep is compiled.

``` bash
- script: az login --service-principal -u $(acrPrincipalId) -p $(acrPrincipalSecret) --tenant $(acrTenantId)
displayName: 'az login'
```

NOTE: The service principal **may** need to be in the "acr pull" role for the container registry. *(This needs to be confirmed!)*

Note: this might also be accomplished by using a token instead of a service principal. *(This needs to be researched and documented!*)  

See: [Container Registry Scoped Permissions](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-repository-scoped-permissions)

---

## Setup a Bicep Container Registry

1. Run the pipeline 'create-bicep-registry.yml' or run a command similar to the one below to create a container registry in a resource group

    ``` bash
    $resourceGroupName = 'yourResourceGroup'
    $registryName = 'yourRegistryName'
    az deployment group create -n main-deploy-20230213T090000Z --resource-group $resourceGroupName --template-file 'containerregistry.bicep' --parameters registryName=$registryName
    ```

2. Set up the pipeline publish-bicep-modules.yml, which will push bicep file changes to the container registry as they are committed. The pipeline needs two variables defined: registryName and subscriptionName.

---

## Bicep Container Registry Commands

### List Contents of a BCR

To list the contents of all the registry images and their tags:

``` bash
$registryName = 'yourRegistryName'
$modulePrefix = 'bicep/'
Write-Host "Scanning for repository tags in $registryName"
az acr repository list --name $registryName --query "[?contains(@, '${modulePrefix}')]" -o tsv | Foreach-Object { 
    $thisModule = $_
    az acr repository show-tags --name $registryName --repository $_ --output tsv  | Foreach-Object { 
      Write-Host "$thisModule`:$_"
    }
}
```

### Removing a BCR Entry

With these scripts, the entries are locked, so they are not easily removed. To remove a repository entry from the registry, you need to unlock it, then delete it:

``` bash
$registryName = 'yourRegistryName'
$repositoryEntry = 'bicep/sample3:2022-08-24.259'
az acr repository update --name $registryName --image $repositoryEntry --write-enabled true
az acr repository delete --name $registryName --image $repositoryEntry 
```
