# Guía de instalación desde cero
## Cybermatica Issabel Call Center Monitor v1.0.5

Esta guía explica cómo instalar **v1.0.5**, registrar la licencia, aplicar los permisos obligatorios y comprobar que el sistema quede operativo.

## 1. Plataforma soportada

La instalación está orientada principalmente a:

```text
Issabel 5
Rocky Linux 8
Asterisk 18
Apache / PHP
MariaDB / MySQL
```

Bases esperadas de Issabel:

```text
asterisk
asteriskcdrdb
```

Si Issabel Call Center falta o está incompleto, v1.0.5 puede instalarlo/repararlo automáticamente en Issabel 5 sobre Rocky Linux 8.

## 2. Requisitos previos

Ingrese como root:

```bash
sudo -i
```

Instale utilidades básicas:

```bash
dnf -y install curl wget unzip
```

Compruebe:

```bash
php -v
mysql --version
asterisk -V
systemctl status httpd --no-pager
```

El servidor debe poder acceder por HTTPS al servidor de licencias:

```text
https://www.cybermatica.com.py/licence
```

## 3. Backup previo

Antes de instalar en producción haga snapshot/backup. Si existe una instalación anterior del panel:

```bash
cp -a /var/www/html/callcenter-panel \
/root/callcenter-panel_backup_$(date +%F_%H%M)
```

## 4. Descargar v1.0.5

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.5.zip \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.5/issabel-callcenter-monitor-v1.0.5.zip
```

Verifique SHA-256:

```bash
sha256sum /root/issabel-callcenter-monitor-v1.0.5.zip
```

Resultado esperado:

```text
a4af7feb966f7f8c8e9dbc1385a346972c1f632880dc4e4b8caf56f85bdc1395  /root/issabel-callcenter-monitor-v1.0.5.zip
```

## 5. Descomprimir

```bash
cd /root
rm -rf issabel-callcenter-monitor-v1.0.5
unzip issabel-callcenter-monitor-v1.0.5.zip
cd issabel-callcenter-monitor-v1.0.5
```

## 6. Ejecutar instalación

```bash
chmod +x install.sh
./install.sh
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

## 7. Issabel Call Center

Antes de crear el panel, el instalador verifica:

- `asteriskcdrdb`;
- `asterisk`;
- `asteriskcdrdb.cdr`;
- base `call_center`;
- tablas operativas utilizadas por el panel;
- `/var/www/html/modules/agent_console`;
- `issabeldialer.service`.

Si Call Center falta o está incompleto, se intenta instalar/reparar antes de continuar.

Log:

```bash
tail -n 150 /var/log/callcenter-panel-callcenter-install.log
```

## 8. Registro de licencia

Durante la instalación v1.0.5 se registra la instalación contra:

```text
https://www.cybermatica.com.py/licence
```

Cada servidor recibe:

```text
Installation ID único
Licence Key única
Estado inicial ACTIVE
```

La licencia solamente puede cambiar a `SUSPENDED` mediante una acción manual en el administrador central de Cybermatica. No existe suspensión automática por tiempo, falta de Internet o falta de heartbeat.

Archivos locales de licencia:

```text
/var/lib/cybermatica-callcenter/license-client.json
/var/lib/cybermatica-callcenter/license-state.json
```

Compruebe el timer:

```bash
systemctl status cybermatica-license-check.timer --no-pager
systemctl list-timers cybermatica-license-check.timer
```

Forzar comprobación:

```bash
php /var/www/html/callcenter-panel/bin/license_check.php
```

## 9. PASO OBLIGATORIO: aplicar permisos

**El usuario debe ejecutar este paso después de la instalación y antes del primer acceso web.**

```bash
sudo -i

TARGET="/var/www/html/callcenter-panel"

chown root:root /var/www /var/www/html
chmod 755 /var/www /var/www/html

chown -R root:apache "$TARGET"
find "$TARGET" -type d -exec chmod 755 {} \;
find "$TARGET" -type f -exec chmod 644 {} \;

chown root:apache "$TARGET/index.php" "$TARGET/.htaccess" "$TARGET/config.php"
chmod 644 "$TARGET/index.php"
chmod 644 "$TARGET/.htaccess"
chmod 640 "$TARGET/config.php"

chown -R apache:apache "$TARGET/cache"
find "$TARGET/cache" -type d -exec chmod 770 {} \;
find "$TARGET/cache" -type f -exec chmod 660 {} \;
```

