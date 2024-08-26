# enable Helm support
azd config set alpha.aks.helm on

# Build image and upload to ACR
echo "AKS_NAME: $AKS_NAME"
echo "RESOURCE_GROUP_NAME $RESOURCE_GROUP_NAME"
echo "WORKSPACE_ID: $WORKSPACE_ID"

export AKS_NAME=$(az aks list -g ${RESOURCE_GROUP_NAME} --query \[0\].name -o tsv)

az aks enable-addons \
  --addons monitoring \
  --name ${AKS_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --workspace-resource-id ${WORKSPACE_ID}


echo "get image name and version"

run_maven_command() {
    mvn -q -Dexec.executable=echo -Dexec.args="$1" --non-recursive exec:exec 2>/dev/null | sed -e 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n'
}

IMAGE_NAME=$(run_maven_command '${project.artifactId}')
IMAGE_VERSION=$(run_maven_command '${project.version}')

echo "build image and upload"

mvn clean package -DskipTests
cd target
echo "docker build"
docker build -t ${IMAGE_NAME}:${IMAGE_VERSION} --pull --file=Dockerfile .
docker tag ${IMAGE_NAME}:${IMAGE_VERSION} ${ACRServer}/${IMAGE_NAME}:${IMAGE_VERSION}
docker login -u ${ACRUserName} -p ${ACRPassword} ${ACRServer}

echo "docker push to ACR Server ${ACRServer} with image name ${IMAGE_NAME} and version ${IMAGE_VERSION}"

docker push ${ACRServer}/${IMAGE_NAME}:${IMAGE_VERSION}

echo "provision postgresql"
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
