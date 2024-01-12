#!/bin/bash
# Script to assemble ansible inventory files from terraform output

set -e 

output=$(terraform output -json)

# Verify that output is not empty
if [ $(echo $output | jq length) -gt 0 ]; then
    full_inventory=$(echo $output | jq '.[].value | select(.inventory) | .inventory' -r)
    echo "$full_inventory"
else
    echo "::error title=INV_EMPTY::Inventory is empty"
    exit 1
fi