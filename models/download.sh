#!/usr/bin/env bash
# Download checkpoints listed in models/checkpoints.yml into models/checkpoints/.
#
# Run this on a machine that actually has network access to civitai.com
# (this repo's sandboxed dev environment does not).
#
# Version resolution order per model:
#   1. Query the Civitai API for model_id and match version_name exactly
#      (case-insensitive, ignoring a leading "v").
#   2. Fall back to the pinned version_id from checkpoints.yml.
#
# Env vars:
#   CIVITAI_API_KEY  - required (civitai.com > Account Settings > API Keys)
#
# Usage:
#   models/download.sh            # download every model
#   models/download.sh janku-v6   # download a single entry by id

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YML="$SCRIPT_DIR/checkpoints.yml"
OUT_DIR="$SCRIPT_DIR/checkpoints"
FILTER_ID="${1:-}"

mkdir -p "$OUT_DIR"

for tool in yq jq curl; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "error: '$tool' is required" >&2
    exit 1
  }
done

: "${CIVITAI_API_KEY:?CIVITAI_API_KEY env var is required (civitai.com > Account Settings > API Keys)}"

resolve_version_id() {
  # $1=model_id  $2=version_name  -> echoes version id, or nothing on failure
  local model_id="$1" version_name="$2"
  curl -sL --fail -H "Authorization: Bearer ${CIVITAI_API_KEY}" \
    "https://civitai.com/api/v1/models/${model_id}" |
    jq -r --arg name "$version_name" '
      .modelVersions[]
      | select((.name | ascii_downcase | ltrimstr("v"))
               == ($name | ascii_downcase | ltrimstr("v")))
      | .id' | head -n1
}

count=$(yq '.models | length' "$YML")
failures=0

for i in $(seq 0 $((count - 1))); do
  id=$(yq -r ".models[$i].id" "$YML")
  [[ -n "$FILTER_ID" && "$id" != "$FILTER_ID" ]] && continue

  name=$(yq -r ".models[$i].name" "$YML")
  model_id=$(yq -r ".models[$i].source.model_id" "$YML")
  version_name=$(yq -r ".models[$i].source.version_name" "$YML")
  pinned_version_id=$(yq -r ".models[$i].source.version_id" "$YML")
  filename=$(yq -r ".models[$i].filename" "$YML")
  dest="$OUT_DIR/$filename"

  if [[ -f "$dest" ]]; then
    echo "skip: $name -> $dest already exists"
    continue
  fi

  echo "resolving: $name (model $model_id, version '$version_name')"
  version_id=$(resolve_version_id "$model_id" "$version_name" || true)

  if [[ -z "$version_id" && "$pinned_version_id" != "null" && -n "$pinned_version_id" ]]; then
    echo "  API name match failed; falling back to pinned version_id $pinned_version_id"
    version_id="$pinned_version_id"
  fi

  if [[ -z "$version_id" ]]; then
    echo "error: could not resolve a version for $name — check version_name on $(yq -r ".models[$i].source.page" "$YML")" >&2
    failures=$((failures + 1))
    continue
  fi

  url="https://civitai.com/api/download/models/${version_id}"
  echo "downloading: $name (version $version_id) -> $dest"
  if ! curl -L --fail --progress-bar \
      -H "Authorization: Bearer ${CIVITAI_API_KEY}" \
      -o "$dest" "$url"; then
    echo "error: download failed for $name ($url)" >&2
    echo "       (early-access versions may require purchasing on the model page first)" >&2
    rm -f "$dest"
    failures=$((failures + 1))
  fi
done

if [[ "$failures" -gt 0 ]]; then
  echo "done with $failures failure(s)" >&2
  exit 1
fi
echo "done"
