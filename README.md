# Cybermatica Call Center Monitor v1.0

Panel web para Issabel Call Center / Asterisk orientado a monitoreo, supervisión y reportería.

## Incluye

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

## Instalación recomendada desde GitHub

```bash
cd /root
git clone https://github.com/orlandopy31/issabel-callcenter-monitor.git
cd issabel-callcenter-monitor
sudo bash install.sh
```

También puede usar **Code → Download ZIP** en GitHub, descomprimir el proyecto y ejecutar `sudo bash install.sh`.

El instalador:

1. verifica PHP, PDO MySQL y bases de Issabel;
2. crea `callcenter_panel`;
3. crea un usuario MySQL exclusivo con lectura sobre las bases de Issabel;
4. crea el superadministrador inicial;
5. instala el panel en `/var/www/html/callcenter-panel`;
6. genera un `config.php` sin usar root como usuario de la aplicación;
7. configura un usuario AMI local para monitoreo/supervisión;
8. ajusta cache, SELinux y permisos;
9. valida todos los PHP y reinicia Apache/PHP-FPM.

Consulte `GUIA_INSTALACION_DESDE_CERO.md` antes de instalar en producción.

## Requisito importante

Issabel Call Center debe estar instalado y debe existir al menos:

- `call_center.agent`
- `call_center.audit`
- `call_center.call_entry`
- `asteriskcdrdb.cdr`

Los módulos opcionales dependen de tablas adicionales creadas por Issabel Call Center.

## Seguridad

- El panel usa un usuario MySQL dedicado; PHP no necesita conectarse como `root`.
- AMI se configura con un usuario exclusivo restringido a `127.0.0.1`.
- Las contraseñas de usuarios del panel se almacenan mediante `password_hash()`.
- No publique el `config.php` generado en un servidor real si contiene credenciales.

Consulte `SECURITY.md` para recomendaciones adicionales.
