#!/usr/bin/env bash
# provision.sh - create the lab's Azure resources from labs-config.json.
#
#   bash infra/provision.sh             # PLAN: show what would be created; changes nothing
#   bash infra/provision.sh --execute   # create it
#
# Creates, in order: resource group -> Foundry resource (with project management enabled)
# -> custom subdomain -> project -> each model deployment in the config.
# Safe to rerun: anything that already exists is left alone.
#
# These resources cost money while they exist. Run teardown.sh at the end of every session.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/../lib/config.sh" || exit 1

execute=0; [ "${1:-}" = "--execute" ] && execute=1

sub="$(lab_require .azure.subscription)"      || exit 1
loc="$(lab_require .azure.location)"          || exit 1
rg="$(lab_require .azure.resourceGroup)"      || exit 1
res="$(lab_require .foundry.resourceName)"    || exit 1
proj="$(lab_require .foundry.projectName)"    || exit 1
kind="$(lab_require .foundry.kind)"           || exit 1
sku="$(lab_require .foundry.sku)"             || exit 1
tags="$(jq -r '.azure.tags // {} | to_entries | map("\(.key)=\(.value)") | join(" ")' "$LABS_CONFIG")"

command -v az >/dev/null 2>&1 || { echo "Azure CLI not installed (docs/environment.md)" >&2; exit 1; }
az account show >/dev/null 2>&1 || { echo "Not signed in. Run: az login" >&2; exit 1; }

step() { echo; echo "== $*"; }
run()  { if [ "$execute" -eq 1 ]; then "$@"; else echo "   would run: $*"; fi; }

step "Subscription: $sub"
run az account set --subscription "$sub" || exit 1

step "Resource group: $rg ($loc)"
if az group show --name "$rg" >/dev/null 2>&1; then echo "   exists"
else # shellcheck disable=SC2086
  run az group create --name "$rg" --location "$loc" --tags $tags --output none || exit 1; fi

step "Foundry resource: $res"
if az cognitiveservices account show --name "$res" --resource-group "$rg" >/dev/null 2>&1; then echo "   exists"
else
  # --allow-project-management cannot be turned on after creation
  run az cognitiveservices account create --name "$res" --resource-group "$rg" --kind "$kind" --sku "$sku" \
      --location "$loc" --allow-project-management --output none || exit 1
  run az cognitiveservices account update --name "$res" --resource-group "$rg" --custom-domain "$res" --output none || exit 1
fi

step "Project: $proj"
if az cognitiveservices account project show --name "$res" --resource-group "$rg" --project-name "$proj" >/dev/null 2>&1; then echo "   exists"
else run az cognitiveservices account project create --name "$res" --resource-group "$rg" --project-name "$proj" --location "$loc" --output none || exit 1; fi

n="$(lab_count .deployments.items)"
for ((i = 0; i < n; i++)); do
  d="$(lab_get ".deployments.items[$i].deploymentName")"; ver="$(lab_get ".deployments.items[$i].modelVersion")"
  step "Model deployment: $d"
  case "$ver" in REPLACE*) echo "   skipped: modelVersion not set. Run: bash infra/list-models.sh $(lab_get ".deployments.items[$i].modelName")"; continue;; esac
  if az cognitiveservices account deployment show --name "$res" --resource-group "$rg" --deployment-name "$d" >/dev/null 2>&1; then echo "   exists"; continue; fi
  run az cognitiveservices account deployment create --name "$res" --resource-group "$rg" --deployment-name "$d" \
      --model-name "$(lab_get ".deployments.items[$i].modelName")" --model-version "$ver" \
      --model-format "$(lab_get ".deployments.items[$i].modelFormat")" \
      --sku-name "$(lab_get ".deployments.items[$i].skuName")" --sku-capacity "$(lab_get ".deployments.items[$i].skuCapacity")" --output none || exit 1
done

echo
if [ "$execute" -eq 1 ]; then
  echo "Provisioned. Endpoint and state:  bash infra/status.sh"
  echo "When the session ends:             bash infra/teardown.sh --execute"
else
  echo "Plan only. Nothing was created. Add --execute to create it."
fi
