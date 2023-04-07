# Deploy Cargo Tracker to Open Liberty on Azure Kubernetes Service (AKS)

This quickstart shows you how to deploy an existing Liberty application to AKS using Liberty on AKS solution templates. When you're finished, you can continue to manage the application via the Azure CLI or Azure Portal.

Cargo Tracker is a Domain-Driven Design Jakarta EE application. The application is built with Maven and deployed to Open Liberty running in Azure Kubernetes Service (AKS). This quickstart uses the [official Azure offer for running Liberty on AKS](https://aka.ms/liberty-aks). The application is exposed by Azure Load Balancer service via Public IP address.

* [Deploy Cargo Tracker to Open Liberty on Azure Kubernetes Service (AKS)]()
  * [Introduction](#introduction)
  * [Prerequisites](#prerequisites)
  * [Unit-1 - Deploy and monitor Cargo Tracker](#unit-1---deploy-and-monitor-cargo-tracker)
    * [Clone Cargo Tracker](#clone-cargo-tracker)
    * [Prepare your variables for deployments](#prepare-your-variables-for-deployments)
    * [Clone Liberty on AKS Bicep templates](#clone-liberty-on-aks-bicep-templates)
    * [Sign in to Azure](#sign-in-to-azure)
    * [Create a resource group](#create-a-resource-group)
    * [Create an Azure Database for PostgreSQL instance](#create-an-azure-database-for-postgresql-instance)
    * [Prepare deployment parameters](#prepare-deployment-parameters)
    * [Invoke Liberty on AKS Bicep template to deploy the application](#invoke-liberty-on-aks-bicep-template-to-deploy-the-application)
    * [Monitor WebLogic application](#monitor-weblogic-application)
      * [Create Application Insights](#create-application-insights)
      * [Use Cargo Tracker and make a few HTTP calls](#use-cargo-tracker-and-make-a-few-http-calls)
      * [Start monitoring Cargo Tracker in Application Insights](#start-monitoring-cargo-tracker-in-application-insights)
      * [Start monitoring Liberty logs in Azure Log Analytics](#start-monitoring-liberty-logs-in-azure-log-analytics)
      * [Start monitoring Cargo Tracker logs in Azure Log Analytics](#start-monitoring-cargo-tracker-logs-in-azure-log-analytics)
  * [Unit-2 - Automate deployments using GitHub Actions](#unit-2---automate-deployments-using-github-actions)
  * [Appendix 1 - Exercise Cargo Tracker Functionality](#appendix-1---exercise-cargo-tracker-functionality)
  * [Appendix 2 - Learn more about Cargo Tracker](#appendix-2---learn-more-about-cargo-tracker)

## Introduction

In this quickstart, you will:

* Deploying Cargo Tracker:
  * Create ProgresSQL Database
  * Create the Cargo Tracker - build with Maven
  * Provisioning Azure Infra Services with BICEP templates
    * Create an Azure Container Registry
    * Create an Azure Kubernetes Service
    * Build your application, Open Liberty into an image
    * Push your application image to the container registry
    * Deploy your application to AKS
    * Expose your application with the Azure Load Balancer service
  * Verify your application
  * Monitor application
  * Automate deployments using GitHub Actions

## Prerequisites

- Local shell with Azure CLI 2.46.0 and above or [Azure Cloud Shell](https://ms.portal.azure.com/#cloudshell/)
- Azure Subscription, on which you are able to create resources and assign permissions
  - View your subscription using ```az account show``` 
  - If you don't have an account, you can [create one for free](https://azure.microsoft.com/free). 
  - Your subscription is accessed using an Azure Service Principal with at least **Contributor** and **User Access Administrator** permissions.
- We strongly recommend you use Azure Cloud Shell. For local shell, make sure you have installed the following tools.
  - A Java JDK, Version 11. Azure recommends [Microsoft Build of OpenJDK](https://learn.microsoft.com/en-us/java/openjdk/download). Ensure that your JAVA_HOME environment.
  - [Git](https://git-scm.com/downloads). use git --version to test whether git works. This tutorial was tested with version 2.25.1.
  - GitHub CLI (optional, but strongly recommended). To install the GitHub CLI on your dev environment, see [Installation](https://cli.github.com/manual/installation).
  - [Kubernetes CLI](https://kubernetes-io-vnext-staging.netlify.com/docs/tasks/tools/install-kubectl/); use `kubectl version` to test if `kubectl` works. This document was tested with version v1.21.1.
  - [Maven](https://maven.apache.org/download.cgi). use `mvn -version` to test whether `mvn` works. This tutorial was tested with version 3.6.3.

## Unit-1 - Deploy and monitor Cargo Tracker

### Clone Cargo Tracker

Clone the sample app repository to your development environment.

```bash
mkdir cargotracker-liberty-aks
DIR="$PWD/cargotracker-liberty-aks"

git clone https://github.com/Azure-Samples/cargotracker-liberty-aks.git ${DIR}/cargotracker
```

### Prepare your variables for deployments

Create a bash script with environment variables by making a copy of the supplied template:

```bash
cp ${DIR}/cargotracker/.scripts/setup-env-variables-template.sh ${DIR}/cargotracker/.scripts/setup-env-variables.sh
```

Open ${DIR}/cargotracker/.scripts/setup-env-variables.sh and enter the following information. Make sure your Oracle SSO user name and password are correct.

```bash
export LIBERTY_AKS_REPO_REF="964f6463d6cfda9572d215cdd53109cee8f4ff1e" # WASdev/azure.liberty.aks
export RESOURCE_GROUP_NAME="abc1110rg" # customize this
export DB_SERVER_NAME="libertydb$(date +%s)" # PostgreSQL server name
export DB_PASSWORD="Secret123456" # PostgreSQL database password
```

Then, set the environment:

```bash
source ${DIR}/cargotracker/.scripts/setup-env-variables.sh
```

### Clone Liberty on AKS Bicep templates

```bash
git clone https://github.com/WASdev/azure.liberty.aks ${DIR}/azure.liberty.aks

cd ${DIR}/azure.liberty.aks
git checkout ${LIBERTY_AKS_REPO_REF}

cd ${DIR}
```

### Sign in to Azure

If you haven't already, sign in to your Azure subscription by using the `az login` command and follow the on-screen directions.

```bash
az login
```

If you have multiple Azure tenants associated with your Azure credentials, you must specify which tenant you want to sign in to. You can do this with the `--tenant` option. For example, `az login --tenant contoso.onmicrosoft.com`.

### Create a resource group

Create a resource group with `az group create`. Resource group names must be globally unique within a subscription.

```bash
az group create \
    --name ${RESOURCE_GROUP_NAME} \
    --location eastus
```

### Create an Azure Database for PostgreSQL instance

Use `az postgres server create` to provision a PostgreSQL instance on Azure. The data server allows access from Azure Services.

```bash
az postgres server create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name ${DB_SERVER_NAME}  \
  --location eastus \
  --admin-user liberty \
  --ssl-enforcement Disabled \
  --public-network-access Enabled \
  --admin-password ${DB_PASSWORD} \
  --sku-name B_Gen5_1

  echo "Allow Access To Azure Services"
  az postgres server firewall-rule create \
  -g ${RESOURCE_GROUP_NAME} \
  -s ${DB_SERVER_NAME} \
  -n "AllowAllWindowsAzureIps" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "0.0.0.0"
```

Obtain the JDBC connection string, which will be used as a deployment parameter.

```bash
DB_CONNECTION_STRING="jdbc:postgresql://${DB_SERVER_NAME}.postgres.database.azure.com:5432/postgres"
```

### Prepare deployment parameters

Several parameters are required to invoke the Bicep templates. Parameters and their value are listed in the table. Make sure the variables have correct value.

| Parameter Name | Value | Note |
|----------------|-------|------|


### Invoke Liberty on AKS Bicep template to deploy the Open Liberty Operator

### Create Application Insights

### Build and deploy Cargo Tracker

### Monitor Liberty application

#### Use Cargo Tracker and make a few HTTP calls

#### Start monitoring Cargo Tracker in Application Insights

#### Start monitoring Liberty logs in Azure Log Analytics

#### Start monitoring Cargo Tracker logs in Azure Log Analytics

## Unit-2 - Automate deployments using GitHub Actions

1. Fork the repository by clicking the 'Fork' button on the top right of the page.
This creates a local copy of the repository for you to work in. 

2. Configure GITHUB Actions:  Follow the instructions in the [GITHUB_ACTIONS_CONFIG.md file](.github/GITHUB_ACTIONS_CONFIG.md) (Located in the .github folder.)

4. Manually run the workflow

* Under your repository name, click Actions.
* In the left sidebar, click the workflow "Setup OpenLiberty on AKS".
* Above the list of workflow runs, select Run workflow.
* Configure the workflow.
  + Use the Branch dropdown to select the workflow's main branch.
  + For **Included in names to disambiguate. Get from another pipeline execution**, enter disambiguation prefix, e.g. `test01`.

5. Click Run workflow.

### Workflow description

As mentioned above, the app template uses the [official Azure offer for running Liberty on AKS](https://aka.ms/liberty-aks). The workflow uses the source code behind that offer by checking it out and invoking it from Azure CLI.

#### Job: preflight

This job is to build Liberty on AKS template into a ZIP file containing the ARM template to invoke.

* Set up environment to build the Liberty on AKS templates
  + Set up JDK 1.8
  + Set up bicep 0.11.1

* Download dependencies
  + Checkout azure-javaee-iaas, this is a precondition necessary to build Liberty on AKS templates. For more details, see [Azure Marketplace Azure Application (formerly known as Solution Template) Helpers](https://github.com/Azure/azure-javaee-iaas).

* Checkout and build Liberty on AKS templates
  + Checkout ${{ env.aksRepoUserName }}/azure.liberty.aks. Checkout [WASdev/azure.liberty.aks](https://github.com/WASdev/azure.liberty.aks) by default. This repository contains all the BICEP templates that provision Azure resources, configure Liberty and deploy app to AKS. 
  + Build and test ${{ env.aksRepoUserName }}/azure.liberty.aks. Build and package the Liberty on AKS templates into a ZIP file (e.g. azure.liberty.aks-1.0.32-arm-assembly.zip). The structure of the ZIP file is:

    ```text
    ├── mainTemplate.json (ARM template that is built from BICEP files, which will be invoked for the following deployments)
    └── scripts (shell scripts and metadata)
    ```

  + Archive Archive azure.liberty.aks template template. Upload the ZIP file to the pipeline. The later jobs will download the ZIP file for further deployments.

#### Job: deploy-db

This job is to deploy PostgreSQL server and configure firewall setting.

* Set Up Azure Database for PostgreSQL
  + azure-login. Login Azure.
  + Create Resource Group. Create a resource group to which the database will deploy.
  + Set Up Azure Postgresql to Test dbTemplate. Provision Azure Database for PostgreSQL Single Server. The server allows access from Azure services.

#### Job: deploy-openliberty-on-aks

This job is to provision Azure resources, run Open Liberty Operator on AKS using the solution template.

* Download the Liberty on AKS solution template
  + Checkout ${{ env.aksRepoUserName }}/azure.liberty.aks. Checkout [WASdev/azure.liberty.aks](https://github.com/WASdev/azure.liberty.aks) to find the version information.
  + Get version information from azure.liberty.aks/pom.xml. Get the version info for solution template ZIP file, which is used to generate the ZIP file name: `azure.liberty.aks-${version}-arm-assembly.zip`
  + Output artifact name for Download action. Generate and output the ZIP file name: `azure.liberty.aks-${version}-arm-assembly.zip`.
  + Download artifact for deployment. Download the ZIP file that is built in job:preflight.

* Deploy Liberty on AKS
  + azure-login. Login Azure.
  + Create Resource Group. Create a resource group for Liberty on AKS.
  + Checkout cargotracker. Checkout the parameter template.
  + Prepare parameter file. Set values to the parameters.
  + Validate Deploy of Open Liberty Server Cluster Domain offer. Validate the parameters file in the context of the bicep template to be invoked. This will catch some errors before taking the time to start the full deployment. `--template-file` is the mainTemplate.json from solution template ZIP file. `--parameters` is the parameter file created in last step.
  + Deploy Open Liberty Server Cluster Domain offer. Invoke the mainTemplate.json to deploy resources and configurations. After the deployment completes, you'll get the following result:
    + An Azure Container Registry. It'll store app image in the later steps.
    + An Azure Kubernetes Service with Open Liberty Operator running in `default` namespace.

#### Job: deploy-cargo-tracke

This job is to build app, push it to ACR and apply it to Open Liberty server running on AKS.

* Prepare env
  + Set up JDK 1.8。
  + Install jq.
  + Prepare variables. Obtain AKS and ACR resource properties that will be used in later deployment.

* Deploy Cargo Tracker
  + Checkout cargotracker. Checkout source code of cargo tracker from this repository.
  + Build the app. Set required environment variables and build cargo tracker with Maven.
  + Query version string for deployment verification. Obtain the app version string for later verification.
  + Build image and upload to ACR. Build cargo tracker into a docker image with docker file locating in [Dockerfile](Dockerfile), and push the image to ACR.
  + Connect to AKS cluster. Connect to AKS cluster to deploy cargo tracker.
  + Apply deployment files. Apply data source configuration in `target/db-secret.yaml` and cargo tracker metadata in `target/openlibertyapplication.yaml`. This will cause cargo tracker deployed to the AKS cluster.
  + Verify pods are ready. Make sure cargo tracker is live.
  + Query Application URL. Obtain cargo tracker URL.
  + Verify that the app is update. Make sure cargo tracker is running by validating its version string.
  + Print app URL. Print the cargo tracker URL to pipeline summary page. Now you'are able to access cargo tracker with the URL from your browser.

## Appendix 1 - Exercise Cargo Tracker Functionality

1. On the main page, select **Public Tracking Interface** in new window. 

   1. Enter **ABC123** and select **Track!**

   1. Observe what the **next expected activity** is.

1. On the main page, select **Administration Interface**, then, in the left navigation column select **Live** in a new window.  This opens up a map view.

   1. Mouse over the pins and find the one for **ABC123**.  Take note of the information in the hover window.

1. On the main page, select **Mobile Event Logger**.  This opens up in a new, small, window.

1. Drop down the menu and select **ABC123**.  Select **Next**.

1. Select the **Location** using the information in the **next expected activity**.  Select **Next**.

1. Select the **Event Type** using the information in the **next expected activity**.  Select **Next**.

1. Select the **Voyage** using the information in the **next expected activity**.  Select **Next**.

1. Set the **Completion Date** a few days in the future.  Select **Next**.

1. Review the information and verify it matches the **next expected activity**.  If not, go back and fix it.  If so, select **Submit**.

1. Back on the **Public Tracking Interface** select **Tracking** then enter **ABC123** and select **Track**.  Observe that a different. **next expected activity** is listed.

1. If desired, go back to **Mobile Event Logger** and continue performing the next activity.

## LAppendix 2 - Learn more about Cargo Tracker

See [Eclipse Cargo Tracker - Applied Domain-Driven Design Blueprints for Jakarta EE](cargo-tracker.md)