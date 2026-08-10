# Cybermatica Call Center Monitor

Panel web para **Issabel Call Center / Asterisk** orientado a monitoreo, supervisión, SLA y reportería operativa.

**Versión estable actual: v1.0.1**

> **Corrección v1.0.1:** soluciona el posible error **403 Forbidden** después de instalar en Issabel, relacionado con permisos Unix, contexto SELinux y `DirectoryIndex` de Apache.

## Descargar última versión

**[Descargar Issabel Call Center Monitor v1.0.1](https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.1/issabel-callcenter-monitor-v1.0.1-fixed.zip)**

**[Ver Release v1.0.1](https://github.com/orlandopy31/issabel-callcenter-monitor/releases/tag/v1.0.1)**

SHA-256 del paquete oficial:

```text
af53a7153faa4f0502307638651ec3f07d522cc43446da937cc7e594a58ea802
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

## Instalación rápida v1.0.1

En el servidor Issabel:

```bash
cd /root
wget -O issabel-callcenter-monitor-v1.0.1-fixed.zip \
  https://github.com/orlandopy31/issabel-callcenter-monitor/releases/download/v1.0.1/issabel-callcenter-monitor-v1.0.1-fixed.zip

unzip issabel-callcenter-monitor-v1.0.1-fixed.zip
cd cybermatica_issabel_callcenter_monitor_v1.0
sudo bash install.sh
```

El instalador v1.0.1:

1. verifica PHP, PDO MySQL y las bases de Issabel;
2. crea `callcenter_panel`;
3. crea un usuario MySQL exclusivo con lectura sobre las bases de Issabel;
4. crea el superadministrador inicial;
5. instala el panel en `/var/www/html/callcenter-panel`;
6. genera `config.php` con las credenciales técnicas creadas durante la instalación;
7. configura un usuario AMI local para monitoreo/supervisión;
8. corrige permisos Unix y acceso de Apache;
9. aplica `httpd_sys_content_t` al panel cuando SELinux está activo;
10. aplica `httpd_sys_rw_content_t` a `cache/`;
11. garantiza `DirectoryIndex index.php`;
12. valida PHP y Apache antes de reiniciar servicios.

Consulte **[GUIA_INSTALACION_DESDE_CERO.md](GUIA_INSTALACION_DESDE_CERO.md)** antes de instalar en producción.

## Reparar 403 Forbidden en una instalación existente

Si instaló una versión anterior y Apache responde:

```text
Forbidden
You don't have permission to access this resource.
```

no necesita reinstalar. Ejecute:

```bash
cd /root
curl -fsSL \
  https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
  -o REPARAR_403.sh
chmod +x REPARAR_403.sh
sudo ./REPARAR_403.sh /var/www/html/callcenter-panel
```

El reparador corrige permisos, contexto SELinux, acceso de Apache y `DirectoryIndex`, valida Apache y reinicia los servicios web necesarios.

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

## Verificar la descarga

```bash
sha256sum issabel-callcenter-monitor-v1.0.1-fixed.zip
```

Resultado esperado:

```text
af53a7153faa4f0502307638651ec3f07d522cc43446da937cc7e594a58ea802
```

## Versión

`1.0.1`

## Autor / proyecto

Repositorio: `orlandopy31/issabel-callcenter-monitor`
