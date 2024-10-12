#!/bin/bash

# if folder tmp-build exists, delete the folder
if [ -d "tmp-build" ];
  then rm -rf tmp-build;
fi

export HELM_REPO_URL="https://azure-javaee.github.io/cargotracker-liberty-aks"
export HELM_REPO_NAME="cargotracker-liberty-aks"
export ACR_NAME=$(az acr list  -g ${RESOURCE_GROUP_NAME} --query [0].name -o tsv)
export ACR_SERVER=$(az acr show -n $ACR_NAME -g ${RESOURCE_GROUP_NAME} --query 'loginServer' -o tsv)
export AKS_NAME=$(az aks list -g ${RESOURCE_GROUP_NAME} --query \[0\].name -o tsv)

# enable Helm support
azd config set alpha.aks.helm on

# Check if the repo exists before removing
if helm repo list | grep -q "${HELM_REPO_NAME}"; then
  echo "Removing Repo '${HELM_REPO_NAME}'"
  helm repo remove ${HELM_REPO_NAME}
else
  echo "Repo '${HELM_REPO_NAME}' not found in the list."
fi

helm repo add ${HELM_REPO_NAME} ${HELM_REPO_URL}

az aks enable-addons \
  --addons monitoring \
  --name ${AKS_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --workspace-resource-id ${WORKSPACE_ID}

echo "Provision postgresql server"
az postgres flexible-server create \
   --resource-group ${RESOURCE_GROUP_NAME} \
   --name ${DB_RESOURCE_NAME} \
   --location ${LOCATION} \
   --admin-user ${DB_USER_NAME} \
   --admin-password ${DB_USER_PASSWORD} \
   --version 15 --public-access 0.0.0.0 \
   --tier Burstable  \
   --sku-name Standard_B1ms  \
   --yes

echo "Provision postgresql database"
az postgres flexible-server db create \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --server-name ${DB_RESOURCE_NAME} \
  --database-name ${DB_NAME}

echo "Allow Access to Azure Services"
az postgres flexible-server firewall-rule create \
  -g ${RESOURCE_GROUP_NAME} \
  -n ${DB_RESOURCE_NAME} \
  -r "AllowAllWindowsAzureIps" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "0.0.0.0"

az postgres flexible-server parameter set --name max_prepared_transactions --value 10 -g ${RESOURCE_GROUP_NAME} --server-name ${DB_RESOURCE_NAME}
az postgres flexible-server restart -g ${RESOURCE_GROUP_NAME} --name ${DB_RESOURCE_NAME}

run_maven_command() {
    mvn -q -Dexec.executable=echo -Dexec.args="$1" --non-recursive exec:exec 2>/dev/null | sed -e 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n'
}

IMAGE_NAME=$(run_maven_command '${project.artifactId}')
IMAGE_VERSION=$(run_maven_command '${project.version}')

##########################################################
# Create the custom-values.yaml file
##########################################################
cat << EOF > custom-values.yaml
appInsightConnectionString: ${APP_INSIGHTS_CONNECTION_STRING}
loginServer: ${ACR_SERVER}
imageName: ${IMAGE_NAME}
imageTag: ${IMAGE_VERSION}
azureOpenAIKey: ${AZURE_OPENAI_KEY}
azureOpenAIEndpoint: ${AZURE_OPENAI_ENDPOINT}
azureOpenAIDeploymentName: ${AZURE_OPENAI_MODEL_NAME}

EOF

##########################################################
# DB
##########################################################
cat << EOF >> custom-values.yaml
namespace: ${AZURE_AKS_NAMESPACE}
db:
  ServerName: ${DB_RESOURCE_NAME}.postgres.database.azure.com
  PortNumber: 5432
  Name: ${DB_NAME}
  User: ${DB_USER_NAME}
  Password: ${DB_USER_PASSWORD}
EOF
