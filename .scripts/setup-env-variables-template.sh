export RESOURCE_GROUP_NAME="abc1110rg" # customize this. Must be unique within your subscription

export APPINSIGHTS_NAME="${RESOURCE_GROUP_NAME}appinsights"
export DB_NAME="libertydb" # PostgreSQL database name
export DB_PASSWORD="Secret123456" # PostgreSQL database password
export DB_PORT_NUMBER=5432
export DB_RESOURCE_NAME="${RESOURCE_GROUP_NAME}db"
export DB_SERVER_NAME="${DB_RESOURCE_NAME}.postgres.database.azure.com" # PostgreSQL host name
export DB_USER=liberty
export LIBERTY_AKS_REPO_REF="e526fd1f313af802a888eb43c18d7e271c35be7c" # WASdev/azure.liberty.aks
export NAMESPACE=default
export WORKSPACE_NAME="${RESOURCE_GROUP_NAME}ws"
