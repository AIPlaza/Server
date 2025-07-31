# -----------------------------
# CONFIGURACIÓN INICIAL
# -----------------------------
$ipAddress     = "50.190.105.82"
$prefixLength  = 28
$defaultGateway = "50.190.105.94"
$dnsServers     = @("8.8.8.8", "8.8.4.4")  # Opcional

# -----------------------------
# DETECCIÓN AUTOMÁTICA DE ADAPTADOR ACTIVO
# -----------------------------
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true } | Select-Object -First 1

if (-not $adapter) {
    Write-Host "❌ No se encontró un adaptador de red activo." -ForegroundColor Red
    exit 1
}

$interfaceAlias = $adapter.Name
Write-Host "✅ Adaptador detectado: $interfaceAlias" -ForegroundColor Green

# -----------------------------
# REMOVER CONFIGURACIÓN IP ANTERIOR (si existe)
# -----------------------------
$existingIP = Get-NetIPAddress -InterfaceAlias $interfaceAlias -ErrorAction SilentlyContinue
if ($existingIP) {
    Write-Host "⚠️ Eliminando configuración IP anterior..."
    $existingIP | Remove-NetIPAddress -Confirm:$false
}

# -----------------------------
# APLICAR IP ESTÁTICA
# -----------------------------
New-NetIPAddress `
    -IPAddress $ipAddress `
    -PrefixLength $prefixLength `
    -InterfaceAlias $interfaceAlias `
    -DefaultGateway $defaultGateway

# -----------------------------
# CONFIGURAR DNS (opcional)
# -----------------------------
Set-DnsClientServerAddress `
    -InterfaceAlias $interfaceAlias `
    -ServerAddresses $dnsServers

Write-Host "🎉 Configuración de red aplicada con éxito." -ForegroundColor Cyan

