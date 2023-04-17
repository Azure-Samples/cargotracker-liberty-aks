export LIBERTY_AKS_REPO_REF="964f6463d6cfda9572d215cdd53109cee8f4ff1e" # WASdev/azure.liberty.aks
export RESOURCE_GROUP_NAME="abc1110rg" # customize this
export DB_SERVER_NAME="libertydb$(date +%s)" # PostgreSQL server name
export DB_PASSWORD="Secret123456" # PostgreSQL database password
export DB_PORT_NUMBER=5432
export DB_NAME=postgres
export DB_USER=liberty@${DB_SERVER_NAME}
export NAMESPACE=default
