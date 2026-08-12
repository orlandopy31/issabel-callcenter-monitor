# Cybermatica Issabel Call Center Monitor

Panel web para **Issabel 5 / Asterisk** orientado a monitoreo, supervisión, productividad, SLA, grabaciones, licenciamiento y reportería operativa.

## Versión principal recomendada

**Versión estable principal: v1.0.5**

Esta es la versión recomendada para nuevas instalaciones y actualizaciones.

**Descarga directa:**

https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.5/issabel-callcenter-monitor-v1.0.5.zip

**Release:**

https://github.com/orlandopy31/issabel-callcenter-monitor/releases/tag/v1.0.5

SHA-256 oficial:

```text
a4af7feb966f7f8c8e9dbc1385a346972c1f632880dc4e4b8caf56f85bdc1395
```

## Instalación paso a paso de v1.0.5

### 1. Ingresar como root

```bash
sudo -i
```

### 2. Instalar herramientas necesarias

En Issabel 5 / Rocky Linux 8:

```bash
dnf -y install curl wget unzip
```

### 3. Descargar el paquete oficial

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.5.zip \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.5/issabel-callcenter-monitor-v1.0.5.zip
```

### 4. Verificar integridad

```bash
cd /root
sha256sum issabel-callcenter-monitor-v1.0.5.zip
```

Debe devolver:

```text
a4af7feb966f7f8c8e9dbc1385a346972c1f632880dc4e4b8caf56f85bdc1395  issabel-callcenter-monitor-v1.0.5.zip
```

### 5. Descomprimir

```bash
cd /root
rm -rf issabel-callcenter-monitor-v1.0.5
unzip issabel-callcenter-monitor-v1.0.5.zip
cd issabel-callcenter-monitor-v1.0.5
```

### 6. Ejecutar el instalador

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

## Issabel Call Center

Antes de instalar el monitor, v1.0.5 verifica Issabel, Asterisk, MariaDB/MySQL, `asteriskcdrdb`, `asterisk`, la base `call_center`, las tablas operativas, `agent_console` e `issabeldialer`.

Si **Issabel Call Center no está instalado o está incompleto**, el instalador puede instalarlo/repararlo automáticamente en **Issabel 5 sobre Rocky Linux 8** y vuelve a validar sus componentes antes de continuar.

Log de esa operación:

```text
/var/log/callcenter-panel-callcenter-install.log
```

## Licencia v1.0.5

Cada instalación v1.0.5 registra una instalación única contra el servidor de licencias de Cybermatica y obtiene una **Licence Key**.

Servidor de licencias:

```text
https://www.cybermatica.com.py/licence
```

La licencia se crea **ACTIVA**. La suspensión o reactivación se realiza **exclusivamente de forma manual** desde el administrador de licencias de Cybermatica.

El licenciamiento no detiene Asterisk ni Issabel; en caso de una suspensión manual se bloquea únicamente el acceso a Cybermatica Issabel Call Center Monitor.

Para comprobar el timer de licencia:

```bash
systemctl status cybermatica-license-check.timer --no-pager
systemctl list-timers cybermatica-license-check.timer
```

Para forzar una validación:

```bash
php /var/www/html/callcenter-panel/bin/license_check.php
```

## PASO OBLIGATORIO: aplicar permisos después de instalar

Después de ejecutar `install.sh`, el usuario debe **aplicar y verificar los permisos del panel** antes de abrirlo en el navegador.

Ejecute exactamente:

```bash
sudo -i

TARGET="/var/www/html/callcenter-panel"

# Permitir que Apache atraviese la ruta web
chown root:root /var/www /var/www/html
chmod 755 /var/www /var/www/html

# Código de la aplicación
chown -R root:apache "$TARGET"
find "$TARGET" -type d -exec chmod 755 {} \;
find "$TARGET" -type f -exec chmod 644 {} \;

# Archivos principales
chown root:apache "$TARGET/index.php" "$TARGET/.htaccess" "$TARGET/config.php"
chmod 644 "$TARGET/index.php"
chmod 644 "$TARGET/.htaccess"
chmod 640 "$TARGET/config.php"

