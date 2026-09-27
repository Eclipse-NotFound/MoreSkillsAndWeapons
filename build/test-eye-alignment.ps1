param([string]$ProductionSwf='', [string]$AnimateRoot='D:\Program Files\Adobe Animate 2024', [switch]$Nodebug, [string]$GameDirectory='', [string]$OutputDirectory='out\eye-alignment-20260924\baseline', [string]$ProbeClass='EyeAlignmentSmoke')
$ErrorActionPreference='Stop'
$gameRoot=if($GameDirectory){[IO.Path]::GetFullPath($GameDirectory)}else{[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))}
if(!$ProductionSwf){$ProductionSwf=Join-Path $PSScriptRoot '..\release\MoreSkillsWeaponsMod.swf'}
$ProductionSwf=[IO.Path]::GetFullPath($ProductionSwf)
$output=Join-Path $PSScriptRoot $OutputDirectory
$runtime=Join-Path $output 'runtime'
$mswDir=Join-Path $runtime 'mods\MoreSkills&Weapons\release'
$probeDir=Join-Path $runtime "mods\$ProbeClass\release"
New-Item -ItemType Directory -Force $output,$runtime,$mswDir,$probeDir | Out-Null
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-debug=true' '-target-player=11.1' '-source-path+=smoke' ("-output="+(Join-Path $probeDir "$ProbeClass.swf")) "smoke/$ProbeClass.as"
    if($LASTEXITCODE -ne 0){throw 'Eye-alignment harness compilation failed'}
    $fixture=Join-Path $PSScriptRoot 'fixtures\eye-native-fixtures.json'
    if(Test-Path -LiteralPath $fixture){Copy-Item -LiteralPath $fixture -Destination $runtime}
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object {$_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml'} | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $runtime}
    if(!(Test-Path -LiteralPath (Join-Path $runtime 'Rooms'))){Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtime -Recurse}
    Copy-Item -LiteralPath $ProductionSwf -Destination (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')
    $hash=(Get-FileHash -LiteralPath $ProductionSwf).Hash
    if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Production copy mismatch'}
    $settingsEntry=& (Join-Path $PSScriptRoot 'copy-settings-host.ps1') -GameDirectory $gameRoot -RuntimeDirectory $runtime
    "$settingsEntry`n$ProbeClass|$ProbeClass|1|0|0" | Set-Content -LiteralPath (Join-Path $runtime 'mods\loader-manifest.txt') -Encoding utf8
    $testId='pfe-modsettings-eyes-'+[guid]::NewGuid().ToString('N')
    $descriptor=Join-Path $runtime 'app_msw_eye_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0"><id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWEyeTest</filename><initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow></application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $argsList=@('-runtime',('"'+(Join-Path $gameRoot 'runtimes\air\win64')+'"'),('"'+$descriptor+'"'))
    if($Nodebug){$argsList+='-nodebug'}
    $proc=$null
    try {
        $proc=Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList $argsList -WindowStyle Hidden -RedirectStandardOutput (Join-Path $output 'stdout.log') -RedirectStandardError (Join-Path $output 'stderr.log') -PassThru
        $storage=Join-Path $env:APPDATA "$testId\Local Store"
        for($i=0;$i -lt 240;$i++){
            if($proc.WaitForExit(500)){break}
        }
        if(!$proc.HasExited){throw 'Eye-alignment test timed out'}
        $result=Join-Path $env:APPDATA "$testId\Local Store\eye-alignment.txt"
        if(!(Test-Path -LiteralPath $result)){throw 'No eye-alignment result'}
        Copy-Item -LiteralPath $result -Destination (Join-Path $output 'results.txt')
        Get-ChildItem -LiteralPath (Split-Path -Parent $result) -File | Where-Object {$_.Extension -in @('.png','.json')} | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $output}
        $lines=Get-Content -LiteralPath $result
        if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Runtime candidate hash changed'}
        @{productionSHA256=$hash;gameSHA256=(Get-FileHash -LiteralPath (Join-Path $runtime 'pfe.swf')).Hash;testId=$testId;nodebug=[bool]$Nodebug} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'run.json') -Encoding utf8
        "Production SHA256=$hash nodebug=$Nodebug"
        $lines
        if($lines[-1] -ne 'PASS eye alignment'){throw 'Eye-alignment regression failed'}
    }
    finally {
        if($null -ne $proc -and !$proc.HasExited){Stop-Process -Id $proc.Id}
        Remove-Item -LiteralPath $descriptor -ErrorAction SilentlyContinue
    }
}
finally {Pop-Location}


