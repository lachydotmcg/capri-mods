param([Parameter(Mandatory=$true)][string]$Deployment,[switch]$Fixture)
$ErrorActionPreference='Stop'
if (-not $Fixture -and (Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue)) { throw 'Close Cyberpunk before removing the bridge.' }
$manifest=Get-Content -LiteralPath $Deployment -Raw | ConvertFrom-Json
$gameRoot=[IO.Path]::GetFullPath($manifest.gameRoot)
$capriData=[IO.Path]::GetFullPath($manifest.capriData)
$gameMod=Join-Path $gameRoot 'bin\x64\plugins\cyber_engine_tweaks\mods\CapriNightCityBridge'
$allowedCapri=@((Join-Path $capriData 'mods\capri-night-city.capri-code'),(Join-Path $capriData 'mods\capri-night-city-data\game-folder.txt'))
# Validate every path and hash before performing any rollback.
foreach ($entry in $manifest.files) {
    $target=[IO.Path]::GetFullPath($entry.path)
    if (-not ($target.StartsWith($gameMod+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or $allowedCapri -contains $target)) { throw "Unexpected rollback target: $target" }
    if ((Test-Path -LiteralPath $target) -and (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $entry.sha256) { throw "File changed since installation; retaining it: $target" }
    if ($entry.backup -and -not (Test-Path -LiteralPath $entry.backup)) { throw "Missing backup: $($entry.backup)" }
    if ($entry.backup -and (Get-FileHash -LiteralPath $entry.backup -Algorithm SHA256).Hash -ne $entry.backupSha256) { throw "Backup hash mismatch: $($entry.backup)" }
}
foreach ($entry in $manifest.files) {
    if ($entry.backup) { Copy-Item -LiteralPath $entry.backup -Destination $entry.path -Force }
    elseif (Test-Path -LiteralPath $entry.path) { Remove-Item -LiteralPath $entry.path }
}
Write-Output 'Restored/removed only hash-matching installed files. Runtime files, settings changed by you and unrelated files are retained.'
Write-Output 'Disable Capri Night City in Capri Mods to stop its current listener.'
