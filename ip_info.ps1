\
# ------------------------------------------
# Exportar configuración IP del adaptador Ethernet a JSON
# ------------------------------------------

Write-Host "`n Exportando configuración IP del adaptador Ethernet..." -ForegroundColor Cyan

# Detectar adaptador Ethernet activo
$ethernet = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -like "*Ethernet*" }

if (-not $ethernet) {
    Write-Host "No se encontró adaptador Ethernet activo." -ForegroundColor Red
    exit
}

$alias = $ethernet.InterfaceAlias
$ipInfo = Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4
$dnsInfo = Get-DnsClientServerAddress -InterfaceAlias $alias

# Armar objeto
$result = [PSCustomObject]@{
    Timestamp      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    AdapterAlias   = $alias
    IPAddress      = $ipInfo.IPAddress
    PrefixLength   = $ipInfo.PrefixLength
    DefaultGateway = $ipInfo.DefaultGateway
    DNSServers     = $dnsInfo.ServerAddresses
}

# Detectar carpeta de descargas (Downloads o Descargas)
$downloadsFolders = @("Downloads", "Descargas")
$downloadPath = $null
foreach ($folder in $downloadsFolders) {
    $candidate = Join-Path $env:USERPROFILE $folder
    if (Test-Path $candidate) {
        $downloadPath = $candidate
        break
    }
}

if (-not $downloadPath) {
    Write-Host "No se encontró carpeta de descargas válida (Downloads o Descargas)." -ForegroundColor Red
    exit
}

# Crear nombre de archivo con timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonPath = Join-Path $downloadPath "ip_info_$timestamp.json"

# Guardar el JSON
$result | ConvertTo-Json -Depth 4 | Out-File -Encoding UTF8 $jsonPath

Write-Host "`n Información exportada en:" -ForegroundColor Green
Write-Host $jsonPath -ForegroundColor Yellow
