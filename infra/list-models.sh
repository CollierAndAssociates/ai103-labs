#!/usr/bin/env bash
# list-models.sh - show the versions and deployment types available for a model in the
# configured region. Read-only. Use the output to fill in modelVersion and skuName.
#
#   bash infra/list-models.sh gpt-5        # every model whose name contains "gpt-5"
set -uo pipefail
. "$(dirname "$(readlink -f "$0")")/../lib/config.sh" || exit 1

filter="${1:-}"; [ -n "$filter" ] || { echo "usage: list-models.sh <part of a model name>" >&2; exit 2; }
loc="$(lab_require .azure.location)" || exit 1

echo "Models matching '$filter' in $loc:"
az cognitiveservices model list --location "$loc" -o json |
  jq -r --arg f "$filter" '
    [ .[] | select((.model.name // "") | test($f; "i"))
      | { name: .model.name, version: .model.version, format: .model.format, skus: ([.model.skus[]?.name] | unique | join(",")) } ]
    | unique | sort_by(.name, .version)
    | (["NAME","VERSION","FORMAT","DEPLOYMENT TYPES"] | @tsv), (.[] | [.name, .version, .format, .skus] | @tsv)' |
  awk -F'\t' '{printf "  %-28s %-14s %-10s %s\n", $1, $2, $3, $4}'
