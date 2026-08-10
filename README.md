# Cybermatica Call Center Monitor

Panel web para **Issabel Call Center / Asterisk** orientado a monitoreo, supervisión, SLA y reportería operativa.

**Código actual en `main`: v1.0.1**

> **Corrección v1.0.1:** se corrigió el posible error **403 Forbidden** después de instalar en Issabel, relacionado con permisos Unix, contexto SELinux y `DirectoryIndex` de Apache.

## Funciones principales

- Dashboard ejecutivo.
- Monitoreo en tiempo real de agentes.
- Wallboard profesional para TV (`live.php?tv=1`).
- Escucha, susurro y conferencia mediante AMI + ChanSpy.
- Productividad por agente.
- Llamadas entrantes/salientes y trazabilidad.
- Campañas salientes.
- Pausas y sesiones.
- Llamadas abandonadas y devoluciones.
- Nivel de servicio / SLA configurable.
- Comparativo de llamadas entrantes.
- Fuera de horario.
- Formularios de Call Center.
- Grabaciones.
- Exportaciones CSV y PDF.
- Usuarios, permisos granulares y auditoría.

## Corrección 403 Forbidden

Si ya instaló la versión 1.0.0 y Apache responde:

```text
Forbidden
You don't have permission to access this resource.
```

no es necesario reinstalar. Ejecute en el servidor Issabel:

```bash
cd /root
curl -fsSL https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh -o REPARAR_403.sh
chmod +x REPARAR_403.sh
sudo ./REPARAR_403.sh /var/www/html/callcenter-panel
```

El reparador:

1. corrige propietario y permisos de archivos/directorios;
2. garantiza `DirectoryIndex index.php`;
3. aplica `httpd_sys_content_t` al panel cuando SELinux está activo;
4. aplica `httpd_sys_rw_content_t` a `cache/`;
5. crea una regla explícita de Apache para permitir el acceso al panel en Issabel;
6. valida la configuración de Apache antes de reiniciar.

Después pruebe:

```text
http://IP_DEL_ISSABEL/callcenter-panel/
```

## Requisitos

El servidor debe contar con Issabel, Asterisk e Issabel Call Center. Como mínimo deben existir:

- `call_center.agent`
- `call_center.audit`
- `call_center.call_entry`
- `asteriskcdrdb.cdr`

Además se requiere PHP 7.2 o superior y PDO MySQL.

## Instalación nueva

Para instalaciones nuevas se recomienda utilizar **v1.0.1 o superior** desde la sección **Releases**.

El instalador v1.0.1 ya incorpora la corrección de permisos y SELinux automáticamente.

La instalación habitual es:

```bash
unzip issabel-callcenter-monitor-v1.0.1.zip
cd cybermatica_issabel_callcenter_monitor_v1.0
sudo bash install.sh
```

El instalador:

1. verifica PHP, PDO MySQL y las bases de Issabel;
2. crea `callcenter_panel`;
3. crea un usuario MySQL exclusivo con lectura sobre las bases de Issabel;
4. crea el superadministrador inicial;
5. instala el panel en `/var/www/html/callcenter-panel`;
6. genera `config.php` con las credenciales técnicas creadas durante la instalación;
7. configura un usuario AMI local para monitoreo/supervisión;
8. ajusta permisos, cache y SELinux;
9. valida PHP y Apache antes del reinicio.

Consulte **[GUIA_INSTALACION_DESDE_CERO.md](GUIA_INSTALACION_DESDE_CERO.md)** antes de instalar en producción.

## Wallboard para TV

Para una pantalla pública de operación, cree un usuario con únicamente el permiso:

```text
live.view
```

Luego utilice:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

## SLA

La política inicial es **80 % dentro de 20 segundos (80/20)** y puede modificarse desde **Administración → Configuración SLA**.

El sistema diferencia entre:

- **Tiempo SLA:** máximo de segundos para considerar una llamada dentro del SLA.
- **Meta SLA:** porcentaje mínimo requerido para considerar que la operación cumple.
- **NS ajustado por recuperación:** indicador separado que contempla abandonadas recuperadas posteriormente.

## Seguridad

- La aplicación no necesita conectarse a MySQL como `root` durante su operación normal.
- El usuario AMI se restringe a `127.0.0.1` cuando panel y Asterisk están en el mismo servidor.
- Las contraseñas de usuarios se guardan con `password_hash()`.
- No publique el `config.php` generado en un servidor real.
- Revise **[SECURITY.md](SECURITY.md)** antes de exponer el panel a Internet.

## Versión

`1.0.1`

## Autor / proyecto

Repositorio: `orlandopy31/issabel-callcenter-monitor`
