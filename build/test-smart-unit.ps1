param(
    [string]$AnimateRoot = 'D:\Program Files\Adobe Animate 2024', [string]$GameDirectory='',
    [string]$SourcePath='../src', [string]$TestSourcePath='tests', [string]$OutputDirectory='out\smart-tests'
)
$ErrorActionPreference = 'Stop'
$gameRoot = if($GameDirectory){[IO.Path]::GetFullPath($GameDirectory)}else{[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))}
$javaPath = Join-Path $AnimateRoot 'jre\bin\java.exe'
$compilerPath = Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar'
$outputDir = Join-Path $PSScriptRoot $OutputDirectory
New-Item -ItemType Directory -Force $outputDir | Out-Null
Push-Location $PSScriptRoot
try {
    & $javaPath '-Dfile.encoding=UTF-8' -jar $compilerPath '-debug=true' '-target-player=11.1' ("-source-path+="+$SourcePath) ("-source-path+="+$TestSourcePath) ("-output="+(Join-Path $outputDir 'SmartTests.swf')) (Join-Path $TestSourcePath 'SmartTests.as')
    if ($LASTEXITCODE -ne 0) { throw 'Test compilation failed' }
    $testId = 'pfe-msw-smart-unit-' + [guid]::NewGuid().ToString('N')
    $descriptor = Join-Path $outputDir 'app_msw_test.xml'
    @"
<application xmlns="http://ns.adobe.com/air/application/30.0">
  <id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWSmartTests</filename>
  <initialWindow><content>SmartTests.swf</content><visible>false</visible><width>1000</width><height>700</height></initialWindow>
</application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
    $result = Join-Path $outputDir 'results.txt'
    $storedResult = Join-Path $env:APPDATA "$testId\Local Store\results.txt"
    if (Test-Path -LiteralPath $result) { Remove-Item -LiteralPath $result }
    $proc = Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList @('-runtime', ('"' + (Join-Path $gameRoot 'runtimes\air\win64') + '"'), ('"' + $descriptor + '"')) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $outputDir 'stdout.log') -RedirectStandardError (Join-Path $outputDir 'stderr.log') -PassThru
    try {
        if (-not $proc.WaitForExit(30000)) { throw 'AIR test timed out after 30 seconds' }
        if (Test-Path -LiteralPath $storedResult) { Copy-Item -LiteralPath $storedResult -Destination $result }
        if (-not (Test-Path -LiteralPath $result)) { throw 'AIR test did not write results' }
        $lines = Get-Content -LiteralPath $result
        $lines | Select-Object -Last 6
        if ($lines[-1] -notmatch '^PASS \d+ assertions$') { throw 'AIR assertions failed; see out/smart-tests/results.txt' }
    }
    finally {
        if (-not $proc.HasExited) { Stop-Process -Id $proc.Id }
        Remove-Item -LiteralPath $descriptor
    }
}
finally { Pop-Location }
