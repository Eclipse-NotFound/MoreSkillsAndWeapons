param([string]$AnimateRoot = 'D:\Program Files\Adobe Animate 2024')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'build-smart-host.ps1') -AnimateRoot $AnimateRoot
Push-Location $PSScriptRoot
try {
    & (Join-Path $AnimateRoot 'jre\bin\java.exe') '-Dfile.encoding=UTF-8' -jar (Join-Path $AnimateRoot 'Common\Configuration\ActionScript 3.0\bin\mxmlc.jar') '-target-player=11.1' '-source-path+=../src' '-includes=fe.unit.MSWBlindAccess,fe.inter.MSWLaserSats,fe.weapon.MSWPanicBlade,fe.weapon.MSWDazzlerWeapon' '-external-library-path+=out/SmartHost.swc' '-link-report=out/link-report.xml' '-output=out/MoreSkillsWeaponsMod.swf' '../src/MoreSkillsWeaponsMod.as'
    if ($LASTEXITCODE -ne 0) { throw 'Production compilation failed' }
    # mxmlc leaves '&' in source paths unescaped (this repository contains one).
    $reportText=Get-Content -LiteralPath 'out/link-report.xml' -Raw
    [xml]$report=$reportText -replace '&(?!amp;|lt;|gt;|quot;|apos;)','&amp;'
    $definitions=@($report.report.scripts.script.def | ForEach-Object {$_.id})
    foreach($required in @('MoreSkillsWeaponsMod','fe.unit:MSWBlindAccess','fe.inter:MSWLaserSats','fe.weapon:MSWPanicBlade','fe.weapon:MSWDazzlerWeapon')) {
        if($required -notin $definitions){throw "Missing production definition: $required"}
    }
    foreach($definition in $definitions) {
        if($definition -in @('fe:Pt','fe.unit:Unit','fe.unit:UnitRaider','fe.inter:SatsCel','fe.weapon:Bullet','fe.weapon:Weapon') -or $definition -match 'Smoke|Probe') {
            throw "Forbidden production definition: $definition"
        }
    }
    Write-Output "PASS production link report ($($definitions.Count) definitions; host classes external)"
}
finally { Pop-Location }
