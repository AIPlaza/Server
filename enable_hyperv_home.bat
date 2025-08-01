@echo off
color 0A
title Habilitar Hyper-V en Windows 10/11 Home Edition

echo ================================================
echo HABILITANDO HYPER-V EN WINDOWS HOME
echo ================================================

echo Este proceso puede tardar unos minutos...
echo.

dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /quiet /norestart
dism /online /enable-feature /featurename:Microsoft-Hyper-V /all /quiet /norestart
dism /online /enable-feature /featurename:Microsoft-Hyper-V-Management-Clients /all /quiet /norestart
dism /online /enable-feature /featurename:Microsoft-Hyper-V-Management-PowerShell /all /quiet /norestart
dism /online /enable-feature /featurename:Microsoft-Hyper-V-Hypervisor /all /quiet /norestart
dism /online /enable-feature /featurename:Microsoft-Hyper-V-Services /all /quiet /norestart
dism /online /enable-feature /featurename:Microsoft-Hyper-V-Tools-All /all /quiet /norestart

echo.
echo ================================================
echo HYPER-V HABILITADO (si no hay errores)
echo ES RECOMENDABLE REINICIAR EL SISTEMA AHORA
echo ================================================
pause
