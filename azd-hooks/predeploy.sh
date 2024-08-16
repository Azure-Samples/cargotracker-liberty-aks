#!/bin/bash

##########################################################
# Check kubelogin and install if not exists
##########################################################
if ! command -v kubelogin &> /dev/null; then
  echo "kubelogin could not be found. Installing kubelogin..."
  az aks install-cli
fi

##########################################################
# Create the custom-values.yaml file
##########################################################
cat << EOF > custom-values.yaml
appInsightConnectionString: ${AZURE_AKS_NAMESPACE}
loginServer: ${AZURE_REGISTRY_NAME}.azurecr.io
EOF


##########################################################
# DB
##########################################################
cat << EOF >> custom-values.yaml
namespace: ${AZURE_AKS_NAMESPACE}
db:
  ServerName: ${DB_RESOURCE_NAME}
  PortNumber: 5432
  Name: ${DB_NAME}
  User: ${DB_USER_NAME}
  Password: ${DB_USER_PASSWORD}
EOF

