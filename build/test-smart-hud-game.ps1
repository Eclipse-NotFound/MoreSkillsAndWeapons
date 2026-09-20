param([string]$AnimateRoot = 'D:\Program Files\Adobe Animate 2024', [string]$HostSwf='', [string]$SettingsSwf='', [string]$SourcePath='../src')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'build-smart-host.ps1') -AnimateRoot $AnimateRoot
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$runtimeDir = Join-Path $PSScriptRoot 'out\smart-hud-game\runtime'
$outputDir = Join-Path $PSScriptRoot 'out\smart-hud-game'
$javaPath = Join-Path $AnimateRoot 'jre\bin\java.exe'
$compilerPath = Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar'
New-Item -ItemType Directory -Force $runtimeDir,$outputDir,(Join-Path $runtimeDir 'mods\MoreSkills&Weapons\release') | Out-Null
Push-Location $PSScriptRoot
try {
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-target-player=11.1' ("-source-path+="+$SourcePath) '-includes=fe.unit.MSWBlindAccess,fe.inter.MSWLaserSats,fe.weapon.MSWPanicBlade,fe.weapon.MSWDazzlerWeapon' '-external-library-path+=out/SmartHost.swc' '-output=out/smart-hud-game/MoreSkillsWeaponsMod.swf' (Join-Path $SourcePath 'MoreSkillsWeaponsMod.as')
    if ($LASTEXITCODE -ne 0) { throw 'Mod compilation failed' }
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-debug=true' '-target-player=11.1' ("-source-path+="+$SourcePath) '-includes=fe.unit.MSWBlindAccess,fe.inter.MSWLaserSats,fe.weapon.MSWPanicBlade,fe.weapon.MSWDazzlerWeapon' '-external-library-path+=out/SmartHost.swc' '-source-path+=smoke' '-output=out/smart-hud-game/SmartHudSmokeMod.swf' 'smoke/SmartHudSmokeMod.as'
    if ($LASTEXITCODE -ne 0) { throw 'Smoke harness compilation failed' }
    Copy-Item -LiteralPath (Join-Path $outputDir 'SmartHudSmokeMod.swf') -Destination (Join-Path $runtimeDir 'mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf')
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object { $_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml' } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $runtimeDir }
    $settingsDir=Join-Path $runtimeDir 'mods\ModSettings\release'
    New-Item -ItemType Directory -Force $settingsDir | Out-Null
    if(!$SettingsSwf){$SettingsSwf=Join-Path $gameRoot 'mods\ModSettings\release\ModSettingsMod.swf'}
    Copy-Item -LiteralPath $SettingsSwf -Destination $settingsDir
    if($HostSwf){Copy-Item -LiteralPath $HostSwf -Destination (Join-Path $runtimeDir 'pfe.swf')}
    if (-not (Test-Path -LiteralPath (Join-Path $runtimeDir 'Rooms'))) { Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtimeDir -Recurse }
    $testId = 'pfe-msw-hud-game-' + [guid]::NewGuid().ToString('N')
    $descriptor = Join-Path $runtimeDir 'app_msw_hud_game_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0">
  <id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWGameSmoke</filename>
  <initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow>
</application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $storageDir = Join-Path $env:APPDATA "$testId\Local Store"
    foreach ($name in @('results.txt','heartbeat.txt','game-two-targets.png','game-loss.png','scene.txt')) {
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
        foreach ($name in @('results.txt','heartbeat.txt','game-two-targets.png','game-loss.png','scene.txt')) {
            $src = Join-Path $storageDir $name
            if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination $outputDir }
        }
        $result = Join-Path $outputDir 'results.txt'
        if (-not (Test-Path -LiteralPath $result)) { throw 'No game smoke result' }
        $lines = Get-Content -LiteralPath $result
        $lines | Select-Object -Last 12
        if ($lines[-1] -ne 'PASS smart HUD game smoke') { throw 'Smart test failed; see out/smart-hud-game/results.txt' }
    }
    finally {
        if (-not $proc.HasExited) { Stop-Process -Id $proc.Id }
        Remove-Item -LiteralPath $descriptor
    }
}
finally { Pop-Location }
