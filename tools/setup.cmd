@echo off
rem Windows entry point: double-click this file to set up the project (it runs setup.ps1).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
echo.
pause
