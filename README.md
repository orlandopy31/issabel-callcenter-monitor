# Cybermatica Issabel Call Center Monitor

Panel web para **Issabel 5 / Asterisk** orientado a monitoreo, supervisión, productividad, SLA, grabaciones y reportería operativa.

## Versión principal recomendada

**Versión estable principal: v1.0.4**

Esta es la versión recomendada para nuevas instalaciones y actualizaciones.

**Descarga directa:**

https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.4/issabel-callcenter-monitor-v1.0.4.zip

**Release:**

https://github.com/orlandopy31/issabel-callcenter-monitor/releases/tag/v1.0.4

SHA-256 oficial:

```text
5475d3773f1585b73a6d5bf2f46770c1d8d55b4885a9771e7b79ea17f50b23e6
```

## Instalación paso a paso de v1.0.4

### Paso 1 — Ingresar como root

```bash
sudo -i
```

### Paso 2 — Instalar herramientas necesarias

En Issabel 5 / Rocky Linux 8:

```bash
dnf -y install curl wget unzip
```

### Paso 3 — Descargar el paquete principal v1.0.4

```bash
cd /root

wget -O issabel-callcenter-monitor-v1.0.4.zip \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.4/issabel-callcenter-monitor-v1.0.4.zip
```

También puede utilizar `curl`:

```bash
curl -fL \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.4/issabel-callcenter-monitor-v1.0.4.zip \
-o /root/issabel-callcenter-monitor-v1.0.4.zip
```

### Paso 4 — Verificar integridad

```bash
cd /root
sha256sum issabel-callcenter-monitor-v1.0.4.zip
```

Debe devolver:

```text
5475d3773f1585b73a6d5bf2f46770c1d8d55b4885a9771e7b79ea17f50b23e6  issabel-callcenter-monitor-v1.0.4.zip
```

### Paso 5 — Descomprimir

```bash
cd /root
rm -rf issabel-callcenter-monitor-v1.0.4
unzip issabel-callcenter-monitor-v1.0.4.zip
cd issabel-callcenter-monitor-v1.0.4
```

### Paso 6 — Ejecutar el instalador

```bash
chmod +x install.sh
./install.sh
```

El instalador solicitará normalmente:

- directorio del panel: `/var/www/html/callcenter-panel`;
- nombre de empresa/call center;
- zona horaria;
- usuario administrador de MariaDB/MySQL;
- contraseña administrativa de MariaDB/MySQL;
- usuario administrador del panel;
- nombre del administrador;
- contraseña inicial del panel.

## Instalación automática de Issabel Call Center

Antes de instalar el monitor, v1.0.4 verifica:

- Asterisk;
- PHP y PDO MySQL;
- MariaDB/MySQL;
- `asterisk`;
- `asteriskcdrdb` y `asteriskcdrdb.cdr`;
- base `call_center`;
- tablas de Call Center utilizadas por el panel;
- módulo `agent_console`;
- servicio `issabeldialer`.

Si **Issabel Call Center no está instalado o está incompleto**, el sistema puede instalarlo/repararlo automáticamente en **Issabel 5 sobre Rocky Linux 8** y vuelve a validar los componentes antes de continuar.

Log de esa operación:

```text
/var/log/callcenter-panel-callcenter-install.log
```

Para desactivar la instalación automática:

```bash
CC_AUTO_INSTALL_CALLCENTER=0 ./install.sh
```

## Permisos obligatorios del panel

Para que Apache pueda abrir el sistema correctamente y evitar errores como:

```text
Forbidden
You don't have permission to access this resource.
Server unable to read htaccess file, denying access to be safe
```

la instalación debe terminar con este esquema:

```text
/var/www/html/callcenter-panel   root:apache     755
index.php                         root:apache     644
.htaccess                         root:apache     644
config.php                        root:apache     640
cache/                            apache:apache   770
```

> **Importante:** que los archivos PHP tengan propietario `root` es correcto. El grupo debe ser `apache`. Solamente `cache/` necesita quedar escribible por Apache.

### Aplicar los permisos manualmente

Si desea comprobar o normalizar los permisos después de la instalación, ejecute exactamente:

```bash
sudo -i

TARGET="/var/www/html/callcenter-panel"

# Apache debe poder atravesar los directorios padre
chown root:root /var/www /var/www/html
chmod 755 /var/www /var/www/html

# Código de la aplicación: root como propietario y apache como grupo
chown -R root:apache "$TARGET"

# Directorios públicos
find "$TARGET" -type d -exec chmod 755 {} \;

# Archivos públicos
find "$TARGET" -type f -exec chmod 644 {} \;

# Archivos principales
chown root:apache "$TARGET/index.php" "$TARGET/.htaccess" "$TARGET/config.php"
chmod 644 "$TARGET/index.php"
chmod 644 "$TARGET/.htaccess"
chmod 640 "$TARGET/config.php"

# Directorio escribible de la aplicación
chown -R apache:apache "$TARGET/cache"
find "$TARGET/cache" -type d -exec chmod 770 {} \;
find "$TARGET/cache" -type f -exec chmod 660 {} \;
```

