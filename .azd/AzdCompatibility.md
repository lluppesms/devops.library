# Converting a Project to use AZD Command Line Deploy

The Azure Developer CLI (azd) is an open-source tool that accelerates the time it takes to get started on Azure. azd provides a set of developer-friendly commands that map to key stages in a workflow (code, build, deploy, monitor).

Converting a project to use the AZD commands is a matter following a few conventions and adding a few files to the project.

## Folder Conventions

- **Infra Folder:** The main.bicep file is the key to this process and it must reside in a folder named "infra".

- **Src Folder:** Source code for the project should reside in a folder named "src".

## Key Files

There are four key files that drive the AZD process:

| Folder  | File                     | Description               |
| ------- | ------------------------ | ------------------------- |
| /       | azure.yaml               | Build Process Definition  |
| /infra/ | main.bicep               | Azure Resource Definition |
| /infra/ | main.parameters.json     | Resource Parameters       |
| /github/workflows/ | azure-dev.yml | GitHub Action to Build and Deploy |

---

### /azure.yaml

The azure.yaml file defines where to find the infrastructure files, and what to build. It is possible to override the location and name of the main.bicep file name by overriding the infra.path and infra.module values.

This example shows how to build and deploy a C# Azure Function.

```bash
name: <projectName>
infra:
    provider: bicep
    path: infra
    module: main
pipeline:
    provider: github
services:
  function:
    project: src/<your CSProj Name>/
    language: csharp
    host: function
```

### .github/workflows/azure-dev.yml

The azure-dev.yml file creates the GitHub action that will build the Azure resources and deploy the application based on the user inputs.

```bash
on:
  workflow_dispatch:
  push:
    branches:
      - main
      - master
  pull_request:
    branches:
      - main
      - master

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: mcr.microsoft.com/azure-dev-cli-apps:latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Log in with Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Azure Dev Provision
        run: azd provision --no-prompt
        env:
          AZURE_ENV_NAME: ${{ secrets.AZURE_ENV_NAME }}
          AZURE_LOCATION: ${{ secrets.AZURE_LOCATION }}
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Azure Dev Deploy
        run: azd deploy --no-prompt
        env:
          AZURE_ENV_NAME: ${{ secrets.AZURE_ENV_NAME }}
          AZURE_LOCATION: ${{ secrets.AZURE_LOCATION }}
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### /infra/main.bicep

The main.bicep file is the file that defines what is deployed to Azure, and it can be modified to do is required for the project. However, the input parameters are limited to name, location, and principal.

```bash
targetScope = 'subscription'

param name string
param location string
param principalId string = ''

var resourceToken = toLower(uniqueString(subscription().id, name))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
    name: 'rg-${name}'
    location: location
}
module resources './Bicep/main.bicep' = {
    name: 'resources-${resourceToken}'
    scope: resourceGroup
    params: {
        name: name
        location: location
        principalId: principalId
        resourceToken: resourceToken
    }
}
```

### /infra/main.parameters.json

The main.parameters.json file defines the three required input parameters that are passed in by the AZD command to the main.bicep file.

```bash
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "name": {
        "value": "${AZURE_ENV_NAME}"
        },
        "location": {
        "value": "${AZURE_LOCATION}"
        },
        "principalId": {
        "value": "${AZURE_PRINCIPAL_ID}"
        }
    }
}
```

## Setup Complete

Once you have these files and folders in place, the AZD commands should begin to work properly. There are many other options that can be explored, this is just one example that works for an Azure Function.

---

## Reference

[Make your project compatible with Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create)

[Azure Developer CLI Reference](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)

[Introducing the Azure Developer CLI - Azure SDK Blog](https://devblogs.microsoft.com/azure-sdk/introducing-the-azure-developer-cli-a-faster-way-to-build-apps-for-the-cloud/)
