export DB_RESOURCE_NAME="libertydb1110" # PostgreSQL server name, customize this
export RESOURCE_GROUP_NAME="abc1110rg" # customize this
export LOCATION=eastus # customize this, if desired

export APPINSIGHTS_NAME="appinsights$(date +%s)"
export DB_NAME=${DB_RESOURCE_NAME}
export DB_PASSWORD="Secret123456" # PostgreSQL database password
export DB_PORT_NUMBER=5432
export DB_SERVER_NAME="${DB_RESOURCE_NAME}.postgres.database.azure.com" # PostgreSQL host name
export DB_USER=liberty${DB_RESOURCE_NAME}
export LIBERTY_AKS_REPO_REF="048e776e9efe2ffed8368812e198c1007ba94b2c" # WASdev/azure.liberty.aks
export NAMESPACE=default
export WORKSPACE_NAME="${RESOURCE_GROUP_NAME}ws"
