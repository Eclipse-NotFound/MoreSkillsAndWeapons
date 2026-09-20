param([string]$AnimateRoot = 'D:\Program Files\Adobe Animate 2024')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'build-smart-host.ps1') -AnimateRoot $AnimateRoot
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-target-player=11.1' '-source-path+=../src' '-external-library-path+=out/SmartHost.swc' '-output=out/MoreSkillsWeaponsMod.swf' '../src/MoreSkillsWeaponsMod.as'
    if ($LASTEXITCODE -ne 0) { throw 'Production compilation failed' }
}
finally { Pop-Location }
