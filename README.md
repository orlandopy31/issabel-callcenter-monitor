# Cybermatica Call Center Monitor

Panel web para **Issabel 5 / Asterisk** orientado a monitoreo, supervisión, productividad, SLA y reportería operativa.

## Instalación recomendada — siempre la última versión

No es necesario cambiar los comandos de instalación cada vez que se publique una nueva versión.

El repositorio incluye `install-latest.sh`, que consulta automáticamente la **última Release estable publicada en GitHub**, descarga su ZIP y ejecuta el instalador correspondiente.

Ejecute como `root` en el servidor Issabel:

```bash
cd /root

curl -fsSL \
  https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/install-latest.sh \
  -o install-latest.sh

chmod +x install-latest.sh
sudo ./install-latest.sh
```

El proceso mostrará qué versión encontró antes de descargarla:

```text
==> Consultando la última versión publicada en GitHub
Última versión: vX.Y.Z
Paquete: issabel-callcenter-monitor-vX.Y.Z.zip

==> Descargando vX.Y.Z
==> Ejecutando instalador de vX.Y.Z
```

De esta manera, cuando se publique `v1.0.3`, `v1.0.4` o cualquier versión posterior, **los mismos comandos seguirán instalando la versión más reciente**.

> La fuente utilizada para determinar la versión es la Release marcada por GitHub como `latest`. Una versión `draft` o `prerelease` no se utilizará como instalación estable.

## Qué hace el instalador

Antes de instalar el panel, el sistema comprueba:

- Issabel y Asterisk;
- PHP y PDO MySQL;
- MariaDB/MySQL;
- las bases `asterisk` y `asteriskcdrdb`;
- `asteriskcdrdb.cdr`;
- la instalación de Issabel Call Center;
- las tablas de `call_center` utilizadas por el panel;
- el módulo web `agent_console`;
- el servicio `issabeldialer`.

Si Issabel Call Center está ausente o incompleto en **Issabel 5 sobre Rocky Linux 8**, el instalador puede instalarlo/repararlo automáticamente desde `ISSABELPBX/callcenter-issabel5` y vuelve a validar sus componentes antes de continuar.

El flujo es:

```text
Verificar Issabel / Asterisk / MySQL
        ↓
Verificar Issabel Call Center
        ↓
¿Está completo?
   ├── Sí → continuar
   └── No → instalar/reparar Call Center
                    ↓
             validar nuevamente
                    ↓
        instalar Call Center Monitor
```

El log de instalación automática de Call Center queda en:

```text
/var/log/callcenter-panel-callcenter-install.log
```

## Desactivar la instalación automática de Issabel Call Center

Si desea que el instalador no modifique el módulo Call Center:

```bash
CC_AUTO_INSTALL_CALLCENTER=0 sudo -E ./install-latest.sh
```

Si Call Center no está instalado o está incompleto, la instalación se detendrá con un diagnóstico.

## Usar otra revisión del módulo Issabel Call Center

El instalador del monitor utiliza por defecto una revisión validada del módulo Call Center para evitar cambios externos inesperados.

Para utilizar explícitamente la rama `master` del proyecto de Call Center:

```bash
CC_CALLCENTER_GIT_REF=master sudo -E ./install-latest.sh
```

En producción se recomienda conservar la revisión fijada por cada versión del monitor hasta validar una revisión nueva.

Más detalles: **[DEPENDENCIA_ISSABEL_CALLCENTER.md](DEPENDENCIA_ISSABEL_CALLCENTER.md)**.

## Funciones principales

- Dashboard ejecutivo.
- Monitoreo en tiempo real de agentes.
- Wallboard profesional para TV (`live.php?tv=1`).
- Escucha, susurro y conferencia mediante AMI + ChanSpy.
- Productividad por agente.
- Llamadas entrantes y salientes.
- Llamadas abandonadas y devoluciones.
- Campañas salientes.
- Pausas y sesiones.
- Nivel de servicio / SLA configurable.
- Comparativo de llamadas entrantes.
- Fuera de horario.
- Formularios de Call Center.
- Grabaciones.
- Exportaciones CSV y PDF.
- Usuarios, permisos granulares y auditoría.

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

La política inicial es **80 % dentro de 20 segundos (80/20)** y puede modificarse desde:

**Administración → Configuración SLA**

## Reparar 403 Forbidden

Las versiones actuales incluyen la corrección de permisos Unix, SELinux y `DirectoryIndex index.php`.

Para reparar una instalación anterior:

```bash
cd /root
curl -fsSL \
  https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/REPARAR_403.sh \
  -o REPARAR_403.sh
chmod +x REPARAR_403.sh
sudo ./REPARAR_403.sh /var/www/html/callcenter-panel
```

## Seguridad

- PHP no opera con el usuario MySQL `root` durante el funcionamiento normal.
- El panel crea un usuario MySQL técnico exclusivo.
- AMI utiliza un usuario separado restringido a `127.0.0.1` cuando Asterisk está en el mismo servidor.
- Las contraseñas del panel se almacenan mediante `password_hash()`.
- Después de instalar o reparar Call Center, el panel vuelve a validar los componentes requeridos.
- Revise **[SECURITY.md](SECURITY.md)** antes de exponer el panel a Internet.

## Actualización

Para instalar una versión nueva publicada en GitHub, vuelva a ejecutar exactamente los mismos comandos:

```bash
cd /root
curl -fsSL \
  https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/install-latest.sh \
  -o install-latest.sh
chmod +x install-latest.sh
sudo ./install-latest.sh
```

El instalador principal realiza respaldo de la instalación web existente antes de reemplazarla.

## Documentación

- **[Guía de instalación desde cero](GUIA_INSTALACION_DESDE_CERO.md)**
- **[Dependencia Issabel Call Center](DEPENDENCIA_ISSABEL_CALLCENTER.md)**
- **[Seguridad](SECURITY.md)**

## Proyecto

Repositorio: `orlandopy31/issabel-callcenter-monitor`
