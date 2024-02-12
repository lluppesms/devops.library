# Azure DevOps Pipeline Examples

This folder contains examples of multi-stage Azure DevOps pipelines that deploy resources to Azure.

These files are structured in three layers of files.  

- **Pipelines:** The Pipeline_Examples folder contains the pipelines that are unique to a project, where you would specify variable group names and environment names that are being deployed, as well as call out the individual pipes that are being deployed.

  - **Pipes:** Each pipeline may call any number of "pipes", which consist of a set of predefined actions. (These files should not change between projects - or at least have very minimal changes such as additional variables if necessary).

    - **Templates:** Each "pipe" calls any number of template files that actually perform the actions of deploying resources to Azure. These files should not change between projects.
         (These files should not change between projects - or at least have very minimal changes such as additional variables if necessary).

Most of these templates rely on a variable group that is predefined.
See - [Creating Variable Groups](CreateDevOpsVariableGroups.md).
