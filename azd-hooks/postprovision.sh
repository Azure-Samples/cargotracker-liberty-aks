HELM_REPO_URL="https://azure-javaee.github.io/cargotracker-liberty-aks"
HELM_REPO_NAME="cargotracker-liberty-aks"
AZURE_OPENAI_MODEL_NAME="gpt-4o"
AZURE_OPENAI_MODEL_VERSION="2024-08-06"

# enable Helm support
azd config set alpha.aks.helm on

echo "Create Helm repository"
# Check if the repo exists before removing
if helm repo list | grep -q "${HELM_REPO_NAME}"; then
  helm repo remove ${HELM_REPO_NAME}
  echo "Repo '${HELM_REPO_NAME}' removed."
else
  echo "Repo '${HELM_REPO_NAME}' not found in the list."
fi

helm repo add ${HELM_REPO_NAME} ${HELM_REPO_URL}


export AKS_NAME=$(az aks list -g ${RESOURCE_GROUP_NAME} --query \[0\].name -o tsv)

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

az cognitiveservices account create \
    --name ${AZURE_OPENAI_NAME} \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --location ${LOCATION} \
    --kind OpenAI \
    --custom-domain $AZURE_OPENAI_NAME \
    --sku s0

resourceId=$(az cognitiveservices account show \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --name ${AZURE_OPENAI_NAME} \
    --query id --output tsv | tr -d '\r')

az resource update \
    --ids ${resourceId} \
    --set properties.networkAcls="{'defaultAction':'Allow', 'ipRules':[],'virtualNetworkRules':[]}"

az cognitiveservices account deployment create \
    --name ${AZURE_OPENAI_NAME} \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --deployment-name ${AZURE_OPENAI_MODEL_NAME} \
    --model-name ${AZURE_OPENAI_MODEL_NAME} \
    --model-version ${AZURE_OPENAI_MODEL_VERSION} \
    --model-format OpenAI \
    --sku Standard \
    --capacity 10

AZURE_OPENAI_KEY=$(az cognitiveservices account keys list \
    --name ${AZURE_OPENAI_NAME} \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --query key1 \
    --output tsv)

AZURE_OPENAI_ENDPOINT=$(az cognitiveservices account keys list \
    --name ${AZURE_OPENAI_NAME} \
    --resource-group ${RESOURCE_GROUP_NAME} \
    --query properties.endpoint \
    --output tsv)

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
loginServer: ${AZURE_REGISTRY_NAME}
imageName: ${IMAGE_NAME}
imageTag: ${IMAGE_VERSION}
azureOpenAIKey: ${AZURE_OPENAI_KEY}
azureOpenAIEndpoint: ${AZURE_OPENAI_ENDPOINT}

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
