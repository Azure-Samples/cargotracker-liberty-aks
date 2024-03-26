#!/usr/bin/env bash
################################################
# This script is invoked by a human who:
# - has invoked the setup.sh script
#
# This script removes the secrets and deletes the azure resources created in
# setup.sh.
#
# Script design taken from https://github.com/microsoft/NubesGen.
#
################################################


set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

setup_colors

read -r -p "Enter disambiguation prefix: " DISAMBIG_PREFIX
read -r -p "Enter owner/reponame (blank for upsteam of current fork): " OWNER_REPONAME

if [ -z "${OWNER_REPONAME}" ] ; then
    GH_FLAGS=""
else
    GH_FLAGS="--repo ${OWNER_REPONAME}"
fi

SERVICE_PRINCIPAL_NAME=${DISAMBIG_PREFIX}sp

# Execute commands
msg "${GREEN}(1/3) Delete service principal ${SERVICE_PRINCIPAL_NAME}"
SUBSCRIPTION_ID=$(az account show --query id --output tsv --only-show-errors)
SP_OBJECT_ID_ARRAY=$(az ad sp list --display-name ${SERVICE_PRINCIPAL_NAME} --query "\[\].appId") || true
# remove whitespace
SP_OBJECT_ID_ARRAY=$(echo ${SP_OBJECT_ID_ARRAY} | xargs) || true
SP_OBJECT_ID_ARRAY=${SP_OBJECT_ID_ARRAY//[/}
SP_OBJECT_ID=${SP_OBJECT_ID_ARRAY//]/}
az ad sp delete --id ${SP_OBJECT_ID} || true

# Check GitHub CLI status
msg "${GREEN}(2/3) Checking GitHub CLI status...${NOFORMAT}"
USE_GITHUB_CLI=false
{
  gh auth status && USE_GITHUB_CLI=true && msg "${YELLOW}GitHub CLI is installed and configured!"
} || {
  msg "${YELLOW}Cannot use the GitHub CLI. ${GREEN}No worries! ${YELLOW}We'll set up the GitHub secrets manually."
  USE_GITHUB_CLI=false
}

msg "${GREEN}(3/3) Removing secrets...${NOFORMAT}"
if $USE_GITHUB_CLI; then
  {
    msg "${GREEN}Using the GitHub CLI to remove secrets.${NOFORMAT}"
    gh ${GH_FLAGS} secret remove AZURE_CREDENTIALS
    gh ${GH_FLAGS} secret remove DB_PASSWORD
  } || {
    USE_GITHUB_CLI=false
  }
fi
if [ $USE_GITHUB_CLI == false ]; then
  msg "${NOFORMAT}======================MANUAL REMOVAL======================================"
  msg "${GREEN}Using your Web browser to remove secrets..."
  msg "${NOFORMAT}Go to the GitHub repository you want to configure."
  msg "${NOFORMAT}In the \"settings\", go to the \"secrets\" tab and remove the following secrets:"
  msg "(in ${YELLOW}yellow the secret name)"
  msg "${YELLOW}\"AZURE_CREDENTIALS\""
  msg "${YELLOW}\"DB_PASSWORD\""
  msg "${NOFORMAT}========================================================================"
fi
msg "${GREEN}Secrets removed"
