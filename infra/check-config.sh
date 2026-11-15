#!/usr/bin/env bash
# check-config.sh - validate labs-config.json and show the Azure sign-in state. Read-only.
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/../lib/config.sh" || exit 1

rc=0
echo "Config : $LABS_CONFIG (valid JSON)"
for key in .azure.subscription .azure.location .azure.resourceGroup .foundry.resourceName .foundry.projectName .foundry.kind .foundry.sku; do
  if v="$(lab_require "$key" 2>/dev/null)"; then printf '  %-24s %s\n' "$key" "$v"
  else printf '  %-24s %s\n' "$key" "** not set **"; rc=1; fi
done

n="$(lab_count .deployments.items)"
echo; echo "Deployments: $n"
for ((i = 0; i < n; i++)); do
  ver="$(lab_get ".deployments.items[$i].modelVersion")"
  state="ready"; case "$ver" in REPLACE*) state="SKIPPED until a version is set";; esac
  printf '  %-20s %-14s %-16s %s\n' "$(lab_get ".deployments.items[$i].deploymentName")" "$(lab_get ".deployments.items[$i].skuName")" "$ver" "[$state]"
done

echo
if ! command -v az >/dev/null 2>&1; then echo "Azure CLI: not installed (see docs/environment.md)"; rc=1
elif acct="$(az account show --query '[name, user.name]' -o tsv 2>/dev/null)"; then echo "Azure CLI: signed in -> $(echo "$acct" | tr '\n' ' ')"
else echo "Azure CLI: not signed in. Run: az login"; rc=1; fi

[ $rc -eq 0 ] && echo "Config is complete." || echo "Config is incomplete; fix the items marked above."
exit $rc
