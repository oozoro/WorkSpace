# Checkpoint models

`checkpoints.yml` tracks the SDXL/Illustrious-family checkpoints evaluated for
this project, along with recommended settings and why each one was picked.
Weight files themselves are **not** stored in git (see `.gitignore`) — they're
multi-GB binaries that belong on disk / in your SD tool's model folder, not in
version control.

All five models were located on Civitai and their numeric `model_id`s are
filled in. The download script resolves the exact file at run time by asking
the Civitai API for the version whose name matches `version_name`, so it stays
correct even if Civitai's internal version ids change.

## Why the download has to run locally

This repo's sandboxed dev environment blocks outbound access to
`civitai.com` by network policy, so the actual `.safetensors` files can't be
fetched from here. Run `download.sh` on the machine where ComfyUI/A1111
lives.

## Running the download

Requires `curl`, `jq`, and `yq` (https://github.com/mikefarah/yq).

```bash
export CIVITAI_API_KEY=...   # civitai.com > Account Settings > API Keys
models/download.sh           # fetch all five models
models/download.sh janku-v6  # or just one, by id
```

Files land in `models/checkpoints/<filename>`, matching each entry's
`filename` field in `checkpoints.yml`. Point your SD tool's model folder at
that directory, or symlink the files into it.

## Notes

- **JANKU v6.0** is (or was) distributed via Civitai early access; if the
  download returns 401/403, the version may still need to be unlocked with
  Buzz on the model page first.
- Filenames in `checkpoints.yml` are stable local names chosen for this
  project; they intentionally differ from Civitai's original file names.
