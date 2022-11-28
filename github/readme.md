# GitHub Action Workflow Examples

This folder contains examples of multi-stage GitHub Action Workflows that deploy resources to Azure.

These files are structured in two layers of files. GitHub Actions expects all of these files to be in the ".github/workflows" folder, so these are differentiated by the naming standard of:

- Workflows are named 'deploy-*.yml', and are the workflows that are unique to a project. In the workflow, the secrets and environment names for this project are defined, as well as the calls out the templates that are being utilized.

  - Templates are named 'template-*.yml' and each workflow calls any number of template files. The templates actually perform the actions of deploying resources to Azure. (These files should not change between projects - or very minimal changes if necessary).

Most of these templates rely on a GitHub Secrets that are predefined. 
See - [Creating GitHub Secrets](CreateGitHubSecrets.md).
