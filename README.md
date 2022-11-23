# Bicep Container Registries

To share bicep files among development teams, they can be published to a Container Registry.

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

Note: this might also be accomplished by using a token instead of a service principal. *(This needs to be researched and documented!*  See: [Container Registry Scoped Permissions](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-repository-scoped-permissions) )

---

## Idea to Upgrade this Repo?

Investigate/Create this process in this repository:

- Make a pipeline to create resources (i.e. container registry and Key Vault)
- Create two tokens in the registry (a read and a write token)
- Add those token values to the key vault
- Have the publish bicep file pipeline use the writable token to access registry
- Set permissions for other pipelines:
  - Grant them rights to the Key Vault and to only that one read key
  - They can access the registry entries in their pipelines using the read token

---

## Setup

1. Run a command similar to the below to create a container registry in a resource group

    ``` bash
    az deployment group create -n main-deploy-20221103T090000Z --resource-group rg_bicep_registry --template-file '.infrastructure/containerregistry.bicep' --parameters registryName=xxxbicepregistry
    ```

2. Set up the pipeline .infrastructure/publish-bicep-modules.yml, which will push bicep file changes to the container registry as they are committed. The pipeline needs two variables defined: registryName
and subscriptionName.
