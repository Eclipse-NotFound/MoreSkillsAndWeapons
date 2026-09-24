param([string]$ProductionSwf='', [string]$AnimateRoot='D:\Program Files\Adobe Animate 2024', [switch]$Nodebug, [string]$GameDirectory='', [string]$OutputDirectory='out\near-smart', [string]$Mode='slow', [double]$Radius=50, [bool]$Adaptive=$true, [string]$Only='all', [string]$Weapon='lmg', [double]$Distance=180, [double]$AimOffset=0, [int]$Shots=1)
$ErrorActionPreference='Stop'
$gameRoot=if($GameDirectory){[IO.Path]::GetFullPath($GameDirectory)}else{[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))}
if(!$ProductionSwf){$ProductionSwf=Join-Path $PSScriptRoot '..\release\MoreSkillsWeaponsMod.swf'}
$output=Join-Path $PSScriptRoot $OutputDirectory
$runtime=Join-Path $output 'runtime'
$mswDir=Join-Path $runtime 'mods\MoreSkills&Weapons\release'
$probeDir=Join-Path $runtime 'mods\NearSmartSmoke\release'
$settingsDir=Join-Path $runtime 'mods\ModSettings\release'
New-Item -ItemType Directory -Force $output,$runtime,$mswDir,$probeDir,$settingsDir | Out-Null
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-debug=true' '-target-player=11.1' '-source-path+=smoke' ("-output="+(Join-Path $probeDir 'NearSmartSmoke.swf')) 'smoke/NearSmartSmoke.as'
    if($LASTEXITCODE -ne 0){throw 'Near-smart harness compilation failed'}
    Get-ChildItem -LiteralPath $gameRoot -File | Where-Object {$_.Name -eq 'pfe.swf' -or $_.Name -match '^(sound|sprite|texture).*\.swf$' -or $_.Extension -eq '.xml'} | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $runtime}
    if(!(Test-Path -LiteralPath (Join-Path $runtime 'Rooms'))){Copy-Item -LiteralPath (Join-Path $gameRoot 'Rooms') -Destination $runtime -Recurse}
    Copy-Item -LiteralPath $ProductionSwf -Destination (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')
    $hash=(Get-FileHash -LiteralPath $ProductionSwf).Hash
    if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Production copy mismatch'}
    $settingsEntry=& (Join-Path $PSScriptRoot 'copy-settings-host.ps1') -GameDirectory $gameRoot -RuntimeDirectory $runtime
    # Both controls load the same installed Sandevistan; only slow mode presses its hotkey.
    $sandyDir=Join-Path $runtime 'mods\Sandevistan\release'
    New-Item -ItemType Directory -Force $sandyDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $gameRoot 'mods\Sandevistan\release\SandevistanMod.swf') -Destination $sandyDir
    "hotkey=220`nduration=240`ncooldown=0`nreplayspeed=3`nslowfactor=5`ndiaglog=1`ndebugtest=0`nesandyenabled=0" | Set-Content -LiteralPath (Join-Path $sandyDir 'config.txt') -Encoding utf8
    "$settingsEntry`nSandevistan|SandevistanMod|1|0|0`nNearSmartSmoke|NearSmartSmoke|1|0|0" | Set-Content -LiteralPath (Join-Path $runtime 'mods\loader-manifest.txt') -Encoding utf8
    @{mode=$Mode;radius=$Radius;adaptive=$Adaptive;only=$Only;weapon=$Weapon;distance=$Distance;aimOffset=$AimOffset;shots=$Shots} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runtime 'near-options.json') -Encoding utf8
    $testId='pfe-modsettings-near-'+[guid]::NewGuid().ToString('N')
    @{productionSHA256=$hash;productionBytes=(Get-Item -LiteralPath $ProductionSwf).Length;testId=$testId;nodebug=[bool]$Nodebug;
      hostSHA256=(Get-FileHash -LiteralPath (Join-Path $runtime 'pfe.swf')).Hash;
      sandevistanSHA256=(Get-FileHash -LiteralPath (Join-Path $sandyDir 'SandevistanMod.swf')).Hash;
      options=(Get-Content -LiteralPath (Join-Path $runtime 'near-options.json') -Raw | ConvertFrom-Json)} |
      ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $output 'manifest.json') -Encoding utf8
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
        for($i=0;$i -lt 240;$i++){
            if($proc.WaitForExit(500)){break}
        }
        if(!$proc.HasExited){throw 'Near-smart test timed out'}
        $result=Join-Path $env:APPDATA "$testId\Local Store\near-results.txt"
        if(!(Test-Path -LiteralPath $result)){throw 'No near-smart result'}
        Copy-Item -LiteralPath $result -Destination (Join-Path $output 'results.txt')
        foreach($name in @('trajectories.json','heartbeat.txt','sandy_modlog.txt')) {
            $artifact=Join-Path $storage $name
            if(Test-Path -LiteralPath $artifact){Copy-Item -LiteralPath $artifact -Destination $output}
        }
        Get-ChildItem -LiteralPath (Split-Path -Parent $result) -Filter '*.png' | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination $output}
        $lines=Get-Content -LiteralPath $result
        if((Get-FileHash -LiteralPath (Join-Path $mswDir 'MoreSkillsWeaponsMod.swf')).Hash -ne $hash){throw 'Runtime production copy changed during testing'}
        "Production SHA256=$hash nodebug=$Nodebug"
        $lines | Select-Object -Last ([Math]::Max(16,$Shots+5))
        if($lines[-1] -ne 'PASS near smart'){throw 'Near-smart regression failed'}
    }
    finally {
        if($null -ne $proc -and !$proc.HasExited){Stop-Process -Id $proc.Id}
        Remove-Item -LiteralPath $descriptor -ErrorAction SilentlyContinue
    }
}
finally {Pop-Location}
