# ---------------------------------------------
# export_ip_config.ps1
# Exporta configuración IP del adaptador activo a JSON
# ---------------------------------------------

Write-Host "`n Exportando configuración IP del adaptador Ethernet..." -ForegroundColor Cyan

# Detectar adaptador Ethernet activo
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -like "*Ethernet*" }

if (-not $adapter) {
    Write-Host "No se encontró un adaptador Ethernet activo." -ForegroundColor Red
    exit
}

$alias = $adapter.InterfaceAlias
$config = Get-NetIPAddress -InterfaceAlias $alias

# Ruta de salida
$output = "$env:USERPROFILE\\Desktop\\ip_config_result.json"

# Exportar a JSON
$config | ConvertTo-Json -Depth 5 | Set-Content -Path $output -Encoding UTF8

Write-Host "Configuración IP exportada a: $output" -ForegroundColor Green
