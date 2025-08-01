# ╭────────────────────────────────────────────────────────────╮
# │ Script Automático de Configuración SSH + IP + Ping Test   │
# │ Autor: TECHNOPLAY / CRYPTOPLAZA                            │
# ╰────────────────────────────────────────────────────────────╯

param(
    [string]$UsuarioSSH = "node2",
    [string]$PasswordSSH = "",
    [string]$NombreMiniPC = ""
)

# === FUNCIONES AUXILIARES === #
function Obtener-AdaptadorEthernet {
    $adaptadores = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -like '*Ethernet*' }
    if ($adaptadores.Count -eq 0) {
        Write-Host "No se encontró un adaptador Ethernet activo." -ForegroundColor Red
        exit 1
    }
    return $adaptadores[0]
}

function Detectar-CarpetaDescargas {
    $idioma = (Get-Culture).Name
    $descargas = if ($idioma.StartsWith("es")) { "$env:USERPROFILE\Descargas" } else { "$env:USERPROFILE\Downloads" }
    if (-not (Test-Path $descargas)) {
        New-Item -ItemType Directory -Path $descargas | Out-Null
    }
    return $descargas
}

# === CONFIG SSH === #
Write-Host "\n[1/5] Configurando SSH..." -ForegroundColor Cyan
try {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
    Write-Host "✔ OpenSSH instalado correctamente." -ForegroundColor Green
} catch {
    Write-Host "⚠ SSH ya instalado o error: $($_.Exception.Message)" -ForegroundColor Yellow
}
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Generar contraseña aleatoria si vacía
if ([string]::IsNullOrEmpty($PasswordSSH)) {
    $PasswordSSH = -join ((33..126) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    Write-Host "🔐 Contraseña generada: $PasswordSSH" -ForegroundColor Cyan
}

# Crear usuario SSH
$SecurePassword = ConvertTo-SecureString $PasswordSSH -AsPlainText -Force
if (Get-LocalUser -Name $UsuarioSSH -ErrorAction SilentlyContinue) {
    Set-LocalUser -Name $UsuarioSSH -Password $SecurePassword
} else {
    New-LocalUser -Name $UsuarioSSH -Password $SecurePassword -Description "Usuario SSH"
}
Add-LocalGroupMember -Group "Administradores" -Member $UsuarioSSH
New-NetFirewallRule -Name "SSH-Inbound" -DisplayName "SSH Server (Puerto 22)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue

# === CONFIG IP FIJA === #
Write-Host "\n[2/5] Asignando IP Fija..." -ForegroundColor Cyan
$adaptador = Obtener-AdaptadorEthernet
$nombre = $adaptador.Name
$ip = Read-Host "Ingresa la IP fija que deseas asignar (ej: 50.190.105.83)"
$gateway = "50.190.105.94"
$prefixLength = 28
$dns = @("8.8.8.8", "1.1.1.1")
New-NetIPAddress -InterfaceAlias $nombre -IPAddress $ip -PrefixLength $prefixLength -DefaultGateway $gateway -ErrorAction Stop
Set-DnsClientServerAddress -InterfaceAlias $nombre -ServerAddresses $dns -ErrorAction Stop

# === TEST DE CONECTIVIDAD === #
Write-Host "\n[3/5] Ejecutando Ping Test..." -ForegroundColor Cyan
$pingResults = @()
$targets = @("localhost", "127.0.0.1", $gateway, "8.8.8.8", "google.com")
foreach ($target in $targets) {
    $result = Test-Connection -ComputerName $target -Count 2 -ErrorAction SilentlyContinue
    if ($result) {
        $status = "OK"
    } else {
        $status = "FAIL"
    }
    $pingResults += [PSCustomObject]@{
        Destino = $target
        Estado = $status
    }
}

# === GUARDAR RESULTADOS === #
Write-Host "\n[4/5] Guardando registros..." -ForegroundColor Cyan
$carpeta = Detectar-CarpetaDescargas
$fecha = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$credPath = Join-Path $carpeta "ssh-credentials-$($env:COMPUTERNAME).json"
$ipJsonPath = Join-Path $carpeta "config_ip.json"
$pingPath = Join-Path $carpeta "ping_test_$fecha.json"

$infoFinal = [PSCustomObject]@{
    NombreEquipo = if ($NombreMiniPC) { $NombreMiniPC } else { $env:COMPUTERNAME }
    UsuarioSSH = $UsuarioSSH
    PasswordSSH = $PasswordSSH
    Puerto = 22
    IPPrivada = $ip
    IPPublica = try { Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10 } catch { "Manual" }
    Gateway = $gateway
    Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$infoFinal | ConvertTo-Json -Depth 3 | Out-File $credPath -Encoding UTF8
$pingResults | ConvertTo-Json -Depth 3 | Out-File $pingPath -Encoding UTF8

$exportIP = [PSCustomObject]@{
    Fecha     = $infoFinal.Fecha
    Adaptador = $nombre
    IP        = $ip
    Gateway   = $gateway
    Mascara   = $prefixLength
    DNS       = $dns
}
$exportIP | ConvertTo-Json | Set-Content -Path $ipJsonPath -Encoding UTF8

# === RESUMEN FINAL === #
Write-Host "\n[5/5] Resumen:" -ForegroundColor Cyan
Write-Host "Equipo     : $($infoFinal.NombreEquipo)"
Write-Host "IP Pública : $($infoFinal.IPPublica)"
Write-Host "IP Privada : $($infoFinal.IPPrivada)"
Write-Host "Usuario    : $UsuarioSSH"
Write-Host "Contraseña : $PasswordSSH"
Write-Host "Puerto SSH : 22"
Write-Host "Fecha      : $($infoFinal.Fecha)"
Write-Host "\n✔ Archivos guardados en: $carpeta" -ForegroundColor Green
