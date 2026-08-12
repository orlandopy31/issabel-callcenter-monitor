# Guía de instalación desde cero
## Cybermatica Issabel Call Center Monitor v1.0.6

Esta guía explica cómo instalar y comenzar a utilizar **v1.0.6**.

## 1. Plataforma recomendada

```text
Issabel 5
Rocky Linux 8
Asterisk 18
Apache / PHP
MariaDB / MySQL
```

## 2. Requisitos previos

```bash
sudo -i
dnf -y install curl wget unzip cronie
```

Compruebe:

```bash
php -v
mysql --version
asterisk -V
systemctl status httpd --no-pager
```

## 3. Backup previo

Antes de instalar en producción:

```bash
cp -a /var/www/html/callcenter-panel \
/root/callcenter-panel_backup_$(date +%F_%H%M) 2>/dev/null || true
```

## 4. Descargar v1.0.6

Una vez publicada la Release `v1.0.6`:

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.6.zip \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.6/issabel-callcenter-monitor-v1.0.6.zip
```

Verifique:

```bash
sha256sum /root/issabel-callcenter-monitor-v1.0.6.zip
```

SHA-256 esperado:

```text
6754f47a476da7fdba5e53c8d2ea2b192048952dfca771f6ecf48da6928435df
```

## 5. Descomprimir

```bash
cd /root
rm -rf issabel-callcenter-monitor-v1.0.6
unzip issabel-callcenter-monitor-v1.0.6.zip
cd issabel-callcenter-monitor-v1.0.6
```

## 6. Ejecutar instalación

```bash
chmod +x install.sh
./install.sh
```

Complete los datos solicitados. Para identificar correctamente la instalación, indique:

- nombre de empresa/call center;
- nombre del contacto responsable;
- zona horaria;
- credenciales administrativas de MariaDB/MySQL;
- usuario administrador del panel;
- contraseña inicial.

Directorio recomendado:

```text
/var/www/html/callcenter-panel
```

## 7. Issabel Call Center

El instalador comprueba Asterisk, las bases de Issabel, `call_center`, `agent_console` e `issabeldialer`.

Si el módulo está ausente o incompleto en Issabel 5 / Rocky Linux 8, el instalador puede instalarlo o repararlo automáticamente.

Log:

```bash
tail -n 150 /var/log/callcenter-panel-callcenter-install.log
```

## 8. Permisos del panel

v1.0.6 aplica al finalizar:

```bash
chmod -R 0777 /var/www/html/callcenter-panel
```

Para reaplicarlo manualmente:

```bash
sudo -i
chmod -R 0777 /var/www/html/callcenter-panel
```

> Se utiliza `0777` en lugar de `7777`; `7777` agrega bits especiales `setuid`, `setgid` y `sticky`.

## 9. Verificar servicios

```bash
apachectl -t
systemctl status httpd --no-pager
systemctl status php-fpm --no-pager
systemctl status issabeldialer --no-pager
systemctl status crond --no-pager
asterisk -rx "core show version"
```

## 10. Primer acceso

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Ingrese con el usuario administrador creado durante la instalación.

## 11. Uso inicial

Revise en este orden:

1. Dashboard.
2. Agentes.
3. Productividad.
4. Llamadas recibidas y realizadas.
5. Abandonadas y devueltas.
6. SLA.
7. Pausas y sesiones.
8. Grabaciones.
9. Usuarios y permisos.
10. Wallboard.

## 12. Wallboard

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

Para una TV, cree un usuario con el permiso:

```text
live.view
```

## 13. SLA

Configuración inicial:

```text
80 % dentro de 20 segundos
```

Puede modificarse en:

```text
Administración > Configuración SLA
```

## 14. Diagnóstico

```bash
cd /var/www/html/callcenter-panel
php bin/diagnostico.php
```

Validar PHP:

```bash
find /var/www/html/callcenter-panel -name '*.php' -print0 | xargs -0 -n1 php -l
```

## 15. Reparar 403 Forbidden

```bash
sudo -i
cd /root
curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
-o REPARAR_403.sh
chmod +x REPARAR_403.sh
./REPARAR_403.sh /var/www/html/callcenter-panel
```

## 16. Contacto

```text
Cybermatica
info@cybermatica.com.py
021 728 9200
www.cybermatica.com.py
```

Consulte también **[GUIA_INSTALACION_Y_USO_v1.0.6.md](GUIA_INSTALACION_Y_USO_v1.0.6.md)**.
