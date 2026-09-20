param([string]$AnimateRoot = 'D:\Program Files\Adobe Animate 2024',
      [string]$FlexRoot = 'D:\RemainsMod\mods\Sandevistan\build\tools\flexsdk')
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    New-Item -ItemType Directory -Force 'out' | Out-Null
    $pg = Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\FP11.1\playerglobal.swc'
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $FlexRoot 'lib\compc.jar') '-load-config=flex-config.xml' '-target-player=11.1' '-compiler.library-path=' ("-compiler.external-library-path=" + $pg) '-source-path=stubs' '-include-classes=fe.Pt,fe.unit.Unit,fe.unit.UnitRaider,fe.inter.SatsCel,fe.weapon.Bullet,fe.weapon.Weapon' '-output=out/SmartHost.swc'
    if ($LASTEXITCODE -ne 0) { throw 'Smart host extern compilation failed' }
}
finally { Pop-Location }
