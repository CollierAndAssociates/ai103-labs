#!/usr/bin/env bash
# lib/config.sh - load labs-config.json. Source this file; do not execute it.
#
# Config lookup order: the LABS_CONFIG environment variable, then labs-config.json in the
# repository root. labs-config.json is git-ignored; start from labs-config.example.json.
#
# After sourcing: LABS_CONFIG, LAB_ROOT, and the helpers lab_get, lab_require, lab_count.

_lab_fail() { echo "config: $*" >&2; }

command -v jq >/dev/null 2>&1 || { _lab_fail "jq is required: sudo apt-get install -y jq"; return 1 2>/dev/null || exit 1; }

LAB_ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
LABS_CONFIG="${LABS_CONFIG:-$LAB_ROOT/labs-config.json}"
if [ ! -f "$LABS_CONFIG" ]; then
  _lab_fail "not found: $LABS_CONFIG"
  _lab_fail "create it:  cp labs-config.example.json labs-config.json   then replace every REPLACE value"
  return 1 2>/dev/null || exit 1
fi
jq -e . "$LABS_CONFIG" >/dev/null 2>&1 || { _lab_fail "$LABS_CONFIG is not valid JSON"; return 1 2>/dev/null || exit 1; }

# lab_get <jq path> -> value; fails when the key is absent
lab_get() {
  local v
  v="$(jq -r "$1 | if . == null then empty else tostring end" "$LABS_CONFIG" 2>/dev/null)"
  [ -n "$v" ] || { _lab_fail "missing key $1 in $LABS_CONFIG"; return 1; }
  printf '%s' "$v"
}
# lab_require <jq path> -> value; also fails when the value is still a REPLACE placeholder
lab_require() {
  local v; v="$(lab_get "$1")" || return 1
  case "$v" in REPLACE*) _lab_fail "$1 is still a placeholder ($v). Edit $LABS_CONFIG"; return 1;; esac
  printf '%s' "$v"
}
lab_count() { jq -r "$1 | length" "$LABS_CONFIG"; }

export LABS_CONFIG LAB_ROOT
