param([string]$AnimateRoot = 'D:\Program Files\Adobe Animate 2024', [string]$HostSwf='', [string]$SettingsSwf='', [string]$SourcePath='../src', [switch]$Sandevistan)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'build-smart-host.ps1') -AnimateRoot $AnimateRoot
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$runtimeDir = Join-Path $PSScriptRoot 'out\laser\runtime'
$outputDir = Join-Path $PSScriptRoot 'out\laser'
$javaPath = Join-Path $AnimateRoot 'jre\bin\java.exe'
$compilerPath = Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar'
New-Item -ItemType Directory -Force $runtimeDir,$outputDir,(Join-Path $runtimeDir 'mods\MoreSkills&Weapons\release') | Out-Null
Push-Location $PSScriptRoot
try {
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-target-player=11.1' ("-source-path+="+$SourcePath) '-includes=fe.unit.MSWBlindAccess,fe.inter.MSWLaserSats,fe.weapon.MSWPanicBlade,fe.weapon.MSWDazzlerWeapon' '-external-library-path+=out/SmartHost.swc' '-output=out/laser/MoreSkillsWeaponsMod.swf' (Join-Path $SourcePath 'MoreSkillsWeaponsMod.as')
    if ($LASTEXITCODE -ne 0) { throw 'Mod compilation failed' }
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-debug=true' '-target-player=11.1' ("-source-path+="+$SourcePath) '-includes=fe.unit.MSWBlindAccess,fe.inter.MSWLaserSats,fe.weapon.MSWPanicBlade,fe.weapon.MSWDazzlerWeapon' '-external-library-path+=out/SmartHost.swc' '-source-path+=smoke' '-output=out/laser/LaserSmokeMod.swf' 'smoke/LaserSmokeMod.as'
    if ($LASTEXITCODE -ne 0) { throw 'Smoke harness compilation failed' }
    Copy-Item -LiteralPath (Join-Path $outputDir 'LaserSmokeMod.swf') -Destination (Join-Path $runtimeDir 'mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf')
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object { $_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml' } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $runtimeDir }
    $manifest=Join-Path $gameRoot 'mods\loader-manifest.txt'
    if(Test-Path -LiteralPath $manifest){Copy-Item -LiteralPath $manifest -Destination (Join-Path $runtimeDir 'mods\loader-manifest.txt')}
    $settingsDir=Join-Path $runtimeDir 'mods\ModSettings\release'
    New-Item -ItemType Directory -Force $settingsDir | Out-Null
    if($SettingsSwf){Copy-Item -LiteralPath $SettingsSwf -Destination $settingsDir}
    else {
        & (Join-Path $PSScriptRoot 'copy-settings-host.ps1') -GameDirectory $gameRoot -RuntimeDirectory $runtimeDir | Out-Null
    }
    if($HostSwf){Copy-Item -LiteralPath $HostSwf -Destination (Join-Path $runtimeDir 'pfe.swf')}
    if (-not (Test-Path -LiteralPath (Join-Path $runtimeDir 'Rooms'))) { Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtimeDir -Recurse }

    New-Item -ItemType Directory -Force (Join-Path $runtimeDir 'mods\Sandevistan\release') | Out-Null
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-debug=true' '-target-player=11.1' '-source-path+=smoke' '-output=out/laser/runtime/mods/Sandevistan/release/SandevistanMod.swf' 'smoke/SandevistanMod.as'
    if($Sandevistan) {
        $sandyDir=Join-Path $runtimeDir 'mods\Sandevistan\release'
        Copy-Item -LiteralPath (Join-Path $gameRoot 'mods\Sandevistan\release\SandevistanMod.swf') -Destination $sandyDir
        "hotkey=220`nduration=240`ncooldown=0`nreplayspeed=3`nslowfactor=5`ndiaglog=1`ndebugtest=0`nesandyenabled=0" | Set-Content -LiteralPath (Join-Path $sandyDir 'config.txt') -Encoding utf8
    }
    $testId = 'pfe-msw-laser-' + [guid]::NewGuid().ToString('N')
    $descriptor = Join-Path $runtimeDir 'app_msw_laser_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0">
  <id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWGameSmoke</filename>
  <initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow>
</application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $storageDir = Join-Path $env:APPDATA "$testId\Local Store"
    foreach ($name in @('results.txt','heartbeat.txt','laser-hud.png','laser-settings.png')) {
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
        foreach ($name in @('results.txt','heartbeat.txt','laser-hud.png','laser-settings.png')) {
            $src = Join-Path $storageDir $name
            if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination $outputDir }
        }
        $result = Join-Path $outputDir 'results.txt'
        if (-not (Test-Path -LiteralPath $result)) { throw 'No game smoke result' }
        $lines = Get-Content -LiteralPath $result
        $lines | Select-Object -Last 12
        if ($lines[-1] -ne 'PASS laser game smoke') { throw 'Laser test failed; see out/laser/results.txt' }
    }
    finally {
        if (-not $proc.HasExited) { Stop-Process -Id $proc.Id }
        Remove-Item -LiteralPath $descriptor -ErrorAction SilentlyContinue
    }
}
finally { Pop-Location }
