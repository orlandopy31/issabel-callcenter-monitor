# Guía práctica de instalación y uso
## Cybermatica Issabel Call Center Monitor v1.0.5

Esta guía está pensada para instalar el sistema desde cero y dejarlo listo para uso operativo.

## 1. Descargar el paquete oficial

Ingrese al servidor como root:

```bash
sudo -i
```

Instale las herramientas necesarias:

```bash
dnf -y install curl wget unzip
```

Descargue v1.0.5:

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.5.zip \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.5/issabel-callcenter-monitor-v1.0.5.zip
```

Verifique:

```bash
sha256sum issabel-callcenter-monitor-v1.0.5.zip
```

Debe coincidir con:

```text
a4af7feb966f7f8c8e9dbc1385a346972c1f632880dc4e4b8caf56f85bdc1395
```

## 2. Descomprimir e instalar

```bash
cd /root
rm -rf issabel-callcenter-monitor-v1.0.5
unzip issabel-callcenter-monitor-v1.0.5.zip
cd issabel-callcenter-monitor-v1.0.5
chmod +x install.sh
./install.sh
```

Use normalmente:

```text
Directorio web: /var/www/html/callcenter-panel
Zona horaria: America/Asuncion
Administrador BD: root
```

Defina también el usuario y contraseña administrador del panel.

## 3. Issabel Call Center

El instalador comprueba Issabel Call Center. Si no está instalado o está incompleto, puede instalarlo/repararlo automáticamente en Issabel 5 / Rocky Linux 8.

Si hay un problema revise:

```bash
tail -n 150 /var/log/callcenter-panel-callcenter-install.log
systemctl status issabeldialer -l --no-pager
```

## 4. Licencia

Durante la instalación el servidor se registra en Cybermatica y recibe:

```text
Installation ID
Licence Key
Estado ACTIVE
```

Servidor central:

```text
https://www.cybermatica.com.py/licence
```

La licencia únicamente puede ser suspendida o reactivada manualmente por Cybermatica.

Compruebe el servicio de verificación:

```bash
systemctl status cybermatica-license-check.timer --no-pager
```

Puede forzar una validación:

```bash
php /var/www/html/callcenter-panel/bin/license_check.php
```

## 5. Aplicar permisos obligatorios

No omita este paso.

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

Debe quedar:

```text
/var/www/html/callcenter-panel   root:apache     755
index.php                         root:apache     644
.htaccess                         root:apache     644
config.php                        root:apache     640
cache/                            apache:apache   770
```

## 6. Comprobar Apache

```bash
runuser -u apache -- test -x /var/www/html/callcenter-panel && echo "OK directorio"
runuser -u apache -- test -r /var/www/html/callcenter-panel/index.php && echo "OK index.php"
runuser -u apache -- test -r /var/www/html/callcenter-panel/.htaccess && echo "OK .htaccess"
runuser -u apache -- test -r /var/www/html/callcenter-panel/config.php && echo "OK config.php"
apachectl -t
```

Si aparece 403:

```bash
cd /root
curl -fsSL \
https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
-o REPARAR_403.sh
chmod +x REPARAR_403.sh
./REPARAR_403.sh /var/www/html/callcenter-panel
```

## 7. Primer ingreso

Abra desde un navegador:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Ingrese con el administrador creado durante la instalación.

Verifique primero:

```text
Licencia: ACTIVE
Dashboard: carga correctamente
Agentes: visibles
Base de datos: conectada
AMI: disponible
```

## 8. Crear usuarios

Desde Administración cree usuarios según función.

Ejemplos:

```text
Administrador
Supervisor
Reportes
Wallboard
```

No otorgue permisos administrativos innecesarios.

Para Wallboard/TV otorgue solamente:

```text
live.view
```

## 9. Dashboard

Use el Dashboard para visualizar los indicadores operativos generales del Call Center.

Revise especialmente:

```text
agentes conectados
agentes disponibles
en llamada
en pausa
llamadas recibidas
llamadas realizadas
abandonadas
devueltas
nivel de servicio
```

## 10. Productividad

En Productividad puede comparar el trabajo por agente y período.

Revise:

```text
llamadas recibidas
llamadas realizadas
no respondidas netas
llamadas devueltas
tiempos de conversación
pausas
sesiones
```

## 11. SLA

La configuración inicial es:

```text
80 % dentro de 20 segundos
```

Para modificarla ingrese a:

```text
Administración > Configuración SLA
```

## 12. Agentes y pausas

Compruebe regularmente:

```text
estado actual del agente
hora de login
pausas realizadas
duración de pausas
llamadas atendidas
```

## 13. Abandonadas y devoluciones

El sistema permite revisar llamadas no atendidas y las devoluciones posteriores.

Utilice estos datos para controlar recuperación de llamadas y seguimiento operativo.

## 14. Grabaciones

Abra el módulo Grabaciones y compruebe que los audios puedan reproducirse.

Si no hay acceso revise:

```bash
ls -ld /var/spool/asterisk/monitor
ls -ld /var/spool/asterisk/monitoring
```

No use `chmod 777`; utilice grupo o ACL si necesita dar lectura a Apache.

## 15. Wallboard

URL:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

Utilice una cuenta con `live.view` únicamente cuando la pantalla sea compartida.

## 16. Supervisión

Las funciones de escucha, susurro y conferencia utilizan AMI + ChanSpy.

Asigne estos permisos solamente a supervisores autorizados.

## 17. Reportes

Use los módulos de reportes para consultar y exportar información en CSV/PDF.

Antes de entregar reportes compare una muestra con los datos de Issabel/CDR para validar el período y filtros utilizados.

## 18. Diagnóstico general

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

## 19. Qué hacer si la licencia aparece SUSPENDED

Una licencia suspendida no se reactiva automáticamente.

Debe ser reactivada manualmente desde el administrador de licencias de Cybermatica. Después puede forzar la comprobación local:

```bash
php /var/www/html/callcenter-panel/bin/license_check.php
```

La suspensión del Monitor no detiene Asterisk, Issabel ni las llamadas de la central.

## 20. Checklist de entrega

Antes de considerar terminada la instalación confirme:

```text
[ ] v1.0.5 instalada
[ ] Licence Key generada
[ ] licencia ACTIVE
[ ] permisos aplicados
[ ] Apache OK
[ ] SELinux revisado
[ ] Issabel Call Center operativo
[ ] issabeldialer activo
[ ] Dashboard operativo
[ ] agentes visibles
[ ] productividad validada
[ ] abandonadas/devueltas revisadas
[ ] SLA configurado
[ ] grabaciones accesibles
[ ] usuarios creados
[ ] Wallboard probado si corresponde
[ ] backup realizado
```

## Soporte técnico

Para diagnóstico conserve siempre:

```bash
apachectl -t
systemctl status httpd --no-pager
systemctl status issabeldialer --no-pager
systemctl status cybermatica-license-check.timer --no-pager
tail -n 100 /var/log/httpd/error_log
```
