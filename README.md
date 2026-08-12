# Cybermatica Call Center Monitor

Panel web para **Issabel 5 / Asterisk** orientado a monitoreo, supervisión, productividad, SLA y reportería operativa.

**Código actual en `main`: v1.0.2**

## Novedad v1.0.2: instalación automática de Issabel Call Center

El instalador instala el modudo de `call_center` no estén presentes.

Antes de instalar el panel, `install.sh` verifica:

- las bases base de Issabel (`asterisk` y `asteriskcdrdb`);
- la tabla `asteriskcdrdb.cdr`;
- las tablas de `call_center` que utiliza el panel;
- el módulo web `agent_console`;
- el servicio `issabeldialer`.

Si Issabel Call Center está ausente o incompleto, **lo instala/repara automáticamente** desde `ISSABELPBX/callcenter-issabel5` y después vuelve a validar todos los componentes antes de continuar.

Por seguridad y reproducibilidad, v1.0.2 usa por defecto una revisión conocida del módulo Call Center:

```text
82843e063722274276e787c795d8ae20740bd569
```

Puede cambiarse mediante `CC_CALLCENTER_GIT_REF`.

> La instalación automática está diseñada para **Issabel 5 sobre Rocky Linux 8**. En otra plataforma se detiene con un diagnóstico claro en lugar de instalar una versión incompatible.

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

## Instalación v1.0.2

Cuando publique la Release `v1.0.2`, descargue el ZIP de esa versión y ejecute:

```bash
cd /root
unzip issabel-callcenter-monitor-v1.0.2.zip
cd issabel-callcenter-monitor-v1.0.2
sudo bash install.sh
```

Si Call Center no está instalado, el flujo será:

```text
Detectar ausencia/inconsistencia
        ↓
Instalar git si hace falta
        ↓
Obtener ISSABELPBX/callcenter-issabel5
        ↓
Ejecutar build/5.0/install-issabel-callcenter.sh -l
        ↓
Validar tablas + agent_console + issabeldialer
        ↓
Continuar con Call Center Monitor
```

El log de instalación de la dependencia queda en:

```text
/var/log/callcenter-panel-callcenter-install.log
```

## Desactivar instalación automática de Call Center

```bash
CC_AUTO_INSTALL_CALLCENTER=0 sudo -E bash install.sh
```

Si el módulo falta, el instalador se detendrá sin modificar Call Center.

## Usar otra revisión de Call Center

Para usar explícitamente `master`:

```bash
CC_CALLCENTER_GIT_REF=master sudo -E bash install.sh
```

En producción se recomienda conservar la revisión fijada por el paquete hasta validar una nueva.

Más detalles: **[DEPENDENCIA_ISSABEL_CALLCENTER.md](DEPENDENCIA_ISSABEL_CALLCENTER.md)**.

## Corrección 403 incluida

v1.0.2 conserva la corrección de v1.0.1 para permisos Unix, SELinux y `DirectoryIndex index.php`.

Para reparar una instalación anterior:

```bash
cd /root
curl -fsSL https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh -o REPARAR_403.sh
chmod +x REPARAR_403.sh
sudo ./REPARAR_403.sh /var/www/html/callcenter-panel
```

## Wallboard para TV

Para una pantalla pública, cree un usuario con únicamente:

```text
live.view
```

Luego abra:

```text
http://IP_DEL_ISSABEL/callcenter-panel/live.php?tv=1
```

## SLA

La política inicial es **80 % dentro de 20 segundos (80/20)** y puede modificarse desde **Administración → Configuración SLA**.

## Seguridad

- PHP no opera con el usuario MySQL `root` durante la operación normal.
- El panel crea un usuario MySQL técnico exclusivo.
- AMI usa un usuario separado restringido a `127.0.0.1`.
- Las contraseñas del panel usan `password_hash()`.
- Después de instalar Call Center, el panel vuelve a validar sus componentes antes de continuar.
- Revise **[SECURITY.md](SECURITY.md)** antes de exponer el panel a Internet.

## Versión

`1.0.2`

## Proyecto

Repositorio: `orlandopy31/issabel-callcenter-monitor`
