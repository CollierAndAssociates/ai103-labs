#!/usr/bin/env bash
# status.sh - what exists right now, and where to connect. Read-only. Prints no keys.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/../lib/config.sh" || exit 1

rg="$(lab_require .azure.resourceGroup)" || exit 1
res="$(lab_require .foundry.resourceName)" || exit 1
proj="$(lab_require .foundry.projectName)" || exit 1

if ! az group show --name "$rg" >/dev/null 2>&1; then echo "Resource group $rg does not exist. Nothing is running; nothing is being billed."; exit 0; fi

echo "== Resources in $rg (these are being billed)"
az resource list --resource-group "$rg" --query '[].{name:name, type:type, location:location}' -o table

echo; echo "== Foundry resource"
az cognitiveservices account show --name "$res" --resource-group "$rg" \
  --query '{state:properties.provisioningState, endpoint:properties.endpoint}' -o table 2>/dev/null || echo "   not found"

echo; echo "== Project"
az cognitiveservices account project show --name "$res" --resource-group "$rg" --project-name "$proj" \
  --query '{name:name, state:properties.provisioningState}' -o table 2>/dev/null || echo "   not found"

echo; echo "== Model deployments"
az cognitiveservices account deployment list --name "$res" --resource-group "$rg" \
  --query '[].{deployment:name, model:properties.model.name, version:properties.model.version, sku:sku.name, capacity:sku.capacity, state:properties.provisioningState}' -o table 2>/dev/null || echo "   none"

echo; echo "Authenticate with your signed-in identity (az login + DefaultAzureCredential). Keys are deliberately not printed."
