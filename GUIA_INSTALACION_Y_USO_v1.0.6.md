# Guía de instalación y uso — v1.0.6

## 1. Requisitos

```text
Issabel 5
Rocky Linux 8
Asterisk 18
Apache / PHP
MariaDB / MySQL
```

Instale herramientas básicas:

```bash
sudo -i
dnf -y install curl wget unzip cronie
```

## 2. Descargar

Una vez publicada la Release `v1.0.6`:

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.6.zip \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.6/issabel-callcenter-monitor-v1.0.6.zip
```

SHA-256:

```text
6754f47a476da7fdba5e53c8d2ea2b192048952dfca771f6ecf48da6928435df
```

## 3. Instalar

```bash
cd /root
rm -rf issabel-callcenter-monitor-v1.0.6
unzip issabel-callcenter-monitor-v1.0.6.zip
cd issabel-callcenter-monitor-v1.0.6
chmod +x install.sh
./install.sh
```

Ingrese correctamente el **nombre de empresa/call center** y el **nombre del contacto responsable** cuando el instalador los solicite.

## 4. Permisos

El instalador aplica:

```bash
chmod -R 0777 /var/www/html/callcenter-panel
```

Para reaplicar:

```bash
sudo -i
chmod -R 0777 /var/www/html/callcenter-panel
```

## 5. Verificar servicios

```bash
apachectl -t
systemctl status httpd --no-pager
systemctl status php-fpm --no-pager
systemctl status issabeldialer --no-pager
systemctl status crond --no-pager
asterisk -rx "core show version"
```

## 6. Primer acceso

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

## 7. Uso inicial

Revise:

1. Dashboard.
2. Agentes.
3. Productividad.
4. Llamadas.
5. Abandonadas y devueltas.
6. Configuración SLA.
7. Pausas y sesiones.
8. Grabaciones.
9. Usuarios y permisos.
10. Wallboard.

## 8. Wallboard

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

Para una TV cree un usuario con:

```text
live.view
```

## 9. SLA

Configuración inicial:

```text
80 % dentro de 20 segundos
```

Puede modificarse desde:

```text
Administración > Configuración SLA
```

## 10. Diagnóstico

```bash
cd /var/www/html/callcenter-panel
php bin/diagnostico.php
```

## 11. Reparar 403

```bash
sudo -i
cd /root
curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
-o REPARAR_403.sh
chmod +x REPARAR_403.sh
./REPARAR_403.sh /var/www/html/callcenter-panel
```

## 12. Contacto

```text
Cybermatica
Email:    info@cybermatica.com.py
Teléfono: 021 728 9200
Web:      www.cybermatica.com.py
```
