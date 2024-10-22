#!/bin/bash

export GATEWAY_PUBLICIP_ID=$(az network application-gateway list \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --query '[0].frontendIPConfigurations[0].publicIPAddress.id' -o tsv)
export GATEWAY_HOSTNAME=$(az network public-ip show --ids ${GATEWAY_PUBLICIP_ID} --query 'dnsSettings.fqdn' -o tsv)
export CARGO_TRACKER_URL="http://${GATEWAY_HOSTNAME}/cargo-tracker/"
echo "Cargo Tracker URL: ${CARGO_TRACKER_URL}"

if kubectl get deployment cargo-tracker-cluster > /dev/null 2>&1; then
  kubectl rollout restart deployment/cargo-tracker-cluster
fi