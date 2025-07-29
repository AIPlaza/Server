# Asignar IP fija
New-NetIPAddress -InterfaceAlias "Ethernet" `
  -IPAddress "50.190.105.82" `
  -PrefixLength 28 `
  -DefaultGateway "50.190.105.94"

# Configurar DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
  -ServerAddresses ("8.8.8.8", "1.1.1.1")
