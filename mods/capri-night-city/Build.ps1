param(
    [string]$Lua=(Get-Command lua -ErrorAction Stop).Source,
    [string]$Luac=(Get-Command luac55 -ErrorAction Stop).Source
)
$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$validation=Join-Path $root 'validation'
$mock=Join-Path $validation ('mock-game-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $validation,$mock,(Join-Path $root 'out') -Force | Out-Null
foreach ($file in @('core.lua','init.lua','targets.lua','counter.lua','programs.lua')) {
    & $Luac -p (Join-Path $root "CapriNightCityBridge\$file")
    if ($LASTEXITCODE -ne 0) { throw "Lua syntax failed: $file" }
}
Push-Location $mock
try {
    & $Lua "$root\tests\game-tests.lua" "$root\CapriNightCityBridge" | Tee-Object -FilePath "$validation\game-test-results.txt"
    if ($LASTEXITCODE -ne 0) { throw 'Game bridge tests failed.' }
} finally { Pop-Location }
$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw '.NET Framework C# compiler is required.' }
Copy-Item -LiteralPath "$root\capri-night-city.capri-code" -Destination "$validation\NightCity.cs" -Force
& $compiler /nologo /target:library /langversion:5 /r:System.Drawing.dll /out:"$validation\CapriModApi.dll" "$root\tests\CapriModApi.cs"
if ($LASTEXITCODE -ne 0) { throw 'Capri interface compilation failed.' }
& $compiler /nologo /target:library /langversion:5 /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:"$validation\CapriModApi.dll" /out:"$validation\NightCity.dll" "$validation\NightCity.cs"
if ($LASTEXITCODE -ne 0) { throw 'Capri code mod compilation failed.' }
& $compiler /nologo /target:exe /langversion:5 /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:"$validation\CapriModApi.dll" /r:"$validation\NightCity.dll" /out:"$validation\ClientTests.exe" "$root\tests\ClientTests.cs"
if ($LASTEXITCODE -ne 0) { throw 'Client test compilation failed.' }
& "$validation\ClientTests.exe" $validation $Lua $root | Tee-Object -FilePath "$validation\client-test-results.txt"
if ($LASTEXITCODE -ne 0) { throw 'Client tests failed.' }
$capri=Join-Path $env:LOCALAPPDATA 'Capri\Capri.exe'
if (Test-Path -LiteralPath $capri) {
    & $compiler /nologo /target:library /langversion:5 /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:"$capri" /out:"$validation\NightCity-installed-Capri.dll" "$validation\NightCity.cs"
    if ($LASTEXITCODE -ne 0) { throw 'Compatibility compilation against installed Capri failed.' }
    Write-Output ('PASS compatibility compilation: Capri '+(Get-Item -LiteralPath $capri).VersionInfo.FileVersion)
}
& "$root\tests\installer-tests.ps1"
$stage=Join-Path $validation ('package-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
$packageFiles=@('capri-night-city.capri-code','CapriNightCityBridge','tests','Build.ps1','Install.ps1','Uninstall.ps1','README.md','HACKS.md','COMMANDS.md','VALIDATION.md','preview.png')
foreach ($name in $packageFiles) { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $stage -Recurse -Force }
$checksums=Get-ChildItem -LiteralPath $stage -File -Recurse | Sort-Object FullName | ForEach-Object {
    '{0}  {1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash,$_.FullName.Substring($stage.Length+1).Replace('\','/')
}
$checksums | Set-Content -LiteralPath "$stage\SHA256SUMS.txt" -Encoding ASCII
$archive=Join-Path $root 'out\Capri-Night-City-1.9.3.zip'
Compress-Archive -Path "$stage\*" -DestinationPath $archive -Force
Write-Output ('PASS package: '+$archive)
Get-FileHash -LiteralPath $archive -Algorithm SHA256 | Format-List
