
# ╭────────────────────────────────────────────╮
# │ Automatic SSH Setup Script (EN Version)   │
# │ Author: TECHNOPLAY / CRYPTOPLAZA          │
# ╰────────────────────────────────────────────╯

param(
    [string]$UsuarioSSH = "node2",
    [string]$PasswordSSH = "",
    [string]$NombreMiniPC = ""
)

function Detect-DownloadsFolder {
    $culture = (Get-Culture).Name
    $folder = if ($culture.StartsWith("es")) { "$env:USERPROFILE\Descargas" } else { "$env:USERPROFILE\Downloads" }
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
    return $folder
}

# === CONFIGURE SSH === #
Write-Host "
[1/3] Configuring SSH..." -ForegroundColor Cyan
try {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
    Write-Host "✔ OpenSSH successfully installed." -ForegroundColor Green
} catch {
    Write-Host "⚠ SSH already installed or error: $($_.Exception.Message)" -ForegroundColor Yellow
}
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Generate random password if empty
if ([string]::IsNullOrEmpty($PasswordSSH)) {
    $PasswordSSH = -join ((33..126) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    Write-Host "🔐 Generated Password: $PasswordSSH" -ForegroundColor Cyan
}

# Create SSH user
$SecurePassword = ConvertTo-SecureString $PasswordSSH -AsPlainText -Force
if (Get-LocalUser -Name $UsuarioSSH -ErrorAction SilentlyContinue) {
    Set-LocalUser -Name $UsuarioSSH -Password $SecurePassword
} else {
    New-LocalUser -Name $UsuarioSSH -Password $SecurePassword -Description "SSH User"
}
Add-LocalGroupMember -Group "Administrators" -Member $UsuarioSSH
New-NetFirewallRule -Name "SSH-Inbound" -DisplayName "SSH Server (Port 22)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue

# === SYSTEM INFO + EXPORT === #
Write-Host "
[2/3] Getting network info..." -ForegroundColor Cyan
$ipPrivada = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
$ipPublica = try { Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10 } catch { "Manual" }
$fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$infoFinal = [PSCustomObject]@{
    Hostname   = if ($NombreMiniPC) { $NombreMiniPC } else { $env:COMPUTERNAME }
    SSH_User   = $UsuarioSSH
    Password   = $PasswordSSH
    Port       = 22
    Local_IP   = $ipPrivada
    Public_IP  = $ipPublica
    Timestamp  = $fecha
}

$folder = Detect-DownloadsFolder
$path = Join-Path $folder "ssh-credentials-$($env:COMPUTERNAME).json"
$infoFinal | ConvertTo-Json -Depth 3 | Out-File $path -Encoding UTF8

# === FINAL SUMMARY === #
Write-Host "
[3/3] Summary:" -ForegroundColor Cyan
Write-Host "Hostname   : $($infoFinal.Hostname)"
Write-Host "Public IP  : $($infoFinal.Public_IP)"
Write-Host "Local IP   : $($infoFinal.Local_IP)"
Write-Host "SSH User   : $UsuarioSSH"
Write-Host "Password   : $PasswordSSH"
Write-Host "SSH Port   : 22"
Write-Host "Timestamp  : $fecha"
Write-Host "
✔ Credentials saved at: $path" -ForegroundColor Green
