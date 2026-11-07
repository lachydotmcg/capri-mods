$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$sandbox=Join-Path $root ('validation\install-fixture-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$game=Join-Path $sandbox 'game'
$capri=Join-Path $sandbox 'capri'
New-Item -ItemType Directory -Path $game,$capri -Force | Out-Null
$unrelated=Join-Path $game 'untouched.txt'
Set-Content -LiteralPath $unrelated -Value 'Keep this file.'
$hash=(Get-FileHash -LiteralPath $unrelated).Hash
& "$root\Install.ps1" -GameRoot $game -CapriData $capri -Fixture | Out-Null
$deploy=Get-ChildItem -LiteralPath (Join-Path $game 'CapriNightCity-backups') -Filter deployment.json -Recurse | Select-Object -First 1
$manifest=Get-Content -LiteralPath $deploy.FullName -Raw | ConvertFrom-Json
if ($manifest.files.Count -ne 8) { throw 'Expected exactly eight installed files.' }
foreach ($entry in $manifest.files) { if ((Get-FileHash -LiteralPath $entry.path).Hash -ne $entry.sha256) { throw 'Fixture hash mismatch.' } }
$target=Join-Path $game 'bin\x64\plugins\cyber_engine_tweaks\mods\CapriNightCityBridge\init.lua'
Add-Content -LiteralPath $target -Value '-- User edit'
$refused=$false
try { & "$root\Uninstall.ps1" -Deployment $deploy.FullName -Fixture | Out-Null } catch { $refused=$true }
if (-not $refused) { throw 'Modified file rollback was not refused.' }
Copy-Item -LiteralPath "$root\CapriNightCityBridge\init.lua" -Destination $target -Force
& "$root\Uninstall.ps1" -Deployment $deploy.FullName -Fixture | Out-Null
if (Test-Path -LiteralPath $target) { throw 'Fixture uninstall left installed script.' }
if ((Get-FileHash -LiteralPath $unrelated).Hash -ne $hash) { throw 'Unrelated file changed.' }
# Update path restores an original file and preserves pre-existing settings/config.
New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
Set-Content -LiteralPath $target -Value '-- Original custom bridge'
$original=(Get-FileHash -LiteralPath $target).Hash
Start-Sleep -Milliseconds 20
& "$root\Install.ps1" -GameRoot $game -CapriData $capri -Fixture | Out-Null
$latest=Get-ChildItem -LiteralPath (Join-Path $game 'CapriNightCity-backups') -Filter deployment.json -Recurse | Sort-Object FullName -Descending | Select-Object -First 1
& "$root\Uninstall.ps1" -Deployment $latest.FullName -Fixture | Out-Null
if ((Get-FileHash -LiteralPath $target).Hash -ne $original) { throw 'Original bridge was not restored.' }
Write-Output 'PASS installer fixtures: exact files/hashes, modified-file refusal, guarded removal, backup restore and unrelated file preservation.'
