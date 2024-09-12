# enable Helm support
azd config set alpha.aks.helm on

HELM_REPO_URL="https://azure-javaee.github.io/cargotracker-liberty-aks"
HELM_REPO_NAME="cargotracker-liberty-aks"
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

##########################################################
# Create the custom-values.yaml file
##########################################################
cat << EOF > custom-values.yaml
appInsightConnectionString: ${APP_INSIGHTS_CONNECTION_STRING}
loginServer: ${AZURE_REGISTRY_NAME}
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
