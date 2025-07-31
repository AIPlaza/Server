# enable-ssh-complete.ps1
# ------------------------------------------
# Configuración completa de SSH en Windows 10/11
# EJECUTAR COMO ADMINISTRADOR
# ------------------------------------------

param(
    [string]$UsuarioSSH = "matrixnode",
    [string]$PasswordSSH = "",
    [string]$NombreMiniPC = ""
)

Write-Host "Iniciando configuración completa de SSH..." -ForegroundColor Green

# Paso 1: Instalar OpenSSH Server
Write-Host "`nInstalando OpenSSH Server..."
try {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
    Write-Host "OpenSSH Server instalado correctamente" -ForegroundColor Green
} catch {
    Write-Host "Error instalando OpenSSH: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Paso 2: Iniciar y configurar el servicio
Write-Host "`nConfigurando servicio SSH..."
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
Write-Host "Servicio SSH iniciado y configurado para inicio automático" -ForegroundColor Green

# Paso 3: Configurar Firewall
Write-Host "`nConfigurando Firewall de Windows..."
try {
    New-NetFirewallRule -Name "SSH-Inbound" -DisplayName "SSH Server (Puerto 22)" `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction Stop
    Write-Host "Puerto 22 abierto en el Firewall" -ForegroundColor Green
} catch {
    Write-Host "Regla de firewall ya existe o error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Paso 4: Generar contraseña si está vacía
if ([string]::IsNullOrEmpty($PasswordSSH)) {
    $PasswordSSH = -join ((33..126) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    Write-Host "Contraseña generada automáticamente" -ForegroundColor Cyan
}

# Paso 5: Crear usuario SSH
Write-Host "`nCreando usuario SSH: $UsuarioSSH"
try {
    $SecurePassword = ConvertTo-SecureString $PasswordSSH -AsPlainText -Force
    $existeUsuario = Get-LocalUser -Name $UsuarioSSH -ErrorAction SilentlyContinue
    if ($existeUsuario) {
        Set-LocalUser -Name $UsuarioSSH -Password $SecurePassword
        Write-Host "Usuario existente, contraseña actualizada" -ForegroundColor Yellow
    } else {
        New-LocalUser -Name $UsuarioSSH -Password $SecurePassword -Description "Usuario SSH"
        Write-Host "Usuario creado correctamente" -ForegroundColor Green
    }
    Add-LocalGroupMember -Group "Administradores" -Member $UsuarioSSH -ErrorAction SilentlyContinue
    Write-Host "Usuario agregado al grupo Administradores" -ForegroundColor Green
} catch {
    Write-Host "Error creando usuario: $($_.Exception.Message)" -ForegroundColor Red
}

# Paso 6: Info del sistema
Write-Host "`nObteniendo información del sistema..."
$InfoSistema = @{
    NombreEquipo = if ($NombreMiniPC) { $NombreMiniPC } else { $env:COMPUTERNAME }
    IPPrivada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
    UsuarioSSH = $UsuarioSSH
    PasswordSSH = $PasswordSSH
    Puerto = 22
    FechaConfiguracion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

try {
    $IPPublica = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10
    $InfoSistema.IPPublica = $IPPublica
    Write-Host "IP Pública detectada: $IPPublica" -ForegroundColor Green
} catch {
    $InfoSistema.IPPublica = "Manual"
    Write-Host "No se pudo obtener IP pública" -ForegroundColor Yellow
}

# Paso 7: Verificar estado SSH
$EstadoSSH = Get-Service sshd
Write-Host "`nEstado del servicio SSH: $($EstadoSSH.Status)" -ForegroundColor Cyan

# Paso 8: Guardar credenciales
$ArchivoCredenciales = "ssh-credentials-$($InfoSistema.NombreEquipo).json"
$InfoSistema | ConvertTo-Json -Depth 3 | Out-File $ArchivoCredenciales -Encoding UTF8
Write-Host "Archivo de credenciales guardado: $ArchivoCredenciales" -ForegroundColor Green

# Paso 9: Mostrar resumen
Write-Host "`n====================== SSH CONFIG ======================" -ForegroundColor Cyan
Write-Host "Equipo: $($InfoSistema.NombreEquipo)" -ForegroundColor White
Write-Host "IP Pública: $($InfoSistema.IPPublica)" -ForegroundColor White
Write-Host "IP Privada: $($InfoSistema.IPPrivada)" -ForegroundColor White
Write-Host "Usuario SSH: $($InfoSistema.UsuarioSSH)" -ForegroundColor Yellow
Write-Host "Contraseña : $($InfoSistema.PasswordSSH)" -ForegroundColor Yellow
Write-Host "Puerto     : 22" -ForegroundColor White
Write-Host "Fecha      : $($InfoSistema.FechaConfiguracion)" -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "`nConectar desde HQ: ssh $($InfoSistema.UsuarioSSH)@$($InfoSistema.IPPublica)" -ForegroundColor Green
