# Deploy Cargo Tracker to Open Liberty on Azure Kubernetes Service (AKS)

This sample shows you how to deploy an existing Liberty application to AKS using Liberty on AKS solution templates. When you're finished, you can continue to manage the application via the Azure CLI or Azure Portal.

Cargo Tracker is a Domain-Driven Design Jakarta EE application. The application is built with Maven and deployed to Open Liberty running on Azure Kubernetes Service (AKS). The application is exposed by Azure Application Gateway service. For quickstart uses the [official Azure offer for running Liberty on AKS](https://aka.ms/liberty-aks), see [Deploy a Java application with Open Liberty or WebSphere Liberty on an Azure Kubernetes Service (AKS) cluster](https://learn.microsoft.com/azure/aks/howto-deploy-java-liberty-app). 

* [Deploy Cargo Tracker to Open Liberty on Azure Kubernetes Service (AKS)]()
  * [Introduction](#introduction)
  * [Prerequisites](#prerequisites)
  * [Unit-1 - Deploy and monitor Cargo Tracker](#unit-1---deploy-and-monitor-cargo-tracker)
    * [Clone Cargo Tracker](#clone-cargo-tracker)
    * [Prepare your variables for deployments](#prepare-your-variables-for-deployments)
    * [Clone Liberty on AKS Bicep templates](#clone-liberty-on-aks-bicep-templates)
    * [Build Liberty on AKS Bicep templates](#build-liberty-on-aks-bicep-templates)
    * [Sign in to Azure](#sign-in-to-azure)
    * [Create a resource group](#create-a-resource-group)
    * [Prepare deployment parameters](#prepare-deployment-parameters)
    * [Invoke Liberty on AKS Bicep template to deploy the Open Liberty Operator](#invoke-liberty-on-aks-bicep-template-to-deploy-the-open-liberty-operator)
    * [Create an Azure Database for PostgreSQL instance](#create-an-azure-database-for-postgresql-instance)
    * [Create Application Insights](#create-application-insights)
    * [Build and deploy Cargo Tracker](#build-and-deploy-cargo-tracker)
    * [Monitor Liberty application](#monitor-liberty-application)
      * [Use Cargo Tracker and make a few HTTP calls](#use-cargo-tracker-and-make-a-few-http-calls)
      * [Start monitoring Cargo Tracker in Application Insights](#start-monitoring-cargo-tracker-in-application-insights)
      * [Start monitoring Liberty logs in Azure Log Analytics](#start-monitoring-liberty-logs-in-azure-log-analytics)
      * [Start monitoring Cargo Tracker logs in Azure Log Analytics](#start-monitoring-cargo-tracker-logs-in-azure-log-analytics)
  * [Unit-2 - Automate deployments using GitHub Actions](#unit-2---automate-deployments-using-github-actions)
  * [Unit-3 - Automate deployments using AZD](#unit-3---automate-deployments-using-AZD)
  * [Appendix 1 - Exercise Cargo Tracker Functionality](#appendix-1---exercise-cargo-tracker-functionality)
  * [Appendix 2 - Learn more about Cargo Tracker](#appendix-2---learn-more-about-cargo-tracker)
  * [Appendix 3 - Run cargotracker locally against cloud supporting resources](#appendix-3---run-locally-with-remote-resources-without-docker)

## Introduction

In this sample, you will:

* Deploy Cargo Tracker:
  * Create PostgreSQL Database
  * Create the Cargo Tracker - build with Maven
  * Provision Azure Infra Services with BICEP templates
    * Create an Azure Container Registry
    * Create an Azure Kubernetes Service
    * Build your application, Open Liberty into a container image
    * Push your application image to the container registry
    * Deploy your application to AKS
    * Expose your application with the Azure Application Gateway
  * Verify your application
  * Monitor application
  * Automate deployments using GitHub Actions
  * Automate deployments using AZD

## Prerequisites

- JDK 17
- GIT: git version `2.33.6`.
- Kubernetes CLI version as following:

   ```bash
   Client Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.3", GitCommit:"9e644106593f3f4aa98f8a84b23db5fa378900bd", GitTreeState:"clean", BuildDate:"2023-03-15T13:40:17Z", GoVersion:"go1.19.7", Compiler:"gc", Platform:"linux/amd64"}
   Kustomize Version: v4.5.7
   ```
- Maven: Apache Maven `3.8.7` (NON_CANONICAL).
- Azure Subscription, on which you are able to create resources and assign permissions
  - View your subscription using ```az account show``` 
  - If you don't have an account, you can [create one for free](https://azure.microsoft.com/free). 
  - Your subscription is accessed using an Azure Service Principal with at least **Contributor** and **User Access Administrator** permissions.

## Unit-1 - Deploy and monitor Cargo Tracker

> [!NOTE]  
> You can jump to [Unit-3 - Automate deployments using AZD](#unit-3---automate-deployments-using-azd) if you want to automate deployments using AZD instead of manually deploying Cargo Tracker.

### Clone Cargo Tracker

Clone the sample app repository to your development environment.

```bash
mkdir cargotracker-liberty-aks
export DIR="$PWD/cargotracker-liberty-aks"

git clone https://github.com/Azure-Samples/cargotracker-liberty-aks.git ${DIR}/cargotracker
cd ${DIR}/cargotracker
git checkout 20241031
```

If you see a message about `detached HEAD state`, it is safe to ignore. It just means you have checked out a tag.

### Optional -- Prepare Azure OpenAI for use

The steps in this section are optional unless you want to enable the AI shortest path computation.

1. Create an Azure Open AI account and get the required credentials.

   1. In a new tab, visit [Create and deploy an Azure OpenAI Service resource](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal).
   1. If you want to use the following steps, select the **Portal** tab. Otherwise, just follow the documentation to get the following environment variable values in the way best suited to your needs.

      - `AZURE_OPENAI_KEY`: Your Azure Open AI API key.
      - `AZURE_OPENAI_ENDPOINT`: Your Azure OpenAI Endpoint. This will be something like `https://ejb011017openai.openai.azure.com/`
      - `AZURE_OPENAI_DEPLOYMENT_NAME`: Your Azure Open AI Deployment name. This example uses `gpt-4o`
      
   1. Follow the steps up to but not including the section **Deploy a model**.
   
   1. Expand **Resource management** in the left navigation bar and select **Keys and Endpoint**.
   
   1. Select the copy icon next to the value for **KEY 1** and save the value as the value of your `AZURE_OPENAI_KEY` environment variable.
   
   1. Select the copy icon next to the value for **Endpoint** and save the value as the value of your `AZURE_OPENAI_ENDPOINT` environment variable.
   
   1. Continue in the steps with the section **Deploy a model**.
   
   1. When you get to the step asking you to **Create new deployment**, use the following substitutions.
   
      1. For **Select a model** select **gpt-4o**.
      1. For **Deployment name** use **gpt-4o**.

    - To learn more about Azure OpenAI see [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/how-to/create-resource?pivots=cli).

### Prepare your variables for deployments

Create a bash script with environment variables by making a copy of the supplied template. Customize the variables indicated.

```bash
cp ${DIR}/cargotracker/.scripts/setup-env-variables-template.sh ${DIR}/setup-env-variables.sh
```

Open `${DIR}/setup-env-variables.sh` and customize the values as indicated. If running the AI shortest path feature, uncomment and customize those values as described previously.

Then, set the environment:

```bash
source ${DIR}/setup-env-variables.sh
```

### Clone Liberty on AKS Bicep templates

```bash
cd ${DIR}
git clone https://github.com/WASdev/azure.liberty.aks ${DIR}/azure.liberty.aks

cd ${DIR}/azure.liberty.aks
git checkout ${LIBERTY_AKS_REPO_REF}

cd ${DIR}
```

If you see a warning about being in 'detached HEAD' state, it is safe to ignore.

### Build Liberty on AKS Bicep templates

```bash
cd ${DIR}/azure.liberty.aks
export VERSION=$(grep -A4 "<parent>" pom.xml | grep "<version>" | awk -F'[<>]' '{print $3}')

cd ${DIR}
curl -L -o ${DIR}/azure-javaee-iaas-parent-${VERSION}.pom  \
     https://github.com/azure-javaee/azure-javaee-iaas/releases/download/azure-javaee-iaas-parent-${VERSION}/azure-javaee-iaas-parent-${VERSION}.pom


mvn install:install-file -Dfile=${DIR}/azure-javaee-iaas-parent-${VERSION}.pom \
                         -DgroupId=com.microsoft.azure.iaas \
                         -DartifactId=azure-javaee-iaas-parent \
                         -Dversion=${VERSION} \
                         -Dpackaging=pom

cd ${DIR}/azure.liberty.aks
mvn clean package -DskipTests
```

### Sign in to Azure

If you haven't already, sign into your Azure subscription by using the `az login` command and follow the on-screen directions.

```bash
az login --use-device-code
```

If you have multiple Azure tenants associated with your Azure credentials, you must specify which tenant you want to sign in to. You can do this with the `--tenant` option. For example, `az login --tenant contoso.onmicrosoft.com`.

### Create a resource group

Create a resource group with `az group create`. Resource group names must be globally unique within a subscription.

```bash
az group create \
    --name ${RESOURCE_GROUP_NAME} \
    --location ${LOCATION}
```

### Prepare deployment parameters

Several parameters are required to invoke the Bicep templates. Parameters and their value are listed in the table. Make sure the variables have correct value.

| Parameter Name | Value | Note |
|----------------|-------|------|
| `_artifactsLocation ` | `https://raw.githubusercontent.com/WASdev/azure.liberty.aks/${LIBERTY_AKS_REPO_REF}/src/main/` | This quickstart is using templates and scripts from `WASdev/azure.liberty.aks/${LIBERTY_AKS_REPO_REF}`. | 
| `createCluster` | `true` | This value causes provisioning of Azure Kubernetes Service. |
| `vmSize` | `Standard_DS2_v2` | VM size of AKS node. |
| `minCount` | `1` | Minimum count of AKS nodes. |
| `maxCount` | `5` | Maximum count of AKS nodes. |
| `createACR` | `true` | This value causes provisioning of Azure Container Registry. |
| `deployApplication` | `false` | The application will be deployed on the later section. |
| `enableAppGWIngress` | `true` | The value causes to provision Azure Application Gateway Ingress Controller. |
| `appGatewayCertificateOption` | `generateCert` | The option causes generation self-signed certificate for Application Gateway. |
| `enableCookieBasedAffinity` | `true` | The value causes to enable cookie-based affinity for Application Gateway backend setting. |

Create parameter file.

```bash
cat <<EOF >parameters.json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "_artifactsLocation": {
        "value": "https://raw.githubusercontent.com/WASdev/azure.liberty.aks/${LIBERTY_AKS_REPO_REF}/src/main/"
    },
    "location": {
        "value": "eastus"
    },
    "createCluster": {
        "value": true
    },
    "vmSize": {
        "value": "Standard_DS2_v2"
    },
    "minCount": {
        "value": 1
    },
    "maxCount": {
        "value": 5
    },
    "createACR": {
        "value": true
    },
    "deployApplication": {
        "value": false
    },
    "enableAppGWIngress": {
        "value": true
    },
    "appGatewayCertificateOption": {
        "value": "generateCert"
    },
    "enableCookieBasedAffinity": {
        "value": true
    }
  }
}
EOF
```

### Invoke Liberty on AKS Bicep template to deploy the Open Liberty Operator

Invoke the Bicep template in `${DIR}/azure.liberty.aks/target/main/bicep/mainTemplate.bicep` to deploy Open Liberty Operator on AKS.

Run the following command to validate the parameter file.

```bash
az deployment group validate \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name liberty-on-aks \
  --parameters @parameters.json \
  --template-file ${DIR}/azure.liberty.aks/target/bicep/mainTemplate.bicep
```

The command should be completed without error. If there is, you must resolve it before moving on. Verify the exit status from the command by examining shell's exit status. In POSIX environments, this is `$?`.

```bash
echo $?
```

The value must be **0**.

Next, invoke the template.

```bash
az deployment group create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --name liberty-on-aks \
  --parameters @parameters.json \
  --template-file ${DIR}/azure.liberty.aks/target/bicep/mainTemplate.bicep
```

It takes more than 10 minutes to finish the deployment. The Open Liberty Operator is running in namespace `default`.

### Create an Azure Database for PostgreSQL instance

While the previous command runs, use `az postgres flexible-server create` to provision a PostgreSQL instance on Azure. The data server allows access from Azure Services.

```bash
az postgres flexible-server create \
   --resource-group ${RESOURCE_GROUP_NAME} \
   --name ${DB_SERVER_NAME} \
   --location ${LOCATION} \
   --admin-user ${DB_ADMIN_USER} \
   --admin-password ${DB_PASSWORD} \
   --version 15 --public-access 0.0.0.0 
   --tier Burstable --sku-name Standard_B1ms --yes

az postgres flexible-server db create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --server-name ${DB_SERVER_NAME} \
  --database-name ${DB_NAME}

echo "Allow Access to Azure Services"
az postgres flexible-server firewall-rule create \
  -g ${RESOURCE_GROUP_NAME} \
  -n ${DB_SERVER_NAME} \
  -r "AllowAllWindowsAzureIps" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "0.0.0.0"
```

Once the server has been deployed, you must set this parameter and restart the database.

```bash
az postgres flexible-server parameter set --name max_prepared_transactions --value 10 -g ${RESOURCE_GROUP_NAME} --server-name ${DB_SERVER_NAME}

az postgres flexible-server restart -g ${RESOURCE_GROUP_NAME} --name ${DB_SERVER_NAME}
```

### Create Application Insights

To integrate with Application Insights, you need to have an Application Insights instance and expose metrics to it using the Java agent.

First, install or upgrade `application-insights` extension.

```bash
az extension add --upgrade -n application-insights
```

Create a Log Analytics Workspace.

```bash
az monitor log-analytics workspace create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --workspace-name ${WORKSPACE_NAME} \
  --location ${LOCATION}

export WORKSPACE_ID=$(az monitor log-analytics workspace list -g ${RESOURCE_GROUP_NAME} --query '[0].id' -o tsv)
```


This quickstart uses Container Insights to monitor AKS. Enable it with the following commands. 

```bash
export AKS_CLUSTER_NAME=$(az aks list -g ${RESOURCE_GROUP_NAME} --query \[0\].name -o tsv)

az aks enable-addons \
  --addons monitoring \
  --name ${AKS_CLUSTER_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --workspace-resource-id ${WORKSPACE_ID}
```

Next, provision Application Insights.

```bash
az monitor app-insights component create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --app ${APPINSIGHTS_NAME} \
  --location ${LOCATION} \
  --workspace ${WORKSPACE_ID}
```

Obtain the connection string of Application Insights which will be used in later section.

```bash
export APPLICATIONINSIGHTS_CONNECTION_STRING=$(az monitor app-insights component show \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --query '[0].connectionString' -o tsv)
```

### Build and deploy Cargo Tracker

First, prepare the environment variables used in the build time. If you haven't set the deployment variables, run the following command:

```bash
source ${DIR}/cargotracker/.scripts/setup-env-variables.sh
```

Next, obtain the registry information.

```bash
export REGISTRY_NAME=$(az acr list -g ${RESOURCE_GROUP_NAME} --query '[0].name' -o tsv)
export LOGIN_SERVER=$(az acr show -n ${REGISTRY_NAME} -g ${RESOURCE_GROUP_NAME} --query 'loginServer' -o tsv)
```

Now, you're ready to build Cargo Tracker.

```bash
mvn clean install -PopenLibertyOnAks --file ${DIR}/cargotracker/pom.xml
```

The war file is created at `${DIR}/cargotracker/target/cargo-tracker.war`. 

The following steps are to build a container image which will be deployed to AKS. 

The image tag is constructed with `${project.artifactId}:${project.version}`. Run the following command to obtain their values.

```bash
export IMAGE_NAME=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.artifactId}' --non-recursive exec:exec --file ${DIR}/cargotracker/pom.xml) 
export IMAGE_VERSION=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.version}' --non-recursive exec:exec --file ${DIR}/cargotracker/pom.xml)
```

Run `ac acr build` command to build the container image.

```bash
cd ${DIR}/cargotracker/target
az acr build -t ${IMAGE_NAME}:${IMAGE_VERSION} -r ${REGISTRY_NAME} .
```

The image is ready to deploy to AKS. Run the following command to connect to AKS cluster.

```bash
export AKS_CLUSTER_NAME=$(az aks list -g ${RESOURCE_GROUP_NAME} --query \[0\].name -o tsv)

az aks get-credentials --resource-group ${RESOURCE_GROUP_NAME} --name $AKS_CLUSTER_NAME
```

Run the following command to create secrets for data source connection and Application Insights connection.

Then deploy the container image to AKS cluster.

```bash
kubectl apply -f ${DIR}/cargotracker/target/db-secret.yaml
kubectl apply -f ${DIR}/cargotracker/target/app-insight.yaml
kubectl apply -f ${DIR}/cargotracker/target/openlibertyapplication.yaml

kubectl get pod -w
```

Press `Control + C` to exit the watching mode. 

Now, Cargo Tracker is running on Open Liberty, and connecting to Application Insights. You are able to monitor the application.

### Monitor Liberty application

This section uses Application Insights and Azure Log Analytics to monitor Open Liberty and Cargo Tracker. You can find the resource from your working resource group.

#### Use Cargo Tracker and make a few HTTP calls

You can open Cargo Tracker in your web browser. Use the following commands to obtain URL of Cargo Tracker. When accessing the application, if you get "502 Bad Gateway" response, just wait a few minutes.


```bash
export GATEWAY_PUBLICIP_ID=$(az network application-gateway list \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --query '[0].frontendIPConfigurations[0].publicIPAddress.id' -o tsv)

export GATEWAY_HOSTNAME=$(az network public-ip show --ids ${GATEWAY_PUBLICIP_ID} --query 'dnsSettings.fqdn' -o tsv)

export CARGO_TRACKER_URL="http://${GATEWAY_HOSTNAME}/cargo-tracker/"

echo "Cargo Tracker URL: ${CARGO_TRACKER_URL}"
```

Once you have the URL, follow [Appendix 1 - Exercise Cargo Tracker Functionality](#appendix-1---exercise-cargo-tracker-functionality) to make some calls.

You can also `curl` the REST API exposed by Cargo Tracker. It's strongly recommended you get familiar with Cargo Tracker with the above exercise.

The `/graph-traversal/shortest-path` REST API allows you to retrieve shortest path from origin to destination.

The API requires the following parameters:

| Parameter Name | Value |
| ------------------| ----------------- |
| `origin` | The UN location code value of origin and destination must be five characters long, the first two must be alphabetic and the last three must be alphanumeric (excluding 0 and 1). |
| `destination` | The UN location code value of origin and destination must be five characters long, the first two must be alphabetic and the last three must be alphanumeric (excluding 0 and 1). |
| `deadline` | **Optional**. Deadline value must be eight characters long. |

You can run the following curl command:

```bash
curl --verbose -X GET -H "Accept: application/json" "${CARGO_TRACKER_URL}rest/graph-traversal/shortest-path?origin=CNHKG&destination=USNYC"
```

The `/handling/reports` REST API allows you to send an asynchronous message with the information to the handling event registration system for proper registration.

The API requires the following parameters:

| Parameter Name | Value |
| ------------------| ----------------- |
| `completionTime` | Must be ClockHourOfAmPm. Format: `m/d/yyyy HH:MM tt`, e.g `3/29/2023 9:30 AM` |
| `trackingId` | Tracking ID must be at least four characters. |
| `eventType` | Event type value must be one of: RECEIVE, LOAD, UNLOAD, CUSTOMS, CLAIM. |
| `unLocode` | The UN location code value of origin and destination must be five characters long, the first two must be alphabetic and the last three must be alphanumeric (excluding 0 and 1). |
| `voyageNumber` | **Optional**. Voyage number value must be between four and five characters long. |

You can run the following `curl` command to load onto voyage 0200T in New York for trackingId of `ABC123`:

```bash
export DATE=$(date +'%m/%d/%Y %I:%M %p')
cat <<EOF >data.json
{
  "completionTime": "${DATE}",
  "trackingId": "ABC123",
  "eventType": "UNLOAD",
  "unLocode": "USNYC",
  "voyageNumber": "0200T"
}
EOF

curl --verbose -X POST -d "@data.json" -H "Content-Type: application/json" ${CARGO_TRACKER_URL}rest/handling/reports
```

You can use Application Insights to detect failures. Run the following `curl` command to cause a failed call. The REST API fails at incorrect datetime format.

```bash
export DATE=$(date +'%m/%d/%Y %H:%M:%S')
cat <<EOF >data.json
{
  "completionTime": "${DATE}",
  "trackingId": "ABC123",
  "eventType": "UNLOAD",
  "unLocode": "USNYC",
  "voyageNumber": "0200T"
}
EOF

curl -X POST -d "@data.json" -H "Content-Type: application/json" ${CARGO_TRACKER_URL}rest/handling/reports
```

The above request causes an error with message like "Error 500: java.time.format.DateTimeParseException: Text &#39;02/01/2024 08:04:49&#39; could not be parsed at index 16".

#### Start monitoring Cargo Tracker in Application Insights

Open the Application Insights and start monitoring Cargo Tracker. You can find the Application Insights in the same Resource Group where you created deployments using Bicep templates.

Navigate to the `Application Map` blade:

![Cargo Tracker Application Map in Application Insights](media/app-insights-app-map.png)

Navigate to the `Performance` blade:

![Cargo Tracker Performance in Application Insights](media/app-insights-performance.png)

Select operation **GET /cargo-tracker/cargo**, select **Drill into...**, **number-N Samples** you will find the operations are listed in the right panel.

Select the first operation with response code 200, the **End-to-end transaction details** page shows.

![Cargo Tracker transaction details in Application Insights](media/app-insights-cargo-end-to-end-transaction.png)

Select operation **POST /cargo-tracker/rest/handling/reports**, select **Drill into...**, **number-N Samples** you will find the operations are listed in the right panel.

Select the first operation with response code 204. Select the **View all** button in **Traces & events** panel, the traces and events are listed.

![Cargo Tracker traces and events in Application Insights](media/app-insights-cargo-reports-traces.png)

Navigate to the `Failures` blade - you can see a collection of exceptions:

![Cargo Tracker Failures in Application Insights](media/app-insights-failures.png)

Click on an exception to see the end-to-end transaction and stack trace in context:

![Cargo Tracker stacktrace in Application Insights](media/app-insights-failure-details.png)

Navigate to the Live Metrics blade - you can see live metrics on screen with low latencies < 1 second:

![Cargo Tracker Live Metrics in Application Insights](media/app-insights-live-metrics.png)

#### Start monitoring Liberty logs in Azure Log Analytics

Get the pod name of each server in your terminal.

```bash
kubectl -n open-liberty get pod 
```

You will get output like the following content. The first three pods are running Open Liberty servers. The last one is running Open Liberty Operator.

```bash
NAME                                      READY   STATUS    RESTARTS   AGE
olo-controller-manager-77cc59655b-2r5qg   1/1     Running   0          2d5h
```

Get the pod name of each server in your terminal.

```bash
kubectl get pod 
```

You will get output like the following content. The first three pods are running Open Liberty servers. The last one is running Open Liberty Operator.

```bash
NAME                                      READY   STATUS    RESTARTS   AGE
cargo-tracker-cluster-7c8d78c459-6s4mh   1/1     Running   0          19m
cargo-tracker-cluster-7c8d78c459-j6q8l   1/1     Running   0          19m
cargo-tracker-cluster-7c8d78c459-lczj5   1/1     Running   0          20m
```

Open the Log Analytics that created in previous steps.

In the Log Analytics landing page, select `Logs` blade and run any of the sample queries supplied below for Open Liberty server logs.

Make sure the quary scope is your aks instance.

Type and run the following Kusto query to see operator logs, replace the `PodName` with the operator pod name displayed above.

```sql
ContainerLogV2 
| where PodName == "olo-controller-manager-77cc59655b-2r5qg"
| project ContainerName, LogMessage, TimeGenerated
| sort by TimeGenerated
| limit 500
```

Type and run the following Kusto query to see Open Liberty server logs, replace the `PodName` with one of Open Liberty server name displayed above.

```sql
ContainerLogV2 
| where PodName == "cargo-tracker-cluster-7c6df94fc7-5rpjd"
| project ContainerName, LogMessage, TimeGenerated
| sort by TimeGenerated
| limit 500
```

You can change the server pod name to query expected server logs.

#### Start monitoring Cargo Tracker logs in Azure Log Analytics

Open the Log Analytics that created in previous steps.

In the Log Analytics page, select `Logs` blade and run any of the sample queries supplied below for Application logs.

Type and run the following Kusto query to obtain failed dependencies:

```sql
AppDependencies 
| where Success == false
| project Target, DependencyType, Name, Data, OperationId, AppRoleInstance
```

Type and run the following Kusto query to obtain `java.time.format.DateTimeParseException` exceptions:

```sql
AppExceptions 
| where ExceptionType == "java.time.format.DateTimeParseException"
| project TimeGenerated, ProblemId, Method, OuterMessage, AppRoleInstance
| sort by TimeGenerated
| limit 100
```

Type and run the following Kusto query to obtain specified failed request:

```sql
AppRequests 
| where  OperationName contains "POST" and ResultCode == "500"
```

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
  + For **Azure region** select an appropriate region. Take note of this region for potential use later.
  + For **Choose the wait time before deleting resources** select an appropriate value for your usage.
  + Leave the remaining values at their default.

5. Click Run workflow.

### Workflow description

The workflow uses the source code behind the [official Azure offer for running Liberty on AKS](https://aka.ms/liberty-aks) by checking it out and invoking it from Azure CLI.

#### Job: preflight

This job is to build Liberty on AKS template into a ZIP file containing the ARM template to invoke.

* Set up environment to build the Liberty on AKS templates
  + Set up JDK 17
  + Set up bicep 0.29.47

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

This job is to deploy PostgreSQL server and configure firewall settings.

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
  + Validate Deploy of Open Liberty Server Cluster Domain offer. Validate the parameters file in the context of the bicep template to be invoked. This will catch some errors before taking the time to start the full deployment. `--template-file` is the mainTemplate.json from solution template ZIP file. `--parameters` is the parameter file created in the last step.
  + Deploy Open Liberty Server Cluster Domain offer. Invoke the mainTemplate.json to deploy resources and configurations. After the deployment completes, you'll get the following result:
    + An Azure Container Registry. It'll store app image in the later steps.
    + An Azure Kubernetes Service with Open Liberty Operator running in `default` namespace.

#### Job: deploy-azure-monitor
  + azure-login. Login Azure.
  + Deploy Log Analytics Workspace. Provision Log Analytics Workspace to store logs for Container Insights and metrics for Application Insights.
  + Enable Container Insights. Enable Azure Monitor in the existing AKS cluster and enable Container Insights.
  + Provision Application Insights. Provision Application Insights to monitor the application. Cargo Tracker will connect to the App Insight in later steps. Application Insights shares the same workspace with Container Insights.

#### Job: deploy-cargo-tracker

This job is to build app, push it to ACR and apply it to Open Liberty server running on AKS.

* Prepare env
  + Set up JDK 1.8。
  + Install jq.
  + Prepare variables. Obtain AKS and ACR resource properties that will be used in later deployment.

* Deploy Cargo Tracker
  + Checkout cargotracker. Checkout source code of cargo tracker from this repository.
  + Build the applications. Set required environment variables and build cargo tracker with Maven.
  + Query version string for deployment verification. Obtain the app version string for later verification.
  + Build an image and upload to ACR. Build cargo tracker into a docker image with docker file locating in [Dockerfile](Dockerfile), and push the image to ACR.
  + Connect to AKS cluster. Connect to AKS cluster to deploy cargo tracker.
  + Apply deployment files. Apply data source configuration in `target/db-secret.yaml`, App Insight configuration in `target/app-insight.yaml` and cargo tracker metadata in `target/openlibertyapplication.yaml`. This will cause cargo tracker deployed to the AKS cluster.
  + Verify pods are ready. Make sure Cargo Tracker is live.
  + Query Application URL. Obtain cargo tracker URL.

* Make REST API calls
  + A HTTP GET request.
  + A HTTP POST request.
  + An datetime format failure request.

* Print app URL. Print the cargo tracker URL to pipeline summary page. Now you'are able to access cargo tracker with the URL from your browser.

## Unit-3 - Automate deployments using AZD
Use following steps to automate deployments using the Azure Developer CLI (azd).

### Prerequisites
1. [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (azd) installed. 
2. Docker installed. You can install Docker by following the instructions [here](https://docs.docker.com/get-docker/).
3. Azure CLI installed. You can install the Azure CLI by following the instructions [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
4. Helm installed. For instructions to install Helm see [Installing Helm](https://helm.sh/docs/intro/install/).

### How to Run

1. Clone the Cargo Tracker repository to your development environment.

   ```bash
   git clone https://github.com/Azure-Samples/cargotracker-liberty-aks.git
   cd cargotracker-liberty-aks
   ```

1. Run the following command to authenticate with Azure using the Azure CLI.
    ```bash
    az login
    ```

1. Run the following command to authenticate with Azure using the Azure Developer CLI (azd). 
    ```bash
    azd auth login
    ```

1. Run the following command to create a new environment using the Azure Developer CLI (azd). It's a good idea to use a disambiguation prefix for your environment name, such as your initials and todays date.

    ```bash
    azd env new gzh0919-cargotracker-liberty-aks
    ```

1. Run the following command to provision the required Azure resources. Input the required parameters when prompted.

   * Be sure to select the correct Azure subscription when prompted.
   * We observe that `westus` region has a higher likelihood of success than `eastus`.

    ```bash
    azd provision
    ```
    
    For `administratorLoginPassword` enter  `Secret123456`.
    
    When the provisioning completes, you'll see a message similar to the following:
    
    ```bash
    SUCCESS: Your application was provisioned in Azure in 27 minutes 59 seconds.
    ```

2. Ensure Docker is running locally. Run the following command to deploy the Cargo Tracker application to Azure Kubernetes Service (AKS) using the Azure Developer CLI (azd).

    ```bash
    azd deploy
    ```

3. Wait for the deployment to complete. Once the deployment is complete, you can access the Cargo Tracker application using the URL provided in the output.

You can now exercise the Cargo Tracker functionality as shown in Appendix 1.

### Clean up

The steps in this section show you how to clean up and deallocte the resources deployed in the previous section.

1. `azd down` 


## Appendix 1 - Exercise Cargo Tracker Functionality

1. On the main page, inspect the date timestamp, it should reflect today's date. For example, **3.2 2024-08-06 17:48:08**.

1. On the main page, select **Administration**.

1. In the left menu, open **Track** in a new window.

   1. Enter **ABC123** and select **Track!**

   1. Observe what the **next expected activity** is.

1. On the main page, select **Administration Interface**, then, in the left navigation column select **Live** in a new window.  This opens a map view.

   1. Mouse over the pins and find the one for **ABC123**.  Take note of the information in the hover window.

1. On the main page, select **Event Logging Interface**.  This opens up in a new, small, window.

1. Drop down the menu and select **ABC123**.  Select **Next**.

1. Select the **Location** using the information in the **next expected activity**.  Select **Next**.

1. Select the **Event Type** using the information in the **next expected activity**.  Select **Next**.

1. Select the **Voyage** using the information in the **next expected activity**.  Select **Next**.

1. Set the **Completion Date** a few days in the future.  Select **Next**.

1. Review the information and verify it matches the **next expected activity**.  If not, go back and fix it.  If so, select **Submit**.

1. Back on the **Public Tracking Interface** select **Tracking** then enter **ABC123** and select **Track**.  Observe that different. **next expected activity** is listed.

1. If desired, go back to **Mobile Event Logger** and continue performing the next activity.

## Appendix 2 - Learn more about Cargo Tracker

See [Eclipse Cargo Tracker - Applied Domain-Driven Design Blueprints for Jakarta EE](https://github.com/eclipse-ee4j/cargotracker/)

## Appendix 3 - Run locally with remote resources without docker

The steps in this section guide you to deploy supporting resources with the GitHub workflow, yet run the cargotracker app locally.

1. Follow the steps in [Unit 2 Automate deployments using GitHub Actions](#unit-2---automate-deployments-using-github-actions), but when you run the workflow, set the value for **Set this value to true to cause the workflow to only deploy required supporting resources** to **true**.

1. Follow the steps in [Unit-1 - Deploy and monitor Cargo Tracker](#unit-1---deploy-and-monitor-cargo-tracker) up to and including **Prepare your variables for deployments**.

   Use the values from the workflow to fill out the values in your `setup-env-variables.sh`.
   
   * `DB_RESOURCE_NAME` must be the name of the database resource, such as `liberty-dbs-1148487969748`. Find this value by entering the resource group in which the workflow deployed the database and selecting the database resource.
   
   * `DB_NAME` must be `libertydb`.
   
   * If using the AI shortest path feature, set the `AZURE_OPENAI` variables as described in Unit 1.
   
   * Leave the remainder of the variables unchanged. They are not used in the "Run locally with remote resources without Docker" scenario.
   
1. Remove the Application Insights agent jar. 

   1. Edit the file `${DIR}/cargotracker/src/main/liberty/config/jvm.options`.
   
      Remove the entire line containing the string `applicationinsights-agent.jar`.
   
      Application Insights is not used in the "Run locally with remote resources without Docker" scenario.
      
      Note that addtional JVM options can be inserted into this file, such as local debugger options `-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005`.
   
1. Wait until the workflow successfully completes the **deploy-db** job before continuing.

1. Enable network access from your local workstation to the database.

   1. Sign in to the Azure portal using the same subscription to which you deployed the database.
   
   1. Find the resource group in which the database has been deployed.
   
   1. Select the database resource. It will be named something like `liberty-dbs-1148487969748`.
   
   1. In the left navigation panel, under **Settings** select **Networking**.
   
   1. Find the text **Add current client IP address**. Select the text and select **Save**. Wait for the save operation to complete.

1. Build the cargotracker.war. The POM substitutes the environment variables for the database connection.

   ```bash
   mvn -PopenLibertyOnAks clean install
   ```
   
1. Run the cargotracker.war. Make sure to run this command in the same shell where the environment variables are defined.

   ```bash
   mvn -PopenLibertyOnAks liberty:run
   ```

1. Your cargotracker will now be running at `http://localhost:9080/cargo-tracker/`.

   1. To exercise the UI, follow the steps in [Appendix 1 - Exercise Cargo Tracker Functionality](#appendix-1---exercise-cargo-tracker-functionality). If you get an unexpected error, wait a few minutes and try again.
   1. To exercise the REST endpoint, including the AI shortest path feature, follow the steps in [Use Cargo Tracker and make a few HTTP calls](#use-cargo-tracker-and-make-a-few-http-calls)
