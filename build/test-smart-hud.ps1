param([string]$AnimateRoot='D:\Program Files\Adobe Animate 2024')
$ErrorActionPreference='Stop'
$gameRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$outputDir=Join-Path $PSScriptRoot 'out\smart-hud'
New-Item -ItemType Directory -Force $outputDir | Out-Null
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-debug=true' '-target-player=11.1' '-swf-version=41' '-source-path+=../src' '-output=out/smart-hud/SmartHudRenderTest.swf' 'smoke/SmartHudRenderTest.as'
    if($LASTEXITCODE -ne 0){throw 'HUD harness compilation failed'}
    $testId='pfe-msw-hud-'+[guid]::NewGuid().ToString('N')
    $descriptor=Join-Path $outputDir 'app_msw_hud_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0">
 <id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWHudTest</filename>
 <initialWindow><content>SmartHudRenderTest.swf</content><visible>false</visible><width>800</width><height>500</height><renderMode>direct</renderMode></initialWindow>
</application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $storageDir=Join-Path $env:APPDATA "$testId\Local Store"
    $proc=Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList @('-runtime',('"'+(Join-Path $gameRoot 'runtimes\air\win64')+'"'),('"'+$descriptor+'"')) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputDir 'stdout.log') -RedirectStandardError (Join-Path $outputDir 'stderr.log')
    try {
        if(!$proc.WaitForExit(20000)){throw 'HUD test timed out'}
        foreach($name in @('results.txt','preview.png')) {
            $file=Join-Path $storageDir $name
            if(Test-Path -LiteralPath $file){Copy-Item -LiteralPath $file -Destination $outputDir}
        }
        $result=Join-Path $storageDir 'results.txt'
        if(!(Test-Path -LiteralPath $result)){throw 'No fresh HUD results'}
        $lines=Get-Content -LiteralPath $result
        $lines
        if($lines[-1] -notmatch '^PASS smart HUD raster:'){throw 'HUD raster test failed'}
    }
    finally {
        if(!$proc.HasExited){Stop-Process -Id $proc.Id}
        Remove-Item -LiteralPath $descriptor
    }
}
finally {Pop-Location}
