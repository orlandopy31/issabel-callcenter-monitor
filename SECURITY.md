# Seguridad

## Credenciales

No publique credenciales reales de MySQL, AMI, administradores ni datos de producción.
El instalador genera credenciales técnicas durante la instalación. Revise el archivo `config.php`
del servidor antes de compartir copias del sistema.

## Recomendaciones

- Mantenga AMI limitado a `127.0.0.1` cuando el panel y Asterisk estén en el mismo servidor.
- Utilice un usuario MySQL dedicado con permisos mínimos.
- Cambie las claves por defecto o temporales inmediatamente.
- Proteja el panel con HTTPS cuando sea accesible fuera de una red confiable.
- Mantenga Issabel, Asterisk, PHP y el sistema operativo actualizados.
- Haga copias de seguridad antes de actualizar el panel o modificar vistas SQL.

## Reporte de vulnerabilidades

No publique credenciales ni información sensible en Issues públicos. Si encuentra una vulnerabilidad,
contacte al mantenedor del repositorio por un canal privado antes de divulgar detalles explotables.
