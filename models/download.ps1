# Download the checkpoints listed in checkpoints.yml — PowerShell edition.
# Needs only Windows 10/11 built-ins (PowerShell + curl.exe), no extra tools.
#
# Usage (from the repo root):
#   $env:CIVITAI_API_KEY = "your-key"   # civitai.com > Account Settings > API Keys
#   .\models\download.ps1               # download all five models
#   .\models\download.ps1 janku-v6      # or a single one by id
#
# The model table below mirrors models/checkpoints.yml — keep the two in sync.

param([string]$FilterId = "")

$ErrorActionPreference = "Stop"

$Models = @(
    @{ id = "janku-v6";              model_id = 1277670; version_name = "v6.0";  version_id = 2358314; filename = "janku-v6.safetensors" }
    @{ id = "chenkin-noob-xl-ckxl";  model_id = 2167995; version_name = "v0.5";  version_id = $null;   filename = "chenkin-noob-xl-ckxl-v0.5.safetensors" }
    @{ id = "endlustria-lumica-v3";  model_id = 1981990; version_name = "v3";    version_id = 2243567; filename = "endlustria-lumica-v3.safetensors" }
    @{ id = "perfect-deliberate";    model_id = 24350;   version_name = "v9.0";  version_id = $null;   filename = "perfect-deliberate-v9.safetensors" }
    @{ id = "wai-illustrious-sdxl";  model_id = 827184;  version_name = "v15.0"; version_id = 2167369; filename = "wai-illustrious-sdxl-v15.safetensors" }
)

$ApiKey = $env:CIVITAI_API_KEY
if (-not $ApiKey) {
    $ApiKey = Read-Host "CIVITAI_API_KEY (civitai.com > Account Settings > API Keys)"
}
if (-not $ApiKey) {
    Write-Error "API key is required."
}

$OutDir = Join-Path $PSScriptRoot "checkpoints"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$Headers = @{ Authorization = "Bearer $ApiKey" }
$Failures = 0

foreach ($m in $Models) {
    if ($FilterId -and $m.id -ne $FilterId) { continue }

    $dest = Join-Path $OutDir $m.filename
    if (Test-Path $dest) {
        Write-Host "skip: $($m.id) -> already exists: $dest"
        continue
    }

    Write-Host "resolving: $($m.id) (model $($m.model_id), version '$($m.version_name)')"
    $versionId = $null
    try {
        $info = Invoke-RestMethod -Uri "https://civitai.com/api/v1/models/$($m.model_id)" -Headers $Headers
        $want = $m.version_name.TrimStart("v").ToLower()
        $match = $info.modelVersions | Where-Object { $_.name.TrimStart("v", "V").ToLower() -eq $want } | Select-Object -First 1
        if ($match) { $versionId = $match.id }
    } catch {
        Write-Warning "  API lookup failed: $($_.Exception.Message)"
    }

    if (-not $versionId -and $m.version_id) {
        Write-Host "  name match failed; falling back to pinned version_id $($m.version_id)"
        $versionId = $m.version_id
    }
    if (-not $versionId) {
        Write-Warning "error: could not resolve a version for $($m.id) — check https://civitai.com/models/$($m.model_id)"
        $Failures++
        continue
    }

    $url = "https://civitai.com/api/download/models/$versionId"
    Write-Host "downloading: $($m.id) (version $versionId) -> $dest"
    & curl.exe -L --fail --progress-bar -H "Authorization: Bearer $ApiKey" -o $dest $url
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "error: download failed for $($m.id) ($url)"
        Write-Warning "       (early-access versions may need to be unlocked on the model page first)"
        if (Test-Path $dest) { Remove-Item $dest }
        $Failures++
    }
}

if ($Failures -gt 0) {
    Write-Error "done with $Failures failure(s)"
}
Write-Host "done"
