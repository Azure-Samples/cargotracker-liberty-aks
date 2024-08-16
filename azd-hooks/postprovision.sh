# enable Helm support
azd config set alpha.aks.helm on

# Build image and upload to ACR
echo "AKS_NAME: $AKS_NAME"
echo "RESOURCE_GROUP_NAME $RESOURCE_GROUP_NAME"
ehco "WORKSPACE_ID: $WORKSPACE_ID"

export AKS_NAME=$(az aks list -g ${RESOURCE_GROUP_NAME} --query \[0\].name -o tsv)

az aks enable-addons \
  --addons monitoring \
  --name ${AKS_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --workspace-resource-id ${WORKSPACE_ID}


echo "get image name and version"

IMAGE_NAME=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.artifactId}' --non-recursive exec:exec)
IMAGE_VERSION=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.version}' --non-recursive exec:exec)

echo "build image and upload"

mvn clean package -DskipTests
cd target
az acr build --registry ${AZURE_REGISTRY_NAME} --image ${IMAGE_NAME}:${IMAGE_VERSION} .


az postgres flexible-server create \
   --resource-group ${RESOURCE_GROUP_NAME} \
   --name ${DB_RESOURCE_NAME} \
   --location ${LOCATION} \
   --admin-user ${DB_USER_NAME} \
   --admin-password ${DB_USER_PASSWORD} \
   --version 15 --public-access 0.0.0.0
   --tier Burstable --sku-name Standard_B1ms --yes

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

## echo
echo RESOURCE_GROUP_NAME: $RESOURCE_GROUP_NAME
echo WORKSPACE_ID: $WORKSPACE_ID
echo AZURE_REGISTRY_NAME: $AZURE_REGISTRY_NAME