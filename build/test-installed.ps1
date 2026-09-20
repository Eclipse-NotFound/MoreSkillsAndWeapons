param(
    [string]$ExpectedVersion = '1.5.0-smart-weapons',
    [string]$PythonPath = 'C:\Users\hello\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
)
$ErrorActionPreference = 'Stop'
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$runtimeDir = Join-Path $PSScriptRoot 'test-runtime'
$outputDir = Join-Path $PSScriptRoot 'out'
$installed = Join-Path $PSScriptRoot '..\release\MoreSkillsWeaponsMod.swf'
$testMod = Join-Path $runtimeDir 'mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf'
# Run after test-game-smoke: reuse isolated assets, but replace its probe with production bytes.
if (-not (Test-Path -LiteralPath $testMod)) { throw 'Run test-game-smoke.ps1 first to prepare isolated assets' }
if ((Get-FileHash -LiteralPath (Join-Path $gameRoot 'pfe.swf')).Hash -ne (Get-FileHash -LiteralPath (Join-Path $runtimeDir 'pfe.swf')).Hash) { throw 'Isolated host differs from current game; rebuild test assets first' }
Copy-Item -LiteralPath $installed -Destination $testMod
$installedHash = (Get-FileHash -LiteralPath $installed).Hash
if ((Get-FileHash -LiteralPath $testMod).Hash -ne $installedHash) { throw 'Production copy mismatch' }
$testId = 'pfe-msw-install-' + [guid]::NewGuid().ToString('N')
$descriptor = Join-Path $runtimeDir 'app_msw_install_test.xml'
@"
<application xmlns="http://ns.adobe.com/air/application/30.0">
  <id>$testId</id><versionNumber>1.0</versionNumber><filename>MSWInstallSmoke</filename>
  <initialWindow><content>pfe.swf</content><visible>false</visible><width>1100</width><height>700</height><renderMode>direct</renderMode></initialWindow>
</application>
"@ | Set-Content -LiteralPath $descriptor -Encoding utf8
$sol = Join-Path $env:APPDATA "$testId\Local Store\#SharedObjects\mods\MoreSkills&Weapons\release\MoreSkillsWeaponsMod.swf\MSWConfig.sol"
$proc = $null
Push-Location $PSScriptRoot
try {
    $proc = Start-Process -FilePath (Join-Path $gameRoot 'adl64.exe') -ArgumentList @('-runtime', ('"' + (Join-Path $gameRoot 'runtimes\air\win64') + '"'), ('"' + $descriptor + '"')) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $outputDir 'install-stdout.log') -RedirectStandardError (Join-Path $outputDir 'install-stderr.log') -PassThru
    $passed = $false
    for ($poll = 0; $poll -lt 10; $poll++) {
        if ($proc.WaitForExit(10000)) { throw 'Installed build exited unexpectedly' }
        if (-not (Test-Path -LiteralPath $sol)) { continue }
        $raw = & $PythonPath -c 'import sys,json;sys.path.insert(0,"tools");from read_sol import SolParser;print(json.dumps(SolParser(sys.argv[1]).parse(),ensure_ascii=True))' $sol
        if ($LASTEXITCODE -ne 0) { throw 'Cannot parse installed build diagnostics' }
        $data = $raw | ConvertFrom-Json
        $diag = $data.diag
        Write-Output "Installed smoke: version=$($diag.ver) frames=$($diag.frames) settings=$($diag.tabOn)"
        if ($diag.ver -ne $ExpectedVersion) { throw 'Installed version marker mismatch' }
        if ($diag.lastErr) { throw "Installed build error: $($diag.lastErr)" }
        if ($diag.smartError) { throw "Installed smart error: $($diag.smartError)" }
        if ($diag.frames -ge 900 -and $diag.modAPI -eq 'published' -and $diag.tabOn -eq 1) {
            $data | Add-Member -NotePropertyName installedSHA256 -NotePropertyValue $installedHash
            $data | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $outputDir 'install-smoke.json') -Encoding utf8
            $passed = $true
            break
        }
    }
    if (-not $passed) { throw 'Installed build did not reach heartbeat/settings checks in time' }
    Write-Output 'PASS installed production build'
}
finally {
    if ($null -ne $proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id }
    Remove-Item -LiteralPath $descriptor
    Pop-Location
}
