# Cybermatica Issabel Call Center Monitor

Panel web para **Issabel 5 / Asterisk** orientado a monitoreo, supervisión, productividad, SLA, grabaciones y reportería operativa.

## Instalación recomendada: siempre la última versión estable

No es necesario editar el README cada vez que se publica una nueva versión. El script `install-latest.sh` consulta GitHub, identifica la **última Release estable**, descarga su ZIP, ejecuta `install.sh` y finalmente aplica el reparador de permisos más reciente de `main`.

### Paso 1 — Ingresar como root

```bash
sudo -i
```

### Paso 2 — Instalar herramientas básicas

En Issabel 5 / Rocky Linux 8:

```bash
dnf -y install curl unzip
```

### Paso 3 — Descargar el instalador de la última versión

```bash
cd /root
curl -fsSL \
  https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/install-latest.sh \
  -o install-latest.sh
chmod +x install-latest.sh
```

### Paso 4 — Ejecutar la instalación

```bash
./install-latest.sh
```

El instalador solicitará normalmente:

- directorio del panel (recomendado: `/var/www/html/callcenter-panel`);
- nombre de empresa/call center;
- zona horaria;
- usuario administrador de MariaDB/MySQL;
- contraseña del administrador de MariaDB/MySQL;
- usuario administrador del panel;
- nombre del administrador;
- contraseña inicial del panel.

### Paso 5 — Issabel Call Center

Antes de instalar el panel se verifica que Issabel Call Center esté completo. Se comprueban la base `call_center`, sus tablas requeridas, `agent_console` y el servicio `issabeldialer`.

Si Call Center está ausente o incompleto en **Issabel 5 sobre Rocky Linux 8**, el instalador puede instalarlo/repararlo automáticamente desde `ISSABELPBX/callcenter-issabel5` y vuelve a validar todos los componentes antes de continuar.

El log de esa operación queda en:

```text
/var/log/callcenter-panel-callcenter-install.log
```

Para desactivar esa instalación automática:

```bash
CC_AUTO_INSTALL_CALLCENTER=0 ./install-latest.sh
```

### Paso 6 — Permisos web, Apache y SELinux

El sistema configura automáticamente:

- directorios públicos del panel: `0755`;
- archivos públicos: `0644`;
- `.htaccess`: `0644`;
- `config.php`: `0640`, propietario `root` y grupo web;
- `cache/`: propietario del servidor web y permisos de escritura;
- contexto SELinux `httpd_sys_content_t` para el panel;
- contexto SELinux `httpd_sys_rw_content_t` para `cache/`;
- `/etc/httpd/conf.d/callcenter-panel.conf` con `Require all granted` y `DirectoryIndex index.php`.

En Issabel/Rocky la regla propia de Apache usa **`AllowOverride None`**, por lo que Apache no depende de poder procesar `.htaccess` para abrir el panel. Esto evita el error:

```text
Server unable to read htaccess file, denying access to be safe
```

Al finalizar, `install-latest.sh` ejecuta además el reparador de permisos más reciente publicado en `main`.

### Paso 7 — Verificar servicios

```bash
systemctl status httpd --no-pager
systemctl status php-fpm --no-pager
systemctl status issabeldialer --no-pager
asterisk -rx "core show version"
```

### Paso 8 — Verificar permisos

```bash
namei -l /var/www/html/callcenter-panel/.htaccess
ls -ldZ /var /var/www /var/www/html /var/www/html/callcenter-panel
ls -lZ /var/www/html/callcenter-panel/.htaccess
ls -lZ /var/www/html/callcenter-panel/index.php
ls -lZ /var/www/html/callcenter-panel/config.php
```

Valores esperados de referencia:

```text
directorios web   drwxr-xr-x   (755)
.htaccess          -rw-r--r--   (644)
index.php          -rw-r--r--   (644)
config.php         -rw-r-----   (640)
```

### Paso 9 — Acceder al panel

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Wallboard para TV:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

## Reparar un 403 Forbidden existente

Si ya instaló el panel y aparece:

```text
Forbidden
You don't have permission to access this resource.
Server unable to read htaccess file, denying access to be safe
```

ejecute:

```bash
sudo -i
cd /root
curl -fsSL \
  https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
  -o REPARAR_403.sh
chmod +x REPARAR_403.sh
./REPARAR_403.sh /var/www/html/callcenter-panel
```

El reparador corrige permisos Unix, directorios padre, configuración Apache, SELinux, cache y comprueba que el usuario `apache` pueda leer realmente `index.php`, `.htaccess` y `config.php`.

Si todavía aparece 403, recopile:

```bash
namei -l /var/www/html/callcenter-panel/.htaccess
ls -ldZ /var /var/www /var/www/html /var/www/html/callcenter-panel
ls -lZ /var/www/html/callcenter-panel/.htaccess \
       /var/www/html/callcenter-panel/index.php \
       /var/www/html/callcenter-panel/config.php
apachectl -t -D DUMP_RUN_CFG | head -80
tail -n 100 /var/log/httpd/error_log
```

## Funciones principales

- Dashboard ejecutivo.
- Monitoreo en tiempo real de agentes.
- Wallboard profesional para TV.
- Escucha, susurro y conferencia mediante AMI + ChanSpy.
- Productividad por agente.
- Llamadas recibidas y realizadas.
- Llamadas abandonadas y devoluciones.
- Campañas salientes.
- Pausas y sesiones.
- SLA configurable.
- Comparativos de llamadas.
- Grabaciones.
- Exportaciones CSV/PDF.
- Usuarios, permisos y auditoría.

## SLA

La política inicial es **80 % dentro de 20 segundos (80/20)** y puede modificarse desde **Administración → Configuración SLA**.

## Seguridad

- La aplicación no usa MySQL `root` durante su funcionamiento normal.
- Se crea un usuario MySQL técnico exclusivo para el panel.
- AMI usa un usuario separado restringido a `127.0.0.1` cuando panel y Asterisk están en el mismo servidor.
- Las contraseñas de usuarios se almacenan mediante `password_hash()`.
- `config.php` permanece fuera del acceso HTTP directo y con permisos restringidos.
- No use `chmod 777` sobre el panel.
- Realice un snapshot/backup antes de actualizar una central en producción.

## Actualización

Para volver a instalar/actualizar usando siempre la última Release estable:

```bash
sudo -i
cd /root
curl -fsSL \
  https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/install-latest.sh \
  -o install-latest.sh
chmod +x install-latest.sh
./install-latest.sh
```

El instalador principal crea un respaldo del directorio web existente antes de reemplazarlo.

## Proyecto

Repositorio: `orlandopy31/issabel-callcenter-monitor`
