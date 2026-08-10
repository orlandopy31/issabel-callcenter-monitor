# Guía de instalación desde cero
## Cybermatica Call Center Monitor v1.0 para Issabel

Esta guía asume que el panel se instalará en el mismo servidor donde funcionan Issabel y Asterisk.

## 1. Antes de comenzar

Realice un backup del servidor y de las bases de datos. El panel no reemplaza Issabel ni Asterisk: utiliza la información registrada por Issabel Call Center.

Bases utilizadas:

- `call_center`: agentes, auditoría, pausas, campañas y llamadas.
- `asteriskcdrdb`: CDR de Asterisk.
- `asterisk`: datos auxiliares de la PBX.
- `callcenter_panel`: base propia para usuarios, permisos, SLA, configuración y auditoría.

## 2. Requisitos

Compruebe:

```bash
php -v
php -m | egrep -i 'PDO|pdo_mysql|json'
mysql --version
asterisk -V
systemctl status httpd --no-pager
```

Se requiere PHP 7.2 o superior y PDO MySQL. Deben existir como mínimo:

```text
call_center.agent
call_center.audit
call_center.call_entry
asteriskcdrdb.cdr
```

## 3. Instalación automática

Descargue el archivo `issabel-callcenter-monitor-v1.0.zip` y súbalo al servidor, por ejemplo a `/root`.

```bash
cd /root
unzip issabel-callcenter-monitor-v1.0.zip
cd issabel-callcenter-monitor-v1.0
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

La contraseña del panel debe tener al menos 10 caracteres.

## 4. Base y permisos MySQL

El instalador crea la base:

```text
callcenter_panel
```

Y un usuario técnico `ccpanel@localhost` con permisos mínimos:

```sql
GRANT SELECT, SHOW VIEW ON call_center.* TO 'ccpanel'@'localhost';
GRANT SELECT, SHOW VIEW ON asteriskcdrdb.* TO 'ccpanel'@'localhost';
GRANT SELECT, SHOW VIEW ON asterisk.* TO 'ccpanel'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON callcenter_panel.* TO 'ccpanel'@'localhost';
```

PHP no necesita utilizar `root` durante el funcionamiento normal.

## 5. Usuario administrador

El instalador crea el superadministrador inicial. La contraseña se almacena mediante `password_hash()`.

Después del primer ingreso puede crear usuarios adicionales y asignar permisos individuales para monitoreo, reportes, grabaciones, supervisión, exportaciones, configuración SLA y administración.

## 6. Configuración AMI

Se crea un usuario AMI dedicado en `/etc/asterisk/manager_custom.conf`, restringido a localhost:

```ini
[ccpanel_monitor]
secret = CLAVE_GENERADA
deny = 0.0.0.0/0.0.0.0
permit = 127.0.0.1/255.255.255.255
read = system,call
write = call,originate
```

Después se ejecuta:

```bash
asterisk -rx "manager reload"
```

No es necesario reiniciar Asterisk.

## 7. Acceso al panel

Por defecto:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Para comprobar errores PHP:

```bash
cd /var/www/html/callcenter-panel
find . -name '*.php' -print0 | xargs -0 -n1 php -l
```

## 8. Wallboard para TV

Cree un usuario destinado a la pantalla y asigne únicamente:

```text
live.view
```

Abra:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

El modo TV oculta elementos administrativos y presenta estados y KPIs para visualización a distancia.

## 9. SLA

La configuración inicial es:

```text
Meta: 80 %
Tiempo: 20 segundos
```

Es decir, se busca responder al menos el 80 % de las llamadas dentro de 20 segundos. Puede modificarse desde:

**Administración → Configuración SLA**

Cambiar el tiempo SLA modifica qué llamadas califican como atendidas dentro del SLA. Cambiar la meta porcentual modifica el criterio de `CUMPLE / NO CUMPLE`.

## 10. Grabaciones

Las rutas habituales son:

```text
/var/spool/asterisk/monitor
/var/spool/asterisk/monitoring
```

Si el panel no puede leerlas, revise propietario, grupo, ACL y SELinux. No aplique permisos `777` de forma indiscriminada.

## 11. SELinux

Si SELinux está activo, el instalador intenta habilitar la conexión necesaria desde Apache y asignar contexto escribible solamente a `cache/`.

Compruebe:

```bash
getenforce
ls -Zd /var/www/html/callcenter-panel/cache
```

## 12. Diagnóstico

Cuando `bin/diagnostico.php` esté incluido en la distribución completa puede ejecutar:

```bash
cd /var/www/html/callcenter-panel
sudo -u apache php bin/diagnostico.php
```

Revise conexión a MySQL, AMI, cache y directorios de grabaciones.

## 13. Recomendaciones de producción

- Use HTTPS si el panel será accesible fuera de una red confiable.
- Mantenga AMI limitado a `127.0.0.1` cuando sea posible.
- No utilice MySQL `root` como usuario permanente de la aplicación.
- No publique `config.php` generado con credenciales reales.
- Haga backup antes de actualizar.
- Mantenga Issabel, Asterisk, PHP y el sistema operativo actualizados.

## 14. Actualización

Antes de reemplazar una versión instalada:

```bash
cp -a /var/www/html/callcenter-panel /var/www/html/callcenter-panel_backup_$(date +%F_%H%M)
```

Conserve también un respaldo de `callcenter_panel` y revise las migraciones SQL incluidas con la nueva versión.
