param([string]$AnimateRoot = 'D:\Program Files\Adobe Animate 2024', [string]$SourcePath='../src', [switch]$MultiLock, [switch]$SmoothMode)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'build-smart-host.ps1') -AnimateRoot $AnimateRoot
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$runtimeDir = Join-Path $PSScriptRoot 'test-sandy-runtime'
$outputDir = Join-Path $PSScriptRoot 'out\sandy-smart'
$probeName='SandySmartSmokeMod'
if($MultiLock){$runtimeDir=Join-Path $PSScriptRoot 'out\sandy-multi\runtime';$outputDir=Join-Path $PSScriptRoot 'out\sandy-multi';$probeName='MultiSandySmartSmokeMod'}
if($SmoothMode){$runtimeDir=Join-Path $PSScriptRoot 'out\sandy-smooth\runtime';$outputDir=Join-Path $PSScriptRoot 'out\sandy-smooth';$probeName='SmoothSandySmartSmokeMod'}
$javaPath = Join-Path $AnimateRoot 'jre\bin\java.exe'
$compilerPath = Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar'
New-Item -ItemType Directory -Force $runtimeDir,$outputDir,(Join-Path $runtimeDir 'mods\MoreSkills&Weapons\release') | Out-Null
Push-Location $PSScriptRoot
try {
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-target-player=11.1' ("-source-path+="+$SourcePath) '-includes=fe.unit.MSWBlindAccess,fe.inter.MSWLaserSats,fe.weapon.MSWPanicBlade,fe.weapon.MSWDazzlerWeapon' '-external-library-path+=out/SmartHost.swc' ("-output="+(Join-Path $outputDir 'Production.swf')) (Join-Path $SourcePath 'MoreSkillsWeaponsMod.as')
    if ($LASTEXITCODE -ne 0) { throw 'Mod compilation failed' }
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-debug=true' '-target-player=11.1' ("-source-path+="+$SourcePath) '-includes=fe.unit.MSWBlindAccess,fe.inter.MSWLaserSats,fe.weapon.MSWPanicBlade,fe.weapon.MSWDazzlerWeapon' '-external-library-path+=out/SmartHost.swc' '-source-path+=smoke' ("-output="+(Join-Path $outputDir ($probeName+'.swf'))) ('smoke/'+$probeName+'.as')
    if ($LASTEXITCODE -ne 0) { throw 'Smoke harness compilation failed' }
    Copy-Item -LiteralPath (Join-Path $outputDir ($probeName+'.swf')) -Destination (Join-Path $runtimeDir 'mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf')
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object { $_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml' } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $runtimeDir }
    $manifest=Join-Path $gameRoot 'mods\loader-manifest.txt'
    if(Test-Path -LiteralPath $manifest){Copy-Item -LiteralPath $manifest -Destination (Join-Path $runtimeDir 'mods\loader-manifest.txt')}
    if (-not (Test-Path -LiteralPath (Join-Path $runtimeDir 'Rooms'))) { Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtimeDir -Recurse }
    $settingsSwf=Join-Path $gameRoot 'mods\ModSettings\release\ModSettingsMod.swf'
    if(Test-Path -LiteralPath $settingsSwf){$settingsDir=Join-Path $runtimeDir 'mods\ModSettings\release';New-Item -ItemType Directory -Force $settingsDir | Out-Null;Copy-Item -LiteralPath $settingsSwf -Destination $settingsDir}
    $sandyDir = Join-Path $runtimeDir 'mods\Sandevistan\release'
    New-Item -ItemType Directory -Force $sandyDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $gameRoot 'mods\Sandevistan\release\SandevistanMod.swf') -Destination $sandyDir
    "hotkey=220`nduration=240`ncooldown=0`nreplayspeed=3`nslowfactor=5`ndiaglog=1`ndebugtest=0`nesandyenabled=0" | Set-Content -LiteralPath (Join-Path $sandyDir 'config.txt') -Encoding utf8
    $testId = 'pfe-msw-sandy-smart-' + [guid]::NewGuid().ToString('N')
    $testId | Set-Content -LiteralPath (Join-Path $outputDir 'test-id.txt') -Encoding utf8
    $descriptor = Join-Path $runtimeDir 'app_msw_smart_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0">
  <id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWGameSmoke</filename>
  <initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow>
</application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $storageDir = Join-Path $env:APPDATA "$testId\Local Store"
    foreach ($name in @('results.txt','heartbeat.txt','settings.png')) {
        $oldOutput = Join-Path $outputDir $name
        if (Test-Path -LiteralPath $oldOutput) { Remove-Item -LiteralPath $oldOutput }
    }
    $proc = Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList @('-runtime', ('"' + (Join-Path $gameRoot 'runtimes\air\win64') + '"'), ('"' + $descriptor + '"')) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $outputDir 'stdout.log') -RedirectStandardError (Join-Path $outputDir 'stderr.log') -PassThru
    try {
        for ($poll = 0; $poll -lt 8; $poll++) {
            if ($proc.WaitForExit(15000)) { break }
            if (Test-Path -LiteralPath (Join-Path $storageDir 'heartbeat.txt')) { Get-Content -LiteralPath (Join-Path $storageDir 'heartbeat.txt') -TotalCount 1 }
        }
        if (-not $proc.HasExited) { throw 'Game smoke timed out' }
        foreach ($name in @('results.txt','heartbeat.txt','settings.png')) {
            $src = Join-Path $storageDir $name
            if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination $outputDir }
        }
        $result = Join-Path $outputDir 'results.txt'
        if (-not (Test-Path -LiteralPath $result)) { throw 'No game smoke result' }
        $lines = Get-Content -LiteralPath $result
        $lines | Select-Object -Last 12
        if ($lines[-1] -ne 'PASS smart Sandevistan integration') { throw 'Smart Sandevistan test failed; see out/sandy-smart/results.txt' }
    }
    finally {
        if (-not $proc.HasExited) { Stop-Process -Id $proc.Id }
        foreach($name in @('results.txt','heartbeat.txt')) {
            $saved=Join-Path $storageDir $name
            if(Test-Path -LiteralPath $saved){Copy-Item -LiteralPath $saved -Destination $outputDir}
        }
        Remove-Item -LiteralPath $descriptor
    }
}
finally { Pop-Location }
