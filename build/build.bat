@echo off
setlocal
cd /d "%~dp0"
java -jar "C:\Program Files\Adobe\Adobe Animate 2024\Common\Configuration\ActionScript 3.0\bin\mxmlc.jar" -target-player=11.1 -source-path+=..\src -output ..\release\MoreSkillsWeaponsMod.swf ..\src\MoreSkillsWeaponsMod.as
if errorlevel 1 exit /b 1
echo [OK] MoreSkillsWeaponsMod.swf built
