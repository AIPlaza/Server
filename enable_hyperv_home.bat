@echo off
color 0A
title Activar soporte Hyper-V en Windows 10/11 Home

echo =================================================
echo ACTIVANDO Hyper-V EN WINDOWS HOME (NO SOPORTADO)
echo =================================================

echo Paso 1: Descargando componentes ocultos...

pushd "%~dp0"
dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum >hyperv.txt
for /f %%i in ('findstr /i . hyperv.txt 2^>nul') do (
    echo Instalando: %%i
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
)
del hyperv.txt

echo Paso 2: Habilitando características Hyper-V...

dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
dism /online /enable-feature /featurename:Microsoft-Hyper-V-Management-PowerShell /all /norestart

echo =================================================
echo 🔁 HYPER-V INSTALADO. REINICIA TU PC PARA FINALIZAR
echo =================================================
pause
