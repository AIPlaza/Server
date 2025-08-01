# ╭────────────────────────────────────────────╮
# │ Script Automático de Configuración SSH     │
# │ Autor: TECHNOPLAY / CRYPTOPLAZA            │
# ╰────────────────────────────────────────────╯

param(
    [string]$UsuarioSSH = "node2",
    [string]$PasswordSSH = "",
    [string]$NombreMiniPC = ""
)

function Detectar-CarpetaDescargas {
    $idioma = (Get-Culture).Name
    $descargas = if ($idioma.StartsWith("es")) { "$env:USERPROFILE\Descargas" } else { "$env:USERPROFILE\Downloads" }
    if (-not (Test-Path $descargas)) {
        New-Item -ItemType Directory -Path $descargas | Out-Null
    }
    return $descargas
}

# === CONFIG SSH === #
Write-Host "`n[1/3] Configurando SSH..." -ForegroundColor Cyan
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

# === INFO Y EXPORTACION === #
Write-Host "`n[2/3] Obteniendo información de red..." -ForegroundColor Cyan
$ipPrivada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
$ipPublica = try { Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10 } catch { "Manual" }
$fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$infoFinal = [PSCustomObject]@{
    NombreEquipo = if ($NombreMiniPC) { $NombreMiniPC } else { $env:COMPUTERNAME }
    UsuarioSSH = $UsuarioSSH
    PasswordSSH = $PasswordSSH
    Puerto = 22
    IPPrivada = $ipPrivada
    IPPublica = $ipPublica
    Fecha = $fecha
}

$carpeta = Detectar-CarpetaDescargas
$credPath = Join-Path $carpeta "ssh-credentials-$($env:COMPUTERNAME).json"
$infoFinal | ConvertTo-Json -Depth 3 | Out-File $credPath -Encoding UTF8

# === RESUMEN FINAL === #
Write-Host "`n[3/3] Resumen:" -ForegroundColor Cyan
Write-Host "Equipo     : $($infoFinal.NombreEquipo)"
Write-Host "IP Pública : $($infoFinal.IPPublica)"
Write-Host "IP Privada : $($infoFinal.IPPrivada)"
Write-Host "Usuario    : $UsuarioSSH"
Write-Host "Contraseña : $PasswordSSH"
Write-Host "Puerto SSH : 22"
Write-Host "Fecha      : $fecha"
Write-Host "`n✔ Archivo guardado en: $credPath" -ForegroundColor Green
