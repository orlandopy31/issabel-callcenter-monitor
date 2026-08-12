# Guía de instalación desde cero
## Cybermatica Call Center Monitor v1.0.2 para Issabel 5

Esta versión puede instalar el módulo **Issabel Call Center** automáticamente cuando detecta que está ausente o incompleto.

## 1. Plataforma soportada

La instalación automática del módulo Call Center está orientada a:

```text
Issabel 5
Rocky Linux 8
Asterisk 18
Apache / PHP
MariaDB / MySQL
```

El panel también requiere las bases base de Issabel:

```text
asterisk
asteriskcdrdb
```

Si la plataforma no es Rocky Linux, el instalador no intentará instalar automáticamente el Call Center para evitar aplicar una versión incompatible.

## 2. Backup previo

Antes de instalar en producción haga snapshot o backup del servidor y, si existe una instalación previa del panel:

```bash
cp -a /var/www/html/callcenter-panel \
  /root/callcenter-panel_backup_$(date +%F_%H%M)
```

## 3. Instalación

Descargue la Release v1.0.2, copie el ZIP a `/root` y ejecute:

```bash
cd /root
unzip issabel-callcenter-monitor-v1.0.2.zip
cd issabel-callcenter-monitor-v1.0.2
sudo bash install.sh
```

El instalador solicitará:

- directorio web;
- nombre de empresa/call center;
- zona horaria;
- usuario y contraseña administrativa de MariaDB/MySQL;
- usuario administrador del panel;
- nombre del administrador;
- contraseña inicial del panel.

Valores habituales:

```text
Directorio: /var/www/html/callcenter-panel
Zona horaria: America/Asuncion
Administrador BD: root
Usuario del panel: admin
```

## 4. Detección automática de Issabel Call Center

Antes de crear el panel, v1.0.2 verifica:

- base `asteriskcdrdb`;
- base `asterisk`;
- tabla `asteriskcdrdb.cdr`;
- base `call_center`;
- tablas operativas utilizadas por el panel;
- `/var/www/html/modules/agent_console`;
- `issabeldialer.service`.

Las tablas de Call Center verificadas incluyen:

```text
agent
audit
break
call_entry
calls
campaign
campaign_entry
queue_call_entry
call_recording
call_progress_log
current_calls
current_call_entry
form_data_recolected
form_data_recolected_entry
form_field
```

Si falta Call Center o la instalación está incompleta, el instalador obtiene:

```text
https://github.com/ISSABELPBX/callcenter-issabel5.git
```

y utiliza por defecto la revisión:

```text
82843e063722274276e787c795d8ae20740bd569
```

Después ejecuta el instalador Community V5 en modo local y vuelve a comprobar las tablas, `agent_console` y el servicio `issabeldialer` antes de continuar.

## 5. Log de la dependencia

Si la instalación automática de Call Center falla, revise:

```bash
tail -n 150 /var/log/callcenter-panel-callcenter-install.log
```

También puede revisar:

```bash
systemctl status issabeldialer -l --no-pager
journalctl -u issabeldialer -n 100 --no-pager
```

## 6. Desactivar instalación automática

Para administrar Call Center manualmente:

```bash
CC_AUTO_INSTALL_CALLCENTER=0 sudo -E bash install.sh
```

En ese modo, si Call Center no está completo, el instalador se detiene sin modificarlo.

## 7. Cambiar repositorio o revisión

Repositorio alternativo:

```bash
CC_CALLCENTER_REPO=https://github.com/OTRO/REPO.git sudo -E bash install.sh
```

Usar `master` del repositorio configurado:

```bash
CC_CALLCENTER_GIT_REF=master sudo -E bash install.sh
```

Para producción se recomienda mantener la revisión fijada por la versión del panel hasta probar una nueva.

Consulte también `DEPENDENCIA_ISSABEL_CALLCENTER.md`.

## 8. Base propia y usuario MySQL

El instalador crea:

```text
callcenter_panel
```

Y un usuario técnico `ccpanel@localhost` con lectura sobre:

```text
call_center
asteriskcdrdb
asterisk
```

y lectura/escritura sobre:

```text
callcenter_panel
```

PHP no utiliza `root` durante la operación normal.

## 9. AMI

Se crea un usuario AMI dedicado y restringido a localhost. El instalador modifica `manager_custom.conf` y realiza:

```bash
asterisk -rx "manager reload"
```

No es necesario reiniciar Asterisk.

## 10. Apache y SELinux

v1.0.2 conserva la corrección del error 403 incluida desde v1.0.1:

- `DirectoryIndex index.php`;
- regla explícita `<Directory>` para el panel;
- `httpd_sys_content_t` para el código;
- `httpd_sys_rw_content_t` para `cache/`;
- validación de Apache antes del reinicio.

Si una instalación anterior devuelve:

```text
Forbidden
You don't have permission to access this resource.
```

ejecute:

```bash
cd /root
curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
-o REPARAR_403.sh
chmod +x REPARAR_403.sh
sudo ./REPARAR_403.sh /var/www/html/callcenter-panel
```

## 11. Acceso

Por defecto:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Wallboard:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

Para la TV cree un usuario con únicamente el permiso:

```text
live.view
```

## 12. SLA

Configuración inicial:

```text
Meta: 80 %
Tiempo: 20 segundos
```

Puede modificarse desde:

```text
Administración > Configuración SLA
```

## 13. Diagnóstico

Después de instalar:

```bash
cd /var/www/html/callcenter-panel
sudo -u apache php bin/diagnostico.php
```

Para comprobar sintaxis PHP:

```bash
find /var/www/html/callcenter-panel -name '*.php' -print0 \
  | xargs -0 -n1 php -l
```

Para revisar Apache:

```bash
apachectl -t
systemctl status httpd --no-pager
```

## 14. Problemas con Call Center

Compruebe:

```bash
systemctl status issabeldialer -l --no-pager
ls -ld /var/www/html/modules/agent_console
mysql -u root -p -e "SHOW TABLES FROM call_center;"
```

Si el instalador automático se ejecutó, el primer archivo a revisar es:

```text
/var/log/callcenter-panel-callcenter-install.log
```

## 15. Seguridad recomendada

- haga backup antes de instalar o actualizar;
- no use MySQL `root` como usuario permanente del panel;
- mantenga AMI restringido a `127.0.0.1` cuando panel y Asterisk estén en el mismo servidor;
- use HTTPS si el panel se expone fuera de una red administrativa;
- no publique el `config.php` generado en producción;
- pruebe nuevas revisiones de Issabel Call Center antes de cambiar `CC_CALLCENTER_GIT_REF`.
