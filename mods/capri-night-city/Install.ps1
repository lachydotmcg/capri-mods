param(
    [Parameter(Mandatory=$true)][string]$GameRoot,
    [string]$CapriData=(Join-Path $env:LOCALAPPDATA 'Capri'),
    [switch]$Fixture,
    [switch]$StageForRestart
)
$ErrorActionPreference='Stop'
$GameRoot=[IO.Path]::GetFullPath($GameRoot)
$CapriData=[IO.Path]::GetFullPath($CapriData)
if (-not $Fixture) {
    if (-not (Test-Path -LiteralPath (Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'))) { throw 'Cyberpunk2077.exe not found at selected game root.' }
    if (-not (Test-Path -LiteralPath (Join-Path $GameRoot 'bin\x64\plugins\cyber_engine_tweaks.asi'))) { throw 'Cyber Engine Tweaks is required.' }
    if ((Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue) -and -not $StageForRestart) { throw 'Close Cyberpunk before installing the bridge, or use StageForRestart to update files for the next launch.' }
}
$payload=$PSScriptRoot
$gameMod=Join-Path $GameRoot 'bin\x64\plugins\cyber_engine_tweaks\mods\CapriNightCityBridge'
$capriMod=Join-Path $CapriData 'mods\capri-night-city.capri-code'
$capriConfig=Join-Path $CapriData 'mods\capri-night-city-data\game-folder.txt'
$deployRoot=Join-Path $GameRoot 'CapriNightCity-backups'
$deployment=Join-Path $deployRoot (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
New-Item -ItemType Directory -Path $deployment -Force | Out-Null
$entries=@()
foreach ($pair in @(
    @((Join-Path $payload 'CapriNightCityBridge\core.lua'),(Join-Path $gameMod 'core.lua')),
    @((Join-Path $payload 'CapriNightCityBridge\init.lua'),(Join-Path $gameMod 'init.lua')),
    @((Join-Path $payload 'CapriNightCityBridge\targets.lua'),(Join-Path $gameMod 'targets.lua')),
    @((Join-Path $payload 'CapriNightCityBridge\counter.lua'),(Join-Path $gameMod 'counter.lua')),
    @((Join-Path $payload 'CapriNightCityBridge\programs.lua'),(Join-Path $gameMod 'programs.lua')),
    @((Join-Path $payload 'CapriNightCityBridge\settings.json'),(Join-Path $gameMod 'settings.json')),
    @((Join-Path $payload 'capri-night-city.capri-code'),$capriMod)
)) {
    $source=$pair[0]; $target=[IO.Path]::GetFullPath($pair[1])
    $allowed=($target.StartsWith($gameMod+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or $target -eq $capriMod)
    if (-not $allowed) { throw "Unexpected destination: $target" }
    # Never replace a user's tuning during an update.
    if ((Split-Path $target -Leaf) -eq 'settings.json' -and (Test-Path -LiteralPath $target)) { continue }
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing payload file: $source" }
    New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
    $backup=$null
    if (Test-Path -LiteralPath $target) {
        $backup=Join-Path $deployment ('backup-'+$entries.Count+'.bin')
        Copy-Item -LiteralPath $target -Destination $backup
    }
    $backupHash=if($backup) { (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash } else { $null }
    $entry=[pscustomobject]@{path=$target;backup=$backup;backupSha256=$backupHash;sha256=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash}
    $entries+=$entry
    # Persist intent before each write so a partial installation is still reversible.
    [pscustomobject]@{version='1.9.3';gameRoot=$GameRoot;capriData=$CapriData;files=$entries} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $deployment 'deployment.json') -Encoding UTF8
    Copy-Item -LiteralPath $source -Destination $target -Force
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Installed hash mismatch: $target" }
}
if (-not (Test-Path -LiteralPath $capriConfig)) {
    New-Item -ItemType Directory -Path (Split-Path $capriConfig -Parent) -Force | Out-Null
    [IO.File]::WriteAllText($capriConfig,$gameMod)
    $entries+=[pscustomobject]@{path=$capriConfig;backup=$null;sha256=(Get-FileHash -LiteralPath $capriConfig -Algorithm SHA256).Hash}
}
$manifest=Join-Path $deployment 'deployment.json'
[pscustomobject]@{version='1.9.3';gameRoot=$GameRoot;capriData=$CapriData;files=$entries} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifest -Encoding UTF8
Write-Output "Installed game bridge: $gameMod"
if($StageForRestart) { Write-Output 'Files staged for next launch. The running game continues using its already-loaded Lua code until restart.' }
Write-Output "Installed Capri code mod: $capriMod"
Write-Output 'Open Capri > Mods and enable/approve Capri Night City. Existing approvals were not changed.'
Write-Output "Deployment: $manifest"
