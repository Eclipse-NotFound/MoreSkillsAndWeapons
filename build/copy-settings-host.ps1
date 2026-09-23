param([Parameter(Mandatory=$true)][string]$GameDirectory, [Parameter(Mandatory=$true)][string]$RuntimeDirectory)
$ErrorActionPreference='Stop'
# Settings moved from ModSettingsMod to ModLoaderMod. Follow the actual 1.02
# manifest; a file merely existing does not mean the game loads that host.
$manifest=Join-Path $GameDirectory 'mods\loader-manifest.txt'
$entry='ModSettings|ModSettingsMod|1|0|0'
if(Test-Path -LiteralPath $manifest){
    $hosts=@(Get-Content -LiteralPath $manifest | Where-Object {$_ -match '^(ModSettings\|ModSettingsMod|ModLoader\|ModLoaderMod)\|1\|'})
    if($hosts.Count -ne 1){throw 'Expected exactly one active settings host in the current 1.02 manifest'}
    $entry=$hosts[0].Trim()
}
$parts=$entry.Split('|')
$relative='mods\'+$parts[0]+'\release\'+$parts[1]+'.swf'
$source=Join-Path $GameDirectory $relative
$target=Join-Path $RuntimeDirectory $relative
New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
Copy-Item -LiteralPath $source -Destination $target
if((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'Settings host copy mismatch'}
Write-Output $entry