El resultado esperado es:

```text
/var/www/html/callcenter-panel   root:apache     drwxr-xr-x   755
index.php                         root:apache     -rw-r--r--   644
.htaccess                         root:apache     -rw-r--r--   644
config.php                        root:apache     -rw-r-----   640
cache/                            apache:apache   drwxrwx---   770
```

### Verificar que Apache pueda leer los archivos

Ejecute:

```bash
runuser -u apache -- test -x /var/www/html/callcenter-panel && echo "OK directorio"
runuser -u apache -- test -r /var/www/html/callcenter-panel/index.php && echo "OK index.php"
runuser -u apache -- test -r /var/www/html/callcenter-panel/.htaccess && echo "OK .htaccess"
runuser -u apache -- test -r /var/www/html/callcenter-panel/config.php && echo "OK config.php"
```

Deben aparecer los cuatro mensajes `OK`.

### Verificación visual de propietario, grupo y permisos

```bash
namei -l /var/www/html/callcenter-panel/.htaccess

ls -ld \
/var/www/html/callcenter-panel \
/var/www/html/callcenter-panel/cache

ls -l \
/var/www/html/callcenter-panel/index.php \
/var/www/html/callcenter-panel/.htaccess \
/var/www/html/callcenter-panel/config.php
```

## Apache y SELinux

El instalador también configura:

- contexto SELinux `httpd_sys_content_t` para el panel;
- contexto SELinux `httpd_sys_rw_content_t` para `cache/`;
- regla `/etc/httpd/conf.d/callcenter-panel.conf`;
- `Require all granted`;
- `DirectoryIndex index.php`;
- `AllowOverride None` para evitar depender de `.htaccess` al autorizar el acceso.

Para comprobar SELinux:

```bash
getenforce
ls -ldZ /var/www/html/callcenter-panel
ls -ldZ /var/www/html/callcenter-panel/cache
```

## Reparar una instalación existente con 403 Forbidden

Si el panel ya está instalado y aparece un 403:

```bash
sudo -i
cd /root

curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
-o REPARAR_403.sh

chmod +x REPARAR_403.sh
./REPARAR_403.sh /var/www/html/callcenter-panel
```

Después pruebe:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Si continúa el problema:

```bash
namei -l /var/www/html/callcenter-panel/.htaccess
ls -ldZ /var /var/www /var/www/html /var/www/html/callcenter-panel
ls -lZ /var/www/html/callcenter-panel/.htaccess \
       /var/www/html/callcenter-panel/index.php \
       /var/www/html/callcenter-panel/config.php
apachectl -t
tail -n 100 /var/log/httpd/error_log
```

## Funciones principales

- Dashboard ejecutivo.
- Monitoreo en tiempo real de agentes.
- Wallboard profesional para TV.
- Escucha, susurro y conferencia mediante AMI + ChanSpy.
- Productividad por agente.
- Llamadas recibidas y realizadas.
- Llamadas abandonadas y devueltas.
- Campañas salientes.
- Pausas y sesiones.
- SLA configurable.
- Comparativos de llamadas.
- Grabaciones.
- Exportaciones CSV/PDF.
- Usuarios, permisos y auditoría.

## Acceso

Panel:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Wallboard:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

## SLA

La política inicial es **80 % dentro de 20 segundos (80/20)** y puede modificarse desde **Administración → Configuración SLA**.

## Instalar automáticamente la Release estable más reciente

Aunque **v1.0.4 es actualmente el paquete principal recomendado**, el repositorio conserva `install-latest.sh` para futuras versiones.

```bash
sudo -i
cd /root

curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/install-latest.sh \
-o install-latest.sh

chmod +x install-latest.sh
./install-latest.sh
```

Mientras v1.0.4 sea la última Release estable, este procedimiento instalará también v1.0.4.

## Seguridad

- La aplicación no usa MySQL `root` durante el funcionamiento normal.
- Se crea un usuario MySQL técnico exclusivo.
- AMI utiliza un usuario separado restringido a `127.0.0.1` cuando panel y Asterisk están en el mismo servidor.
- Las contraseñas de usuarios se almacenan con `password_hash()`.
- `config.php` queda fuera del acceso HTTP directo y con permisos restringidos.
- El código PHP queda `root:apache`; Apache puede leerlo pero no modificarlo.
- No utilice `chmod 777` sobre el panel.
- Realice backup o snapshot antes de actualizar una central en producción.

## Versión

```text
1.0.4
```

## Proyecto

Repositorio: `orlandopy31/issabel-callcenter-monitor`
