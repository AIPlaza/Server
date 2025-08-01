@echo off
setlocal

REM ╭───────────────────────────────────────────────╮
REM │ Launcher de enable_ssh_complete.ps1 (Admin)  │
REM ╰───────────────────────────────────────────────╯

set SCRIPT=enable_ssh_complete.ps1

REM Detectar idioma del sistema para localizar la carpeta adecuada
for /f "tokens=*" %%i in ('powershell -NoProfile -Command ^
    "if ((Get-Culture).Name -like 'es-*') { Write-Output \"$env:USERPROFILE\\Descargas\" } else { Write-Output \"$env:USERPROFILE\\Downloads\" }"') do set DOWNLOADS=%%i

REM Ejecutar PowerShell como Administrador con el script
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%DOWNLOADS%\\%SCRIPT%\"'"

endlocal
