#!/usr/bin/env bash

set -Eeuo pipefail

CURRENT_FILE_NAME="credentials-params-teardown.sh"
echo "Execute $CURRENT_FILE_NAME - Start------------------------------------------"

# remove param the json
yq eval -o=json '.[]' "$param_file" | jq -c '.' | while read -r line; do
    name=$(echo "$line" | jq -r '.name')
    value=$(echo "$line" | jq -r '.value')
    gh secret remove "$name"
done

echo "Execute $CURRENT_FILE_NAME - End--------------------------------------------"
