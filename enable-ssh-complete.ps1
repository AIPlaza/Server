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
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "OpenSSH Server instalado correctamente" -ForegroundColor Green
} catch {
    Write-Host "Error instalando OpenSSH: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
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
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "Puerto 22 abierto en el Firewall" -ForegroundColor Green
} catch {
    Write-Host "Regla de firewall ya existe o error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Paso 4: Generar contraseña segura si no se proporcionó
if ([string]::IsNullOrEmpty($PasswordSSH)) {
    $PasswordSSH = -join ((33..126) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    Write-Host "Contraseña generada automáticamente" -ForegroundColor Cyan
}

# Paso 5: Crear usuario SSH dedicado
Write-Host "`nCreando usuario SSH: $UsuarioSSH"
try {
    $existeUsuario = Get-LocalUser -Name $UsuarioSSH -ErrorAction SilentlyContinue
    if ($existeUsuario) {
        Write-Host "Usuario ya existe, actualizando contraseña..." -ForegroundColor Yellow
        $SecurePassword = ConvertTo-SecureString $PasswordSSH -AsPlainText -Force
        Set-LocalUser -Name $UsuarioSSH -Password $SecurePassword
    } else {
        $SecurePassword = ConvertTo-SecureString $PasswordSSH -AsPlainText -Force
        New-LocalUser -Name $UsuarioSSH -Password $SecurePassword -Description "Usuario SSH para gestión remota"
        Write-Host "Usuario creado correctamente" -ForegroundColor Green
    }
    Add-LocalGroupMember -Group "Administradores" -Member $UsuarioSSH -ErrorAction SilentlyContinue
    Write-Host "Usuario agregado al grupo Administradores" -ForegroundColor Green
} catch {
    Write-Host "Error creando usuario: $($_.Exception.Message)" -ForegroundColor Red
}

# Paso 6: Obtener información del sistema
Write-Host "`nRecopilando información del sistema..."
$InfoSistema = @{
    NombreEquipo = if ([string]::IsNullOrEmpty($NombreMiniPC)) { $env:COMPUTERNAME } else { $NombreMiniPC }
    IPPrivada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
    UsuarioSSH = $UsuarioSSH
    PasswordSSH = $PasswordSSH
    Puerto = 22
    FechaConfiguracion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# Paso 7: Obtener IP pública
Write-Host "Obteniendo IP pública..."
try {
    $IPPublica = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10
    $InfoSistema.IPPublica = $IPPublica
    Write-Host "IP Pública: $IPPublica" -ForegroundColor Green
} catch {
    Write-Host "No se pudo obtener IP pública automáticamente" -ForegroundColor Yellow
    $InfoSistema.IPPublica = "Verificar manualmente"
}

# Paso 8: Verificar estado del servicio
Write-Host "`nVerificando configuración..."
$EstadoSSH = Get-Service sshd
Write-Host "Estado del servicio SSH: $($EstadoSSH.Status)" -ForegroundColor Cyan

# Paso 9: Generar archivo de credenciales
$CredencialesJSON = $InfoSistema | ConvertTo-Json -Depth 2
$ArchivoCredenciales = "ssh-credentials-$($InfoSistema.NombreEquipo).json"
$CredencialesJSON | Out-File -FilePath $ArchivoCredenciales -Encoding UTF8
Write-Host "`nArchivo de credenciales generado: $ArchivoCredenciales" -ForegroundColor Green

# Paso 10: Mostrar resumen sin emojis
Write-Host "`n====================== CONFIGURACIÓN SSH ======================" -ForegroundColor Cyan
Write-Host "Nombre del Equipo: $($InfoSistema.NombreEquipo)" -ForegroundColor White
Write-Host "IP Pública: $($InfoSistema.IPPublica)" -ForegroundColor White
Write-Host "IP Privada: $($InfoSistema.IPPrivada)" -ForegroundColor White
Write-Host "Usuario SSH: " -NoNewline -ForegroundColor White
Write-Host $InfoSistema.UsuarioSSH -ForegroundColor Yellow
Write-Host "Contraseña: " -NoNewline -ForegroundColor White
Write-Host $InfoSistema.PasswordSSH -ForegroundColor Yellow
Write-Host "Puerto: $($InfoSistema.Puerto)" -ForegroundColor White
Write-Host "Configurado: $($InfoSistema.FechaConfiguracion)" -ForegroundColor White
Write-Host "==============================================================" -ForegroundColor Cyan

$ComandoConexion = "ssh $($InfoSistema.UsuarioSSH)@$($InfoSistema.IPPublica)"
Write-Host "`nCOMANDO PARA CONECTAR DESDE HQ:" -ForegroundColor Cyan
Write-Host $ComandoConexion -ForegroundColor Yellow

Write-Host "`nEnviar este archivo al HQ: $ArchivoCredenciales" -ForegroundColor Green
