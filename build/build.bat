@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -File "%~dp0build.ps1"
if errorlevel 1 exit /b 1
echo [OK] out\MoreSkillsWeaponsMod.swf built. Deployment is a separate release-gate step.
