@echo off
color 0A
title 🧠 Activar Hyper-V + WSL + VirtualMachinePlatform (Windows 10/11 Home)

echo ===============================================
echo PASO 1: Desbloqueando Hyper-V en Windows Home...
echo ===============================================
cd /d %SystemRoot%\servicing\Packages
dir *Hyper-V*.mum > %TEMP%\hyperv.txt
for /f %%i in (%TEMP%\hyperv.txt) do (
   echo Instalando %%i...
   dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
)
del %TEMP%\hyperv.txt

echo.
echo ===============================================
echo PASO 2: Activando Hyper-V
echo ===============================================
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart

echo.
echo ===============================================
echo PASO 3: Activando WSL
echo ===============================================
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

echo.
echo ===============================================
echo PASO 4: Activando VirtualMachinePlatform
echo ===============================================
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /norestart

echo.
echo ===============================================
echo ✅ PROCESO COMPLETO
echo 🔁 REINICIA TU EQUIPO AHORA
echo ===============================================
pause
