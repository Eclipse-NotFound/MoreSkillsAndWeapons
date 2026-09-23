param([string]$ProductionSwf='', [string]$AnimateRoot='D:\Program Files\Adobe Animate 2024', [switch]$Nodebug, [string]$GameDirectory='', [string]$OutputDirectory='out\laser-reload', [string]$LegacySwf='')
$ErrorActionPreference='Stop'
$gameRoot=if($GameDirectory){[IO.Path]::GetFullPath($GameDirectory)}else{[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))}
if(!$ProductionSwf){$ProductionSwf=Join-Path $PSScriptRoot '..\release\MoreSkillsWeaponsMod.swf'}
$output=Join-Path $PSScriptRoot $OutputDirectory
$runtime=Join-Path $output 'runtime'
$mswDir=Join-Path $runtime 'mods\MoreSkills&Weapons\release'
$probeDir=Join-Path $runtime 'mods\LaserReloadSmoke\release'
$settingsDir=Join-Path $runtime 'mods\ModSettings\release'
New-Item -ItemType Directory -Force $output,$runtime,$mswDir,$probeDir,$settingsDir | Out-Null
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-debug=true' '-target-player=11.1' '-source-path+=smoke' ("-output="+(Join-Path $probeDir 'LaserReloadSmoke.swf')) 'smoke/LaserReloadSmoke.as'
    if($LASTEXITCODE -ne 0){throw 'Production-shot harness compilation failed'}
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object {$_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml'} | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $runtime}
    if(!(Test-Path -LiteralPath (Join-Path $runtime 'Rooms'))){Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtime -Recurse}
    Copy-Item -LiteralPath $ProductionSwf -Destination (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')
    $legacyCopy=Join-Path $mswDir 'LegacyConfig.swf'
    if($LegacySwf){Copy-Item -LiteralPath $LegacySwf -Destination $legacyCopy}
    elseif(Test-Path -LiteralPath $legacyCopy){Remove-Item -LiteralPath $legacyCopy}
    $hash=(Get-FileHash -LiteralPath $ProductionSwf).Hash
    if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Production copy mismatch'}
    if($LegacySwf){Copy-Item -LiteralPath $LegacySwf -Destination (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')}
    $settingsEntry=& (Join-Path $PSScriptRoot 'copy-settings-host.ps1') -GameDirectory $gameRoot -RuntimeDirectory $runtime
    "$settingsEntry`nLaserReloadSmoke|LaserReloadSmoke|1|0|0" | Set-Content -LiteralPath (Join-Path $runtime 'mods\loader-manifest.txt') -Encoding utf8
    $testId='pfe-modsettings-reload-'+[guid]::NewGuid().ToString('N')
    $descriptor=Join-Path $runtime 'app_msw_shot_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0"><id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWShotTest</filename><initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow></application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $argsList=@('-runtime',('"'+(Join-Path $gameRoot 'runtimes\air\win64')+'"'),('"'+$descriptor+'"'))
    if($Nodebug){$argsList+='-nodebug'}
    $proc=$null
    try {
        $proc=Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList $argsList -WindowStyle Hidden -RedirectStandardOutput (Join-Path $output 'stdout.log') -RedirectStandardError (Join-Path $output 'stderr.log') -PassThru
        $storage=Join-Path $env:APPDATA "$testId\Local Store"
        $legacySwapped=$false
        for($i=0;$i -lt 240;$i++){
            if($proc.WaitForExit(500)){break}
            if($LegacySwf -and !$legacySwapped -and (Test-Path -LiteralPath (Join-Path $storage 'legacy-config-ready.txt'))){
                Copy-Item -LiteralPath $ProductionSwf -Destination (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')
                if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Upgrade build copy mismatch'}
                'ready' | Set-Content -LiteralPath (Join-Path $storage 'production-ready.txt')
                $legacySwapped=$true
            }
        }
        if(!$proc.HasExited){throw 'Production-shot test timed out'}
        $result=Join-Path $env:APPDATA "$testId\Local Store\reload-shot.txt"
        if(!(Test-Path -LiteralPath $result)){throw 'No combat-shot result'}
        Copy-Item -LiteralPath $result -Destination (Join-Path $output 'results.txt')
        Get-ChildItem -LiteralPath (Split-Path -Parent $result) -Filter '*.png' | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $output}
        $lines=Get-Content -LiteralPath $result
        if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Runtime did not restore the exact production build after legacy config setup'}
        "Production SHA256=$hash nodebug=$Nodebug"
        $lines
        if($lines[-1] -ne 'PASS production laser shot'){throw 'Production-shot regression failed'}
    }
    finally {
        if($null -ne $proc -and !$proc.HasExited){Stop-Process -Id $proc.Id}
        Remove-Item -LiteralPath $descriptor -ErrorAction SilentlyContinue
    }
}
finally {Pop-Location}
