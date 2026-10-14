# ArtCraft skills installer for Windows (PowerShell).
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.ps1))) -Apps gridcraft,wordcraft"
# Options: -Apps a,b|all  -Mode live|headless|both  -DryRun  -NoLauncher -NoClaudeDesktop -NoClaudeCode -NoSkill  -Local DIR
param(
  [Parameter(Mandatory = $true)][string[]]$Apps,
  [ValidateSet('', 'live', 'headless', 'both')][string]$Mode = '',
  [switch]$DryRun, [switch]$NoLauncher, [switch]$NoClaudeDesktop, [switch]$NoClaudeCode, [switch]$NoSkill,
  [string]$Local = ''
)
$ErrorActionPreference = 'Stop'
if ($Local) {
  $src = (Resolve-Path $Local).Path
} else {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("artcraft-" + [Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  Write-Host 'Downloading ArtCraft skills...'
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  $zip = Join-Path $tmp 'hub.zip'
  Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/Vinciux99/artcraft-claude-skills/archive/refs/heads/main.zip' -OutFile $zip
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $src = Join-Path $tmp 'artcraft-claude-skills-main'
}
$ids = @()
foreach ($a in $Apps) { foreach ($p in ($a -split ',')) { if ($p.Trim()) { $ids += $p.Trim() } } }
if ($ids -contains 'all') { $ids = @(Get-ChildItem (Join-Path $src 'apps') -Directory | ForEach-Object { $_.Name }) }
foreach ($id in $ids) {
  $cfg = Join-Path $src "apps\$id\app.json"
  if (-not (Test-Path $cfg)) { throw "Unknown app: $id" }
  Write-Host ""; Write-Host "=== $id ==="
  $splat = @{ Config = $cfg; SkillDir = (Join-Path $src "plugins\$id\skills\$id") }
  if ($Mode) { $splat.Mode = $Mode }
  if ($DryRun) { $splat.DryRun = $true }
  if ($NoLauncher) { $splat.NoLauncher = $true }
  if ($NoClaudeDesktop) { $splat.NoClaudeDesktop = $true }
  if ($NoClaudeCode) { $splat.NoClaudeCode = $true }
  if ($NoSkill) { $splat.NoSkill = $true }
  & (Join-Path $src 'scripts\artcraft-setup.ps1') @splat
}
Write-Host ""; Write-Host 'Done. Fully quit and reopen Claude, then start each app with its "<App> (Claude)" launcher.'
