# GitHub Action Workflow Examples

This folder contains examples of multi-stage GitHub Action Workflows that deploy resources to Azure.

These files are structured in two layers of files.  

- **Workflows:** This folder contains the workflows that are unique to a project, where you would specify secrets and environment names that are being deployed, as well as call out the individual templates that are being deployed.

  - **Templates:** GitHub expects all of these files to be in the workflows folder, so these are differentiated by the naming standard of 'template-*.yml'.  Each workflow calls any number of template files that actually perform the actions of deploying resources to Azure. These files should not change between projects (or very minimal changes if necessary).

Most of these templates rely on a GitHub Secrets that are predefined.
See - [Creating GitHub Secrets](CreateGitHubSecrets.md).
