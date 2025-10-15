#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# ------------------------------
# Required ENV vars
# ------------------------------
: "${RANCHER_URL:?Set RANCHER_URL like https://rancher.example.com}"
: "${TOKEN:?Set TOKEN for API access}"

# ------------------------------
# Input folder (role JSON files)
# ------------------------------
ROLES_DIR="roles"

# ------------------------------
# Function: create or ignore existing RoleTemplate
# ------------------------------
ensure_roletemplate() {
  local file="$1"
  local name
  name=$(jq -r '.name' "$file")

  if [[ -z "$name" || "$name" == "null" ]]; then
    echo "Skipping $file — missing or invalid .name field"
    return 0
  fi

  echo "Processing role template: ${name}"

  local existing
  existing=$(curl -sS -k -H "Authorization: Bearer ${TOKEN}" \
    "${RANCHER_URL}/v3/roletemplates?name=${name}" | jq -r '.data | length')

  if [[ "$existing" -eq 0 ]]; then
    echo "Creating ${name}"
    curl -sS -k -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -X POST "${RANCHER_URL}/v3/roletemplates" \
      -d @"$file" | jq '.id,.name'
  else
    echo "RoleTemplate ${name} already exists — skipping (no update)."
  fi
}

# ------------------------------
# Main loop
# ------------------------------
files=("${ROLES_DIR}"/*.json)
if [ ${#files[@]} -eq 0 ]; then
  echo " No JSON files found in ${ROLES_DIR}. Nothing to do."
  exit 0
fi

for f in "${files[@]}"; do
  ensure_roletemplate "$f"
done