# Directorio escribible
chown -R apache:apache "$TARGET/cache"
find "$TARGET/cache" -type d -exec chmod 770 {} \;
find "$TARGET/cache" -type f -exec chmod 660 {} \;
```

El resultado esperado es:

```text
/var/www/html/callcenter-panel   root:apache     755
index.php                         root:apache     644
.htaccess                         root:apache     644
config.php                        root:apache     640
cache/                            apache:apache   770
```

> Que los archivos PHP tengan propietario `root` es correcto. El grupo debe ser `apache`. Solamente `cache/` debe quedar escribible por Apache.

### Verificar lectura real como Apache

```bash
runuser -u apache -- test -x /var/www/html/callcenter-panel && echo "OK directorio"
runuser -u apache -- test -r /var/www/html/callcenter-panel/index.php && echo "OK index.php"
runuser -u apache -- test -r /var/www/html/callcenter-panel/.htaccess && echo "OK .htaccess"
runuser -u apache -- test -r /var/www/html/callcenter-panel/config.php && echo "OK config.php"
```

Deben aparecer los cuatro mensajes `OK`.

## Apache y SELinux

Compruebe:

```bash
apachectl -t
getenforce
ls -ldZ /var/www/html/callcenter-panel
ls -ldZ /var/www/html/callcenter-panel/cache
```

Si aparece un 403 Forbidden puede ejecutar:

```bash
cd /root
curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
-o REPARAR_403.sh
chmod +x REPARAR_403.sh
./REPARAR_403.sh /var/www/html/callcenter-panel
```

## Primer acceso y uso

Panel:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Wallboard:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

Después del primer ingreso:

1. compruebe que la licencia aparezca como **ACTIVE**;
2. cambie o confirme la contraseña administrativa;
3. cree los usuarios del sistema y asigne permisos;
4. revise **Administración → Configuración SLA**;
5. pruebe el Dashboard y Productividad;
6. compruebe agentes y pausas;
7. valide abandonadas y devoluciones;
8. pruebe grabaciones;
9. configure el usuario de Wallboard si utilizará una TV;
10. pruebe supervisión AMI/ChanSpy solamente con usuarios autorizados.

## Funciones principales

- Dashboard ejecutivo.
- Monitoreo de agentes en tiempo real.
- Wallboard profesional para TV.
- Productividad por agente.
- Llamadas recibidas y realizadas.
- Llamadas abandonadas y devueltas.
- Campañas salientes.
- Pausas y sesiones.
- Nivel de servicio / SLA configurable.
- Grabaciones.
- Escucha, susurro y conferencia mediante AMI + ChanSpy.
- Exportaciones CSV/PDF.
- Usuarios y permisos granulares.
- Auditoría.
- Licence Key por instalación con suspensión/reactivación manual centralizada.

## Diagnóstico

```bash
cd /var/www/html/callcenter-panel
sudo -u apache php bin/diagnostico.php
```

También revise:

```bash
systemctl status httpd --no-pager
systemctl status php-fpm --no-pager
systemctl status issabeldialer --no-pager
systemctl status cybermatica-license-check.timer --no-pager
asterisk -rx "core show version"
```

## Documentación

- [Guía de instalación desde cero](GUIA_INSTALACION_DESDE_CERO.md)
- [Guía de instalación y uso v1.0.5](GUIA_INSTALACION_Y_USO_v1.0.5.md)
- [Dependencia Issabel Call Center](DEPENDENCIA_ISSABEL_CALLCENTER.md)
- [Seguridad](SECURITY.md)

## Seguridad

- no use `chmod 777` sobre el panel;
- el código PHP debe quedar `root:apache`;
- solamente `cache/` debe ser escribible por Apache;
- PHP no utiliza MySQL `root` durante el funcionamiento normal;
- AMI debe mantenerse restringido a localhost cuando panel y Asterisk están en el mismo servidor;
- realice backup o snapshot antes de instalar o actualizar una central en producción.

## Versión

```text
1.0.5
```

## Proyecto

Repositorio: `orlandopy31/issabel-callcenter-monitor`
