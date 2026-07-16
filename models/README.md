# Checkpoint models

`checkpoints.yml` tracks the SDXL/Illustrious-family checkpoints evaluated for
this project, along with recommended settings and why each one was picked.
Weight files themselves are **not** stored in git (see `.gitignore`) — they're
multi-GB binaries that belong on disk / in your SD tool's model folder, not in
version control.

## Why there's no committed download yet

This repo's sandboxed dev environment blocks outbound access to
`civitai.com` and `huggingface.co` by network policy, so the actual
`.safetensors` files can't be fetched from here. `download.sh` is meant to be
run on a machine that does have access (your local ComfyUI/A1111 box, etc).

## Filling in the missing URLs

Every entry in `checkpoints.yml` currently has `source.url: null` as a
placeholder. For each model:

1. Find its page on Civitai (or HuggingFace).
2. Either copy the direct file download link into `source.url`, or grab the
   numeric `modelId`/`versionId` from the URL and set `source.model_id` /
   `source.version_id` (for Civitai, `download.sh` can build the URL from
   `version_id` alone).

## Running the download

```bash
export CIVITAI_API_KEY=...   # Account Settings > API Keys on civitai.com
models/download.sh           # fetch every model with a URL/version_id set
models/download.sh janku-v6  # or just one, by id
```

Files land in `models/checkpoints/<filename>`, matching each entry's
`filename` field in `checkpoints.yml`.
