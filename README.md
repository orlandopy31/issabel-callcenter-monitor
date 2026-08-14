# Cybermatica Issabel Call Center Monitor

Panel web para **Issabel 5 / Asterisk** orientado a monitoreo, supervisión, productividad, SLA, grabaciones y reportería operativa.
## OBSERVACION IMPORTANTE:
Este sistema esta en modo beta, las licencias aplicadas a este modulo estan liberados, el sistema puede tener errores, seguimos trabajando y mejorando el sistema para tenerlo listo pronto

## Versión principal

**Versión estable principal: v1.0.9**

Paquete recomendado:

```text
issabel-callcenter-monitor-v1.0.9.zip
```

SHA-256 del paquete preparado:

```text
b0ffff3c2299551401bdfcf35ea9be8283c0aab612cc0241c5d813e4f0f2a393
```

## Instalación paso a paso

### 1. Ingresar como root

```bash
sudo -i
```

### 2. Instalar herramientas necesarias

En Issabel 5 / Rocky Linux 8:

```bash
dnf -y install curl wget unzip cronie
```

### 3. Descargar v1.0.9

Una vez publicada la Release `v1.0.9`:

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.9.zip \
https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.9/issabel-callcenter-monitor-v1.0.9.zip
```

### 4. Descomprimir

```bash
cd /root
rm -rf issabel-callcenter-monitor-v1.0.9
unzip issabel-callcenter-monitor-v1.0.9.zip
cd issabel-callcenter-monitor-v1.0.9
```

### 5. Ejecutar el instalador

```bash
chmod +x install.sh
./install.sh
```

Durante la instalación se solicitarán:

- directorio web;
- nombre de empresa/call center;
- nombre de contacto responsable;
- zona horaria;
- usuario administrador de MariaDB/MySQL;
- contraseña administrativa de MariaDB/MySQL;
- usuario administrador del panel;
- nombre del administrador;
- contraseña inicial del panel.

Directorio recomendado:

```text
/var/www/html/callcenter-panel
```

## Issabel Call Center

El instalador verifica Issabel, Asterisk, MariaDB/MySQL, las bases de Asterisk, la base `call_center`, las tablas operativas, `agent_console` e `issabeldialer`.

Si Issabel Call Center está ausente o incompleto en **Issabel 5 sobre Rocky Linux 8**, el instalador puede instalarlo o repararlo automáticamente y vuelve a validar sus componentes antes de continuar.

Log de esa operación:

```text
/var/log/callcenter-panel-callcenter-install.log
```

## Permisos globales del panel

v1.0.7 aplica al finalizar un modo global de compatibilidad:

```bash
chmod -R 0777 /var/www/html/callcenter-panel
```

Para reaplicar manualmente:

```bash
sudo -i
chmod -R 0777 /var/www/html/callcenter-panel
```

> Se utiliza `0777` y no `7777`. `7777` activa además bits especiales `setuid`, `setgid` y `sticky` sobre archivos y directorios.

## Comprobar servicios

```bash
apachectl -t
systemctl status httpd --no-pager
systemctl status php-fpm --no-pager
systemctl status issabeldialer --no-pager
systemctl status crond --no-pager
asterisk -rx "core show version"
```

## Primer acceso

Panel:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

Wallboard:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

## Uso inicial recomendado

Después del primer ingreso:

1. revise el Dashboard;
2. compruebe los agentes conectados;
3. revise Productividad;
4. valide llamadas recibidas y realizadas;
5. controle llamadas abandonadas y devueltas;
6. configure **Administración → Configuración SLA**;
7. revise pausas y sesiones;
8. pruebe grabaciones;
9. cree usuarios y asigne permisos;
10. configure el Wallboard si utilizará una TV.

## Funciones principales

- Dashboard ejecutivo.
- Monitoreo de agentes en tiempo real.
- Wallboard profesional para TV.
- Productividad por agente.
- Llamadas recibidas y realizadas.
- Llamadas abandonadas y devueltas.
- Campañas salientes.
- Pausas y sesiones.
- SLA configurable.
- Grabaciones.
- Escucha, susurro y conferencia mediante AMI + ChanSpy.
- Exportaciones CSV/PDF.
- Usuarios, permisos y auditoría.

## Diagnóstico

```bash
cd /var/www/html/callcenter-panel
php bin/diagnostico.php
```

Validar sintaxis PHP:

```bash
find /var/www/html/callcenter-panel -name '*.php' -print0 \
  | xargs -0 -n1 php -l
```

## Contacto

```text
Cybermatica
Email:    info@cybermatica.com.py
Teléfono: 021 728 9200
Web:      www.cybermatica.com.py
Whatsapp: +595984346094
```

## Versión

```text
v1.0.9
```

## Proyecto

Repositorio:

```text
orlandopy31/issabel-callcenter-monitor
```
<img width="1922" height="959" alt="Captura de pantalla 2026-08-10 133551" src="https://github.com/user-attachments/assets/a9ca6adf-8fa4-46c8-bbc4-4bd57dfb8e5f" />
<img width="1877" height="946" alt="Captura de pantalla 2026-08-14 103527" src="https://github.com/user-attachments/assets/70a96db7-e848-41bb-8c3d-c59c7bade651" />
<img width="1857" height="949" alt="Captura de pantalla 2026-08-14 103550" src="https://github.com/user-attachments/assets/722e5a59-adb3-4f3d-8bab-fe13e20935cd" />
<img width="1869" height="982" alt="Captura de pantalla 2026-08-14 103416" src="https://github.com/user-attachments/assets/ee23e199-b86a-46af-9b5b-def972d7578f" />
<img width="1893" height="947" alt="Captura de pantalla 2026-08-14 103453" src="https://github.com/user-attachments/assets/f1f6cb84-a61c-48d4-bd7f-61c31c2cce4d" />
