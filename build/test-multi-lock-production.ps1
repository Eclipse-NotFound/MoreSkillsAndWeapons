param([string]$ProductionSwf='', [string]$AnimateRoot='D:\Program Files\Adobe Animate 2024', [switch]$Nodebug, [string]$GameDirectory='')
$ErrorActionPreference='Stop'
$gameRoot=if($GameDirectory){[IO.Path]::GetFullPath($GameDirectory)}else{[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))}
if(!$ProductionSwf){$ProductionSwf=Join-Path $PSScriptRoot '..\release\MoreSkillsWeaponsMod.swf'}
$output=Join-Path $PSScriptRoot 'out\multi-lock-production'
$runtime=Join-Path $output 'runtime'
$mswDir=Join-Path $runtime 'mods\MoreSkills&Weapons\release'
$probeDir=Join-Path $runtime 'mods\MultiLockProductionSmoke\release'
$settingsDir=Join-Path $runtime 'mods\ModSettings\release'
New-Item -ItemType Directory -Force $output,$runtime,$mswDir,$probeDir,$settingsDir | Out-Null
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-debug=true' '-target-player=11.1' '-source-path+=smoke' ("-output="+(Join-Path $probeDir 'MultiLockProductionSmoke.swf')) 'smoke/MultiLockProductionSmoke.as'
    if($LASTEXITCODE -ne 0){throw 'Production-shot harness compilation failed'}
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object {$_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml'} | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $runtime}
    if(!(Test-Path -LiteralPath (Join-Path $runtime 'Rooms'))){Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtime -Recurse}
    Copy-Item -LiteralPath $ProductionSwf -Destination (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')
    $hash=(Get-FileHash -LiteralPath $ProductionSwf).Hash
    if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Production copy mismatch'}
    Copy-Item -LiteralPath (Join-Path $gameRoot 'mods\ModSettings\release\ModSettingsMod.swf') -Destination $settingsDir
    "ModSettings|ModSettingsMod|1|0|0`nMultiLockProductionSmoke|MultiLockProductionSmoke|1|0|0" | Set-Content -LiteralPath (Join-Path $runtime 'mods\loader-manifest.txt') -Encoding utf8
    $testId='pfe-msw-multi-'+[guid]::NewGuid().ToString('N')
    $descriptor=Join-Path $runtime 'app_msw_multi_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0"><id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWMultiTest</filename><initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow></application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $argsList=@('-runtime',('"'+(Join-Path $gameRoot 'runtimes\air\win64')+'"'),('"'+$descriptor+'"'))
    if($Nodebug){$argsList+='-nodebug'}
    $proc=$null
    try {
        $proc=Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList $argsList -WindowStyle Hidden -RedirectStandardOutput (Join-Path $output 'stdout.log') -RedirectStandardError (Join-Path $output 'stderr.log') -PassThru
        for($i=0;$i -lt 24;$i++){if($proc.WaitForExit(5000)){break}}
        if(!$proc.HasExited){throw 'Production-shot test timed out'}
        $result=Join-Path $env:APPDATA "$testId\Local Store\production-multi.txt"
        if(!(Test-Path -LiteralPath $result)){throw 'No production-shot result'}
        Copy-Item -LiteralPath $result -Destination (Join-Path $output 'results.txt')
        foreach ($name in @('heartbeat.txt','multi-acquiring.png','multi-locked.png')) {
            $artifact=Join-Path $env:APPDATA "$testId\Local Store\$name"
            if(Test-Path -LiteralPath $artifact){Copy-Item -LiteralPath $artifact -Destination $output}
        }
        $lines=Get-Content -LiteralPath $result
        "Production SHA256=$hash nodebug=$Nodebug"
        $lines
        if($lines[-1] -ne 'PASS production multi lock'){throw 'Production-shot regression failed'}
    }
    finally {
        if($null -ne $proc -and !$proc.HasExited){Stop-Process -Id $proc.Id}
        Remove-Item -LiteralPath $descriptor -ErrorAction SilentlyContinue
    }
}
finally {Pop-Location}
