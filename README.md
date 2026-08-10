# Cybermatica Call Center Monitor

Panel web para **Issabel Call Center / Asterisk** orientado a monitoreo, supervisión, SLA y reportería operativa.

**Versión estable actual: v1.0.0**

## Descargar

**[Descargar Issabel Call Center Monitor v1.0.0](https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.0/issabel-callcenter-monitor-v1.0.zip)**

También puede consultar la página de la versión publicada:

**[Release v1.0.0](https://github.com/orlandopy31/issabel-callcenter-monitor/releases/tag/v1.0.0)**

SHA-256 del paquete oficial:

```text
b6570629c79c9f232b7529b95a39a8c52dbf4eda937d1cd3431a6b631ec548d5
```

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

## Instalación rápida desde la Release

En el servidor Issabel:

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.zip \
  https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.0/issabel-callcenter-monitor-v1.0.zip

unzip issabel-callcenter-monitor-v1.0.zip
cd cybermatica_issabel_callcenter_monitor_v1.0
sudo bash install.sh
```

Si no tiene `wget`, descargue el ZIP desde GitHub, cópielo al servidor y ejecute los mismos pasos desde `unzip`.

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

La vista está pensada para mostrar el estado de gestión de los agentes en un monitor o TV sin exponer herramientas administrativas.

## SLA

La política inicial es **80 % dentro de 20 segundos (80/20)** y puede modificarse desde **Administración → Configuración SLA**.

El sistema diferencia entre:

- **Tiempo SLA:** cantidad máxima de segundos para considerar una llamada atendida dentro del nivel de servicio.
- **Meta SLA:** porcentaje mínimo requerido para considerar que la operación cumple el objetivo.
- **NS ajustado por recuperación:** indicador separado que contempla la gestión posterior de abandonadas recuperadas.

## Seguridad

- La aplicación no necesita conectarse a MySQL como `root` durante su operación normal.
- El usuario AMI se restringe a `127.0.0.1` cuando panel y Asterisk están en el mismo servidor.
- Las contraseñas de usuarios se guardan con `password_hash()`.
- No publique el `config.php` generado en un servidor real si contiene credenciales.
- Revise **[SECURITY.md](SECURITY.md)** antes de exponer el panel a Internet.

## Verificar la descarga

Después de descargar el archivo puede comprobar su integridad con:

```bash
sha256sum issabel-callcenter-monitor-v1.0.zip
```

El resultado esperado es:

```text
b6570629c79c9f232b7529b95a39a8c52dbf4eda937d1cd3431a6b631ec548d5
```

## Autor / proyecto

Proyecto publicado para facilitar el monitoreo y la reportería de operaciones basadas en Issabel Call Center y Asterisk.

Repositorio: `orlandopy31/issabel-callcenter-monitor`
