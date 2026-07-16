#!/usr/bin/env bash
# Download checkpoints listed in models/checkpoints.yml into models/checkpoints/.
#
# Run this on a machine that actually has network access to civitai.com /
# huggingface.co (this repo's sandboxed dev environment may not).
#
# Env vars:
#   CIVITAI_API_KEY  - required for civitai entries (Account Settings > API Keys)
#   HF_TOKEN         - required only for gated/private huggingface entries
#
# Usage:
#   models/download.sh            # download every entry that has a URL set
#   models/download.sh janku-v6   # download a single entry by id

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YML="$SCRIPT_DIR/checkpoints.yml"
OUT_DIR="$SCRIPT_DIR/checkpoints"
FILTER_ID="${1:-}"

mkdir -p "$OUT_DIR"

command -v yq >/dev/null 2>&1 || {
  echo "error: 'yq' is required (https://github.com/mikefarah/yq)" >&2
  exit 1
}

count=$(yq '.models | length' "$YML")

for i in $(seq 0 $((count - 1))); do
  id=$(yq -r ".models[$i].id" "$YML")
  [[ -n "$FILTER_ID" && "$id" != "$FILTER_ID" ]] && continue

  name=$(yq -r ".models[$i].name" "$YML")
  platform=$(yq -r ".models[$i].source.platform" "$YML")
  url=$(yq -r ".models[$i].source.url" "$YML")
  model_id=$(yq -r ".models[$i].source.model_id" "$YML")
  version_id=$(yq -r ".models[$i].source.version_id" "$YML")
  filename=$(yq -r ".models[$i].filename" "$YML")
  dest="$OUT_DIR/$filename"

  if [[ -f "$dest" ]]; then
    echo "skip: $name -> $dest already exists"
    continue
  fi

  if [[ "$url" == "null" || -z "$url" ]]; then
    if [[ "$platform" == "civitai" && "$version_id" != "null" && -n "$version_id" ]]; then
      url="https://civitai.com/api/download/models/${version_id}"
    else
      echo "skip: $name -> no source.url (and no version_id) set in checkpoints.yml yet" >&2
      continue
    fi
  fi

  echo "downloading: $name -> $dest"
  case "$platform" in
    civitai)
      : "${CIVITAI_API_KEY:?CIVITAI_API_KEY env var is required for civitai downloads}"
      curl -L --fail --progress-bar \
        -H "Authorization: Bearer ${CIVITAI_API_KEY}" \
        -o "$dest" "$url"
      ;;
    huggingface)
      auth_header=()
      [[ -n "${HF_TOKEN:-}" ]] && auth_header=(-H "Authorization: Bearer ${HF_TOKEN}")
      curl -L --fail --progress-bar "${auth_header[@]}" -o "$dest" "$url"
      ;;
    *)
      echo "error: unknown platform '$platform' for $name" >&2
      rm -f "$dest"
      continue
      ;;
  esac
done
