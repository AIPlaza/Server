# IP_CONFIG

Write-Host "`nExportando configuración IP del adaptador de red activo..." -ForegroundColor Cyan

# Detectar adaptador activo físico (no Wi-Fi/Bluetooth)
$adapter = Get-NetAdapter | Where-Object {
    $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Wi-Fi|Wireless|Bluetooth'
} | Select-Object -First 1

if (-not $adapter) {
    Write-Host "No se encontró adaptador de red Ethernet activo." -ForegroundColor Red
    exit
}

# Solicitar IP manual
$ip = Read-Host "Ingresa la IP fija que deseas asignar (ej: 50.190.105.83)"
$gateway = "50.190.105.94"
$prefix = 28
$dns = @("8.8.8.8", "1.1.1.1")

# Asignar IP y DNS
New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $ip -PrefixLength $prefix -DefaultGateway $gateway
Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dns

# Ruta correcta (Descargas o Downloads según idioma del sistema)
$downloadsPath = [System.IO.Path]::Combine($env:USERPROFILE, (Get-Culture).Name -like "es-*" ? "Descargas" : "Downloads")
if (-not (Test-Path $downloadsPath)) { $downloadsPath = "$env:USERPROFILE\Downloads" }

# Exportar datos a JSON
$export = [pscustomobject]@{
    Adaptador   = $adapter.Name
    IP_Asignada = $ip
    Gateway     = $gateway
    DNS         = $dns -join ", "
    Fecha       = (Get-Date).ToString("s")
}
$exportPath = "$downloadsPath\ip_config_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$export | ConvertTo-Json | Set-Content -Path $exportPath -Encoding UTF8

Write-Host "`nConfiguración aplicada y exportada a:"
Write-Host $exportPath -ForegroundColor Yellow
