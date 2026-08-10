# Cybermatica Call Center Monitor v1.0

Panel web para **Issabel Call Center / Asterisk** orientado a monitoreo, supervisión y reportería.

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

## Requisitos

El servidor debe contar con Issabel, Asterisk e Issabel Call Center. Como mínimo deben existir:

- `call_center.agent`
- `call_center.audit`
- `call_center.call_entry`
- `asteriskcdrdb.cdr`

Además se requiere PHP 7.2 o superior y PDO MySQL.

## Instalación

La distribución completa se entrega como `issabel-callcenter-monitor-v1.0.zip`.

> **Importante:** no ejecute `install.sh` desde un clon que no contenga todos los archivos PHP de la aplicación. La versión completa debe incluir las carpetas `api/`, `assets/`, `bin/`, `includes/`, `sql/` y los módulos PHP del panel.

Una vez descargado el paquete completo:

```bash
cd /root
unzip issabel-callcenter-monitor-v1.0.zip
cd issabel-callcenter-monitor-v1.0
sudo bash install.sh
```

El instalador:

1. verifica PHP, PDO MySQL y las bases de Issabel;
2. crea `callcenter_panel`;
3. crea un usuario MySQL exclusivo con lectura sobre las bases de Issabel;
4. crea el superadministrador inicial;
5. instala el panel en `/var/www/html/callcenter-panel`;
6. genera un `config.php` con las credenciales técnicas creadas durante la instalación;
7. configura un usuario AMI local para monitoreo/supervisión;
8. ajusta cache, SELinux y permisos;
9. valida la sintaxis PHP y reinicia los servicios web necesarios.

Consulte `GUIA_INSTALACION_DESDE_CERO.md` antes de instalar en producción.

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

La política inicial es **80 % dentro de 20 segundos (80/20)** y puede modificarse desde **Administración → Configuración SLA**. Los reportes utilizan el valor configurado para calcular cumplimiento.

## Seguridad

- La aplicación no necesita conectarse a MySQL como `root` durante su operación normal.
- El usuario AMI se restringe a `127.0.0.1` cuando panel y Asterisk están en el mismo servidor.
- Las contraseñas de usuarios se guardan con `password_hash()`.
- No publique el `config.php` generado en un servidor real si contiene credenciales.
- Revise `SECURITY.md` antes de exponer el panel a Internet.

## Versión

`1.0.0`
