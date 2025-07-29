Perfecto. Aquí tienes la documentación generada para el archivo fase1_acceso/asignacion-ips.md en formato compatible con MkDocs:


---

📁 Ruta: docs/fase1_acceso/asignacion-ips.md
🔖 Etiqueta MkDocs: fase1_acceso/asignacion-ips.md


---

🌐 Asignación de IP Fija a MiniPCs Remotos

🎯 Objetivo

Asignar una IP pública fija (del bloque proporcionado por el ISP en EE.UU.) a cada MiniPC Windows conectado al switch PoE, permitiendo acceso remoto vía SSH desde Colombia con estabilidad y trazabilidad.


---

📦 Requisitos Previos

Elemento	Descripción

🖥 MiniPC	Conectado vía Ethernet al switch PoE
🌐 IP Fija	Rango usable del ISP: 50.190.105.81 a 50.190.105.93
📍 Gateway	50.190.105.94
🎭 Subnet Mask	255.255.255.240 (CIDR /28)
🔐 DNS	8.8.8.8, 1.1.1.1
👤 Usuario	Acceso local con privilegios de administrador
⚙ Interfaz	Acceso a la configuración de red de Windows



---

🧭 Instrucciones Paso a Paso

🔧 Método Gráfico (GUI)

1. Abrir: Configuración → Red e Internet → Cambiar opciones del adaptador


2. Seleccionar: clic derecho sobre Ethernet → Propiedades


3. Editar: Doble clic en "Protocolo de Internet versión 4 (TCP/IPv4)"


4. Asignar Manualmente:

IP: 50.190.105.82 (o la siguiente en tu bloque)

Máscara: 255.255.255.240

Gateway: 50.190.105.94



5. DNS:

Preferido: 8.8.8.8

Alternativo: 1.1.1.1



6. Guardar y reiniciar si es necesario.




---

💻 Método PowerShell (Recomendado para scripts)

# Asignar IP fija
New-NetIPAddress -InterfaceAlias "Ethernet" `
  -IPAddress "50.190.105.82" `
  -PrefixLength 28 `
  -DefaultGateway "50.190.105.94"

# Configurar DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
  -ServerAddresses ("8.8.8.8", "1.1.1.1")

🔔 Nota: Cambia "Ethernet" si el nombre de la interfaz es distinto (Get-NetAdapter).


---

✅ Validación en MiniPC (Post-configuración)

Ejecutar los siguientes comandos en PowerShell:

# Ver IP asignada
ipconfig

# Verificar conectividad con gateway
ping 50.190.105.94

# Verificar conexión a Internet
ping 8.8.8.8

# Ver IP pública desde navegador o consola
curl ifconfig.me


---

🛡 Checklist para el Operador Local

Acción	Estado

MiniPC conectado vía RJ45	☐
IP asignada del bloque (ej. .82–.93)	☐
Máscara /28 aplicada	☐
Gateway configurado (.94)	☐
DNS (8.8.8.8, 1.1.1.1) aplicados	☐
IP responde a ping externo	☐
SSH habilitado (ver fase0_preparacion/ssh.md)	☐
Puerto 22 permitido en firewall local	☐
Credenciales entregadas al administrador remoto	☐



---

🌍 Validación desde Colombia

Desde tu terminal:

ping 50.190.105.82
ssh admin@50.190.105.82

Resultado esperado: conexión estable y login exitoso.


---

🧠 Buenas Prácticas

Mantén una tabla de asignación en fase2_ipam_netbox/modelado.md

Usa etiquetas consistentes: cliente_a-nodo1, cliente_a-nodo2, etc.

Documenta cualquier cambio físico o lógico en Notion o NetBox



---

🔁 Flujo de Trabajo Estándar

[Operador] Configura IP fija y SSH
      ↓
[Admin remoto] Valida acceso desde Colombia
      ↓
[Ambos] Documentan nodo e IP
      ↓
[Operador] Pasa al siguiente MiniPC

Repite hasta cubrir todos los nodos del bloque asignado (máx. 13 IPs / usable: 81–93).


---

🧩 Siguiente Fase

📘 Siguiente archivo sugerido:
docs/fase2_ipam_netbox/instalacion.md – Instalación y configuración de NetBox como IPAM centralizado.

❓ ¿Deseas que lo generemos ahora, o prefieres documentar antes validaciones.md para las pruebas desde Colombia?


---