Permisos esperados:

```text
/var/www/html/callcenter-panel   root:apache     755
index.php                         root:apache     644
.htaccess                         root:apache     644
config.php                        root:apache     640
cache/                            apache:apache   770
```

No utilice `chmod 777`.

## 10. Verificar permisos como Apache

```bash
runuser -u apache -- test -x /var/www/html/callcenter-panel && echo "OK directorio"
runuser -u apache -- test -r /var/www/html/callcenter-panel/index.php && echo "OK index.php"
runuser -u apache -- test -r /var/www/html/callcenter-panel/.htaccess && echo "OK .htaccess"
runuser -u apache -- test -r /var/www/html/callcenter-panel/config.php && echo "OK config.php"
```

Deben aparecer los cuatro mensajes `OK`.

## 11. Apache y SELinux

Compruebe:

```bash
apachectl -t
getenforce
ls -ldZ /var/www/html/callcenter-panel
ls -ldZ /var/www/html/callcenter-panel/cache
```

Si aparece un 403 Forbidden:

```bash
cd /root
curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
-o REPARAR_403.sh
chmod +x REPARAR_403.sh
./REPARAR_403.sh /var/www/html/callcenter-panel
```

## 12. Primer acceso

Abra:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Ingrese con el usuario administrador creado durante `install.sh`.

Después del ingreso compruebe:

1. licencia `ACTIVE`;
2. Dashboard cargando datos;
3. agentes visibles;
4. productividad;
5. llamadas recibidas/realizadas;
6. abandonadas y devueltas;
7. SLA;
8. pausas y sesiones;
9. grabaciones;
10. permisos de usuarios.

## 13. Configuración de usuarios

Desde Administración cree usuarios y otorgue solamente los permisos necesarios. Para una TV/Wallboard utilice un usuario limitado a:

```text
live.view
```

Wallboard:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

## 14. SLA

Configuración inicial:

```text
Meta: 80 %
Tiempo: 20 segundos
```

Puede modificarse desde:

```text
Administración > Configuración SLA
```

## 15. Supervisión

La escucha, susurro y conferencia utilizan AMI y ChanSpy. Asigne esos permisos solamente a supervisores autorizados.

El instalador crea un usuario AMI dedicado restringido a localhost cuando el panel y Asterisk están en el mismo servidor.

## 16. Grabaciones

Compruebe acceso a las rutas habituales:

```text
/var/spool/asterisk/monitor
/var/spool/asterisk/monitoring
```

No aplique permisos `777`. Use grupos/ACL si Apache necesita lectura adicional.

## 17. Diagnóstico

```bash
cd /var/www/html/callcenter-panel
sudo -u apache php bin/diagnostico.php
```

Servicios:

```bash
systemctl status httpd --no-pager
systemctl status php-fpm --no-pager
systemctl status issabeldialer --no-pager
systemctl status cybermatica-license-check.timer --no-pager
asterisk -rx "core show version"
```

Sintaxis PHP:

```bash
find /var/www/html/callcenter-panel -name '*.php' -print0 | xargs -0 -n1 php -l
```

## 18. Licencia suspendida

Una licencia solamente será suspendida manualmente por Cybermatica. Cuando la instalación recibe un estado firmado `SUSPENDED`, se bloquea el acceso al Monitor.

No se detiene:

```text
Asterisk
Issabel
Issabel Call Center
las llamadas de la central
```

Para reactivar, el administrador central debe cambiar manualmente la licencia a `ACTIVE`. En la siguiente comprobación el Monitor volverá a habilitarse.

## 19. Recomendaciones de producción

- haga snapshot/backup antes de instalar o actualizar;
- use HTTPS cuando el panel se exponga fuera de una red confiable;
- mantenga AMI limitado a localhost cuando sea posible;
- no publique `config.php`;
- no use `chmod 777`;
- conserve `root:apache` para el código y `apache:apache` solamente en directorios que deban escribirse;
- confirme que el servidor puede resolver y conectar por HTTPS a `www.cybermatica.com.py`;
- pruebe Dashboard, licencia, grabaciones y supervisión antes de entregar el sistema al usuario final.

## 20. Guía rápida de uso

Consulte también:

**[GUIA_INSTALACION_Y_USO_v1.0.5.md](GUIA_INSTALACION_Y_USO_v1.0.5.md)**
