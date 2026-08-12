# Dependencia automática de Issabel Call Center

## Objetivo

Desde Call Center Monitor v1.0.2, `install.sh` puede instalar o reparar automáticamente Issabel Call Center cuando detecta que falta la base `call_center`, alguna tabla requerida, `agent_console` o `issabeldialer.service`.

## Fuente utilizada

Repositorio configurado por defecto:

```text
https://github.com/ISSABELPBX/callcenter-issabel5.git
```

Revisión predeterminada del paquete:

```text
82843e063722274276e787c795d8ae20740bd569
```

Esta revisión corresponde al instalador Community V5.0.0-1 revisado durante el desarrollo de v1.0.2.

## Flujo

1. valida MySQL/MariaDB;
2. valida `asterisk` y `asteriskcdrdb`;
3. detecta Call Center;
4. si está incompleto, instala `git` cuando haga falta;
5. clona el repositorio en `/usr/src/callcenter-issabel5-ccpanel`;
6. fija la revisión configurada;
7. ejecuta `build/5.0/install-issabel-callcenter.sh -l`;
8. verifica nuevamente tablas, módulo web y servicio;
9. solo entonces continúa con la instalación del monitor.

## Log

```text
/var/log/callcenter-panel-callcenter-install.log
```

## Variables

```text
CC_AUTO_INSTALL_CALLCENTER=1|0
CC_CALLCENTER_REPO=https://github.com/ISSABELPBX/callcenter-issabel5.git
CC_CALLCENTER_GIT_REF=<branch|tag|commit>
```

## Limitación deliberada

La instalación automática se habilita únicamente cuando se detecta Rocky Linux, porque la dependencia usada está orientada a Issabel 5 / Rocky Linux 8. Esto reduce el riesgo de instalar el módulo de Issabel 5 sobre un Issabel 4/CentOS incompatible.
