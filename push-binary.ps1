# Helper used by each project's publish.ps1 (run from its pre-push hook).
#   push-binary.ps1 sync                                   -> pull this repo before copying a new binary in
#   push-binary.ps1 publish -Project -File -Version -SourceRepo -> update README row, commit, push
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('sync', 'publish')][string]$Action,
    [string]$Project,     # README row label, e.g. "Helios Analytics"
    [string]$File,        # path inside this repo, e.g. Helios/HeliosAnalytics2.zip
    [string]$Version,
    [string]$SourceRepo   # local path of the source repo (for commit hash)
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
# git exports these inside hooks; they would point our git calls at the source repo
foreach ($v in 'GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_PREFIX') { Remove-Item "Env:$v" -ErrorAction SilentlyContinue }

function Run-Git { & git.exe -C $root @args; if ($LASTEXITCODE) { throw "git $($args -join ' ') failed" } }

if ($Action -eq 'sync') {
    Run-Git pull -q --ff-only origin main
    return
}

foreach ($p in 'Project', 'File', 'Version', 'SourceRepo') {
    if (-not (Get-Variable $p -ValueOnly)) { throw "publish: -$p is required" }
}
$hash = (& git.exe -C $SourceRepo rev-parse --short HEAD).Trim()
$date = Get-Date -Format 'yyyy-MM-dd'
$name = Split-Path $File -Leaf
$url = "https://github.com/ZupinM/Downloads/raw/main/$File"
$row = "| $Project | [$name]($url) | $Version | $date | $hash |"

# replace (or append) this file's row in the README tables; rows are matched by download link,
# so the same project name may appear in both the firmware and the bootloader table
$readme = Join-Path $root 'README.md'
$lines = @(Get-Content $readme)
$pattern = '^\|.*\]\(' + [regex]::Escape($url) + '\)'
if ($lines -match $pattern) {
    $lines = $lines | ForEach-Object { if ($_ -match $pattern) { $row } else { $_ } }
} else {
    $last = ($lines | Select-String '^\|' | Select-Object -Last 1).LineNumber
    $lines = $lines[0..($last - 1)] + $row + $lines[$last..($lines.Count - 1)]
}
Set-Content $readme $lines -Encoding utf8

Run-Git add -A
if (-not (& git.exe -C $root status --porcelain)) { Write-Host "push-binary: nothing changed"; return }
Run-Git commit -q -m "$Project $Version ($hash)"
Run-Git push -q origin main
Write-Host "push-binary: $Project $Version published -> $url"
