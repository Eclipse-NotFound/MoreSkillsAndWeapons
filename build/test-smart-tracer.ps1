param([string]$ProductionSwf='', [string]$AnimateRoot='D:\Program Files\Adobe Animate 2024', [switch]$Nodebug, [string]$GameDirectory='', [string]$OutputDirectory='out\smart-tracer\baseline')
$ErrorActionPreference='Stop'
$gameRoot=if($GameDirectory){[IO.Path]::GetFullPath($GameDirectory)}else{[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))}
if(!$ProductionSwf){$ProductionSwf=Join-Path $PSScriptRoot '..\release\MoreSkillsWeaponsMod.swf'}
$output=Join-Path $PSScriptRoot $OutputDirectory
$runtime=Join-Path $output 'runtime'
$mswDir=Join-Path $runtime 'mods\MoreSkills&Weapons\release'
$probeDir=Join-Path $runtime 'mods\SmartTracerSmoke\release'
$settingsDir=Join-Path $runtime 'mods\ModSettings\release'
New-Item -ItemType Directory -Force $output,$runtime,$mswDir,$probeDir,$settingsDir | Out-Null
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-debug=true' '-target-player=11.1' '-source-path+=smoke' ("-output="+(Join-Path $probeDir 'SmartTracerSmoke.swf')) 'smoke/SmartTracerSmoke.as'
    if($LASTEXITCODE -ne 0){throw 'Smart-tracer harness compilation failed'}
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object {$_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml'} | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $runtime}
    if(!(Test-Path -LiteralPath (Join-Path $runtime 'Rooms'))){Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtime -Recurse}
    Copy-Item -LiteralPath $ProductionSwf -Destination (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')
    $hash=(Get-FileHash -LiteralPath $ProductionSwf).Hash
    if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Production copy mismatch'}
    $settingsEntry=& (Join-Path $PSScriptRoot 'copy-settings-host.ps1') -GameDirectory $gameRoot -RuntimeDirectory $runtime
    "$settingsEntry`nSmartTracerSmoke|SmartTracerSmoke|1|0|0" | Set-Content -LiteralPath (Join-Path $runtime 'mods\loader-manifest.txt') -Encoding utf8
    $testId='pfe-msw-tracer-'+[guid]::NewGuid().ToString('N')
    $testId | Set-Content -LiteralPath (Join-Path $output 'test-id.txt') -Encoding utf8
    @{productionSHA256=$hash;productionBytes=(Get-Item -LiteralPath $ProductionSwf).Length;testId=$testId;nodebug=[bool]$Nodebug;
      hostSHA256=(Get-FileHash -LiteralPath (Join-Path $runtime 'pfe.swf')).Hash;
      probeSHA256=(Get-FileHash -LiteralPath (Join-Path $probeDir 'SmartTracerSmoke.swf')).Hash} |
      ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'manifest.json') -Encoding utf8
    $descriptor=Join-Path $runtime 'app_msw_tracer_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0"><id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWTracerTest</filename><initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow></application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $argsList=@('-runtime',('"'+(Join-Path $gameRoot 'runtimes\air\win64')+'"'),('"'+$descriptor+'"'))
    if($Nodebug){$argsList+='-nodebug'}
    $proc=$null
    try {
        $proc=Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList $argsList -WindowStyle Hidden -RedirectStandardOutput (Join-Path $output 'stdout.log') -RedirectStandardError (Join-Path $output 'stderr.log') -PassThru
        for($i=0;$i -lt 24;$i++){if($proc.WaitForExit(5000)){break}}
        if(!$proc.HasExited){throw 'Smart-tracer test timed out'}
        $result=Join-Path $env:APPDATA "$testId\Local Store\smart-tracer.txt"
        if(!(Test-Path -LiteralPath $result)){throw 'No production-shot result'}
        Copy-Item -LiteralPath $result -Destination (Join-Path $output 'results.txt')
        foreach ($name in @('tracers.png','curved-tracer.png')) {
            $artifact=Join-Path $env:APPDATA "$testId\Local Store\$name"
            if(Test-Path -LiteralPath $artifact){Copy-Item -LiteralPath $artifact -Destination $output}
        }
        $lines=Get-Content -LiteralPath $result
        if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Runtime production copy changed during comparison'}
        "Production SHA256=$hash nodebug=$Nodebug"
        $lines
        if($lines[-1] -ne 'PASS smart tracer'){throw 'Smart-tracer regression failed'}
    }
    finally {
        if($null -ne $proc -and !$proc.HasExited){Stop-Process -Id $proc.Id}
        Remove-Item -LiteralPath $descriptor -ErrorAction SilentlyContinue
    }
}
finally {Pop-Location}


