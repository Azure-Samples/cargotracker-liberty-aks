# Configuration for GitHub Actions

The newly created GitHub repo uses GitHub Actions to deploy Azure resources and application code automatically. Your subscription is accessed using an Azure Service Principal with **Contributor** and **User Access Administrator** permissions. This is an identity created for use by applications, hosted services, and automated tools to access Azure resources. Make sure your identity that runs the scripts has at least **Contributor** and **User Access Administrator**. 

If you have [GitHub CLI](https://cli.github.com/) installed, the script will create GitHub Action secrets automatically. Otherwise, you have to create the secrets following steps in [set up GitHub Actions to deploy Azure applications](https://github.com/Azure/actions-workflow-samples/blob/master/assets/create-secrets-for-GitHub-workflows.md)

## Setup/Teardown configuration
- Follow guidance on top of [setup-credentials.sh](../.github/workflows/setup-credentials.sh#L6) to run the shell scripts. The scripts will set the necessary secrets for the repository running the workflows.
- If you want to tear down the secrets, follow the guidance on top of [teardown-credentials.sh](../.github/workflows/teardown-credentials.sh#L6) to run the shell scripts. The scripts will remove the necessary secrets for the repository running the workflows.
