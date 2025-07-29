# Server

# Documentación SSH para Gestión Remota de Windows

## Resumen General

Esta documentación proporciona una guía completa para habilitar y configurar acceso SSH en MiniPCs remotos con Windows 10/11, incluyendo configuración de usuarios, contraseñas y envío seguro de credenciales al servidor central (headquarter).

---

## 📄 Script PowerShell: enable-ssh-complete.ps1

### Propósito
Habilita OpenSSH Server, crea usuario dedicado para SSH, configura contraseña segura y prepara el sistema para gestión remota centralizada.

### Ubicación del Script
```
fase0_poc/powershell/enable-ssh-complete.ps1
```

### Script Completo para Copiar y Pegar

```powershell
# enable-ssh-complete.ps1
# ------------------------------------------
# Configuración completa de SSH en Windows 10/11
# Incluye: instalación, usuario, contraseña y configuración
# EJECUTAR COMO ADMINISTRADOR
# ------------------------------------------

param(
    [string]$UsuarioSSH = "sshremoto",
    [string]$PasswordSSH = "",
    [string]$NombreMiniPC = ""
)

Write-Host "🔧 Iniciando configuración completa de SSH..." -ForegroundColor Green

# Paso 1: Instalar OpenSSH Server
Write-Host "`n📦 Instalando OpenSSH Server..."
try {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "✅ OpenSSH Server instalado correctamente" -ForegroundColor Green
} catch {
    Write-Host "❌ Error instalando OpenSSH: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Paso 2: Iniciar y configurar el servicio
Write-Host "`n🚀 Configurando servicio SSH..."
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
Write-Host "✅ Servicio SSH iniciado y configurado para inicio automático" -ForegroundColor Green

# Paso 3: Configurar Firewall
Write-Host "`n🔥 Configurando Firewall de Windows..."
try {
    New-NetFirewallRule -Name "SSH-Inbound" -DisplayName "SSH Server (Puerto 22)" `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "✅ Puerto 22 abierto en el Firewall" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Regla de firewall ya existe o error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Paso 4: Generar contraseña segura si no se proporcionó
if ([string]::IsNullOrEmpty($PasswordSSH)) {
    $PasswordSSH = -join ((33..126) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    Write-Host "🔐 Contraseña generada automáticamente" -ForegroundColor Cyan
}

# Paso 5: Crear usuario SSH dedicado
Write-Host "`n👤 Creando usuario SSH: $UsuarioSSH"
try {
    # Verificar si el usuario ya existe
    $existeUsuario = Get-LocalUser -Name $UsuarioSSH -ErrorAction SilentlyContinue
    if ($existeUsuario) {
        Write-Host "⚠️ Usuario $UsuarioSSH ya existe, actualizando contraseña..." -ForegroundColor Yellow
        $SecurePassword = ConvertTo-SecureString $PasswordSSH -AsPlainText -Force
        Set-LocalUser -Name $UsuarioSSH -Password $SecurePassword
    } else {
        $SecurePassword = ConvertTo-SecureString $PasswordSSH -AsPlainText -Force
        New-LocalUser -Name $UsuarioSSH -Password $SecurePassword -Description "Usuario SSH para gestión remota"
        Write-Host "✅ Usuario $UsuarioSSH creado correctamente" -ForegroundColor Green
    }
    
    # Agregar usuario al grupo de administradores locales
    Add-LocalGroupMember -Group "Administradores" -Member $UsuarioSSH -ErrorAction SilentlyContinue
    Write-Host "✅ Usuario agregado al grupo Administradores" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error creando usuario: $($_.Exception.Message)" -ForegroundColor Red
}

# Paso 6: Obtener información del sistema
Write-Host "`n📋 Recopilando información del sistema..."
$InfoSistema = @{
    NombreEquipo = if ([string]::IsNullOrEmpty($NombreMiniPC)) { $env:COMPUTERNAME } else { $NombreMiniPC }
    IPPrivada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
    UsuarioSSH = $UsuarioSSH
    PasswordSSH = $PasswordSSH
    Puerto = 22
    FechaConfiguracion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

# Paso 7: Obtener IP pública
Write-Host "🌐 Obteniendo IP pública..."
try {
    $IPPublica = Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10
    $InfoSistema.IPPublica = $IPPublica
    Write-Host "✅ IP Pública: $IPPublica" -ForegroundColor Green
} catch {
    Write-Host "⚠️ No se pudo obtener IP pública automáticamente" -ForegroundColor Yellow
    $InfoSistema.IPPublica = "Verificar manualmente"
}

# Paso 8: Verificar estado del servicio
Write-Host "`n🔍 Verificando configuración..."
$EstadoSSH = Get-Service sshd
Write-Host "📊 Estado del servicio SSH: $($EstadoSSH.Status)" -ForegroundColor Cyan

# Paso 9: Generar archivo de credenciales para enviar al headquarter
$CredencialesJSON = $InfoSistema | ConvertTo-Json -Depth 2
$ArchivoCredenciales = "ssh-credentials-$($InfoSistema.NombreEquipo).json"
$CredencialesJSON | Out-File -FilePath $ArchivoCredenciales -Encoding UTF8

Write-Host "`n📄 Archivo de credenciales generado: $ArchivoCredenciales" -ForegroundColor Green

# Paso 10: Mostrar resumen de configuración
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "🎉 CONFIGURACIÓN SSH COMPLETADA" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "📍 Nombre del Equipo: $($InfoSistema.NombreEquipo)" -ForegroundColor White
Write-Host "🌐 IP Pública: $($InfoSistema.IPPublica)" -ForegroundColor White
Write-Host "🏠 IP Privada: $($InfoSistema.IPPrivada)" -ForegroundColor White
Write-Host "👤 Usuario SSH: $($InfoSistema.UsuarioSSH)" -ForegroundColor White
Write-Host "🔐 Contraseña: $($InfoSistema.PasswordSSH)" -ForegroundColor Yellow
Write-Host "🚪 Puerto: $($InfoSistema.Puerto)" -ForegroundColor White
Write-Host "📅 Configurado: $($InfoSistema.FechaConfiguracion)" -ForegroundColor White
Write-Host "="*60 -ForegroundColor Cyan

# Paso 11: Comando de conexión para copiar
$ComandoConexion = "ssh $($InfoSistema.UsuarioSSH)@$($InfoSistema.IPPublica)"
Write-Host "`n📋 COMANDO PARA CONECTAR DESDE HEADQUARTER:" -ForegroundColor Cyan
Write-Host $ComandoConexion -ForegroundColor Yellow

Write-Host "`n📤 ENVIAR ARCHIVO AL HEADQUARTER:" -ForegroundColor Cyan
Write-Host "Archivo generado: $ArchivoCredenciales" -ForegroundColor Yellow
Write-Host "Contenido a enviar por email/Teams/Slack:" -ForegroundColor Gray
Write-Host $CredencialesJSON -ForegroundColor Gray

Write-Host "`n✅ Configuración completada. El MiniPC está listo para gestión remota." -ForegroundColor Green
```

---

## 🚀 Guía de Implementación Paso a Paso

### Prerrequisitos
- ✅ Windows 10/11 en el MiniPC remoto
- ✅ Privilegios de Administrador
- ✅ Conexión a Internet
- ✅ Acceso al router para port forwarding (si es necesario)

### 📋 Método 1: Ejecución Básica (Recomendado)

```powershell
# Copiar y pegar en PowerShell como Administrador:
# Configuración automática con valores por defecto
.\enable-ssh-complete.ps1
```

### 📋 Método 2: Configuración Personalizada

```powershell
# Copiar y pegar con parámetros personalizados:
.\enable-ssh-complete.ps1 -UsuarioSSH "adminremoto" -PasswordSSH "MiPassword123!" -NombreMiniPC "MiniPC-USA-01"
```

### 📋 Método 3: Descarga y Ejecución Remota

```powershell
# Descargar y ejecutar desde repositorio remoto:
$url = "https://raw.githubusercontent.com/tu-usuario/scripts/main/enable-ssh-complete.ps1"
Invoke-Expression (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
```

---

## 🔧 Configuración Detallada del Usuario SSH

### Creación Manual de Usuario (Alternativa)

Si prefieres crear el usuario manualmente, ejecuta estos comandos por separado:

```powershell
# 1. Crear usuario SSH
$NombreUsuario = "sshremoto"
$Password = "TuPasswordSeguro123!"
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
New-LocalUser -Name $NombreUsuario -Password $SecurePassword -Description "Usuario SSH Remoto"

# 2. Agregar a grupo Administradores
Add-LocalGroupMember -Group "Administradores" -Member $NombreUsuario

# 3. Configurar para que no expire la contraseña
Set-LocalUser -Name $NombreUsuario -PasswordNeverExpires $true

# 4. Verificar creación
Get-LocalUser -Name $NombreUsuario
```

### Configuración de Nombres de Equipo

```powershell
# Cambiar nombre del equipo (requiere reinicio)
$NuevoNombre = "MiniPC-USA-01"
Rename-Computer -NewName $NuevoNombre -Restart

# Verificar nombre actual
$env:COMPUTERNAME
```

---

## 📤 Envío de Credenciales al Headquarter

### Formato JSON Generado Automáticamente

El script genera un archivo JSON con toda la información necesaria:

```json
{
  "NombreEquipo": "MiniPC-USA-01",
  "IPPublica": "50.190.105.81",
  "IPPrivada": "192.168.1.100",
  "UsuarioSSH": "sshremoto",
  "PasswordSSH": "Xy9#mK2$pL8@",
  "Puerto": 22,
  "FechaConfiguracion": "2025-07-29 15:30:45"
}
```

### 📧 Métodos para Enviar Credenciales

#### Opción 1: Email Seguro
```powershell
# Comando para enviar por email (requiere configuración SMTP)
$EmailBody = Get-Content "ssh-credentials-$env:COMPUTERNAME.json" | Out-String
Send-MailMessage -From "minipc@empresa.com" -To "admin@headquarter.com" `
  -Subject "Credenciales SSH - $env:COMPUTERNAME" -Body $EmailBody `
  -SmtpServer "smtp.gmail.com" -Port 587 -UseSsl
```

#### Opción 2: Webhook/API REST
```powershell
# Enviar a API del headquarter
$CredencialesJSON = Get-Content "ssh-credentials-$env:COMPUTERNAME.json"
$Headers = @{ "Content-Type" = "application/json" }
Invoke-RestMethod -Uri "https://headquarter.com/api/ssh-credentials" `
  -Method POST -Body $CredencialesJSON -Headers $Headers
```

#### Opción 3: Teams/Slack (Manual)
1. Abrir el archivo `ssh-credentials-NOMBREPC.json`
2. Copiar el contenido
3. Enviarlo por Teams/Slack al administrador del headquarter

---

## 🔍 Verificación y Pruebas

### Comandos de Verificación Local

```powershell
# Verificar servicio SSH
Get-Service sshd | Format-Table Name, Status, StartType

# Verificar usuario creado
Get-LocalUser sshremoto | Format-Table Name, Enabled, PasswordRequired

# Verificar regla de firewall
Get-NetFirewallRule -DisplayName "*SSH*" | Format-Table DisplayName, Enabled, Direction

# Probar conexión local
ssh sshremoto@localhost
```

### Prueba de Conexión desde Headquarter

```bash
# Desde Linux/Mac en headquarter
ssh sshremoto@50.190.105.81

# Con puerto específico si es diferente
ssh -p 22 sshremoto@50.190.105.81

# Primer conexión (aceptar fingerprint)
# Escribir "yes" cuando pregunte sobre el fingerprint
```

---

## 🛡️ Configuración de Seguridad Avanzada

### Configuración SSH Personalizada

```powershell
# Crear archivo de configuración SSH personalizado
$ConfigSSH = @"
# Configuración SSH para MiniPC
Port 22
Protocol 2
PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
"@

$ConfigSSH | Out-File -FilePath "C:\ProgramData\ssh\sshd_config_custom" -Encoding ASCII
```

### Port Forwarding en Router

Si el MiniPC está detrás de NAT, configura port forwarding:

1. **Acceder al router**: Generalmente `192.168.1.1` o `192.168.0.1`
2. **Ir a Port Forwarding/Virtual Servers**
3. **Crear regla**:
   - Puerto externo: `22` (o uno personalizado como `2222`)
   - IP interna: IP del MiniPC (ej: `192.168.1.100`)
   - Puerto interno: `22`
   - Protocolo: `TCP`

---

## 🔧 Solución de Problemas Comunes

### Error: "Acceso Denegado"
```powershell
# Verificar que PowerShell se ejecuta como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Ejecutar como Administrador" -ForegroundColor Red
    exit 1
}
```

### Error: "No se puede conectar"
```powershell
# Verificar estado del servicio
Get-Service sshd | Restart-Service

# Verificar puerto abierto
Test-NetConnection -ComputerName localhost -Port 22

# Verificar logs de SSH
Get-WinEvent -LogName "OpenSSH/Operational" | Select-Object -First 10
```

### Error: "Usuario no puede hacer login"
```powershell
# Verificar permisos del usuario
$Usuario = "sshremoto"
Get-LocalGroupMember -Group "Administradores" | Where-Object {$_.Name -like "*$Usuario*"}

# Resetear contraseña si es necesario
$NuevaPassword = ConvertTo-SecureString "NuevaPassword123!" -AsPlainText -Force
Set-LocalUser -Name $Usuario -Password $NuevaPassword
```

---

## 📊 Inventario y Gestión Centralizada

### Archivo de Inventario en Headquarter

```json
{
  "minipcs": [
    {
      "id": "minipc-001",
      "nombre": "MiniPC-USA-01",
      "ip_publica": "50.190.105.81",
      "ip_privada": "192.168.1.100",
      "usuario_ssh": "sshremoto",
      "puerto": 22,
      "ubicacion": "New York, USA",
      "estado": "activo",
      "ultima_conexion": "2025-07-29 15:45:00",
      "aplicaciones": ["Salad", "Honeygain", "EarnApp"]
    }
  ]
}
```

### Script de Conexión Masiva (Headquarter)

```bash
#!/bin/bash
# connect-all-minipcs.sh
# Conectar a todos los MiniPCs desde headquarter

MINIPCS=(
    "sshremoto@50.190.105.81"
    "sshremoto@52.180.140.92"
    "sshremoto@40.120.255.73"
)

for minipc in "${MINIPCS[@]}"; do
    echo "🔗 Conectando a $minipc..."
    ssh -o ConnectTimeout=10 $minipc "echo 'Conexión exitosa a $(hostname)'"
done
```

---

## 🎯 Próximos Pasos

Después de la configuración exitosa de SSH:

1. **✅ Configurar autenticación por llaves SSH** (más seguro que contraseñas)
2. **✅ Implementar monitoreo automatizado** con scripts
3. **✅ Configurar backup automático** de configuraciones
4. **✅ Implementar Ansible/Salt** para gestión masiva
5. **✅ Configurar alertas** por email/Teams cuando hay problemas

---

## 📚 Estructura de Documentación

```
docs/
├── fase0_poc/
│   ├── powershell/
│   │   ├── enable-ssh-complete.md
│   │   └── scripts/
│   │       └── enable-ssh-complete.ps1
│   └── configuracion-inicial.md
├── inventario/
│   ├── minipcs-activos.json
│   └── credenciales-ssh.json
└── troubleshooting/
    ├── problemas-comunes.md
    └── logs-ssh.md
```

---

*Esta documentación proporciona todo lo necesario para configurar SSH de forma segura y profesional en tus MiniPCs remotos, facilitando la gestión centralizada desde tu headquarter en Colombia.*
