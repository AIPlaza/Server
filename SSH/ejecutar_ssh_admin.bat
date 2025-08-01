@echo off
:: ╭──────────────────────────────────────────────╮
:: │ Ejecutar enable_ssh_complete.ps1 como Admin │
:: ╰──────────────────────────────────────────────╯

:: 1. Detectar carpeta Descargas/Downloads
for /f "tokens=*" %%i in ('powershell -NoProfile -Command ^
 "if ((Get-Culture).Name -like 'es-*') { \"$env:USERPROFILE\\Descargas\" } else { \"$env:USERPROFILE\\Downloads\" }"') do set "DOWNLOADS=%%i"

:: 2. Ruta del script PowerShell
set "SCRIPT=%DOWNLOADS%\enable_ssh_complete.ps1"

:: 3. Verifica si ya está como administrador
fltmc >nul 2>&1 || (
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

:: 4. Ejecuta PowerShell como admin con políticas seguras
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

pause
