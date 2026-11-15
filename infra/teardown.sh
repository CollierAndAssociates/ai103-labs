#!/usr/bin/env bash
# teardown.sh - delete everything the lab created, by deleting its resource group.
#
#   bash infra/teardown.sh                     # PLAN: list what would be deleted; changes nothing
#   bash infra/teardown.sh --execute           # delete the resource group (asks you to type its name)
#   bash infra/teardown.sh --execute --purge   # also purge the soft-deleted Foundry resource, so its
#                                              # name can be reused straight away
#
# Nothing of value is lost: provision.sh recreates everything from the config in minutes.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/../lib/config.sh" || exit 1

execute=0; purge=0
for a in "$@"; do case "$a" in --execute) execute=1;; --purge) purge=1;; *) echo "unknown option $a" >&2; exit 2;; esac; done

rg="$(lab_require .azure.resourceGroup)" || exit 1
res="$(lab_require .foundry.resourceName)" || exit 1
loc="$(lab_require .azure.location)" || exit 1

if ! az group show --name "$rg" >/dev/null 2>&1; then echo "Resource group $rg does not exist. Nothing to delete."; exit 0; fi

echo "== Will be deleted: resource group $rg and everything in it"
az resource list --resource-group "$rg" --query '[].{name:name, type:type}' -o table

if [ "$execute" -ne 1 ]; then echo; echo "Plan only. Nothing was deleted. Add --execute to delete."; exit 0; fi

echo; read -r -p "Type the resource group name to confirm: " typed
[ "$typed" = "$rg" ] || { echo "Name did not match. Nothing was deleted."; exit 1; }

az group delete --name "$rg" --yes || exit 1
echo "Deleted $rg."

if [ "$purge" -eq 1 ]; then
  echo "Purging the soft-deleted resource $res ..."
  az cognitiveservices account purge --name "$res" --resource-group "$rg" --location "$loc" && echo "Purged." || echo "Purge failed or nothing to purge; list with: az cognitiveservices account list-deleted"
fi
