#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

APP_VERSION="1.0.3"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${CC_TARGET_DIR:-/var/www/html/callcenter-panel}"
DB_HOST="${CC_DB_HOST:-localhost}"
DB_PORT="${CC_DB_PORT:-3306}"
DB_ADMIN_USER="${CC_DB_ADMIN_USER:-root}"
DB_CALLCENTER="${CC_DB_CALLCENTER:-call_center}"
DB_CDR="${CC_DB_CDR:-asteriskcdrdb}"
DB_ASTERISK="${CC_DB_ASTERISK:-asterisk}"
DB_PANEL="callcenter_panel"
APP_DB_USER="${CC_APP_DB_USER:-ccpanel}"
APP_DB_HOST="localhost"
AMI_USER="${CC_AMI_USER:-ccpanel_monitor}"
AMI_HOST="127.0.0.1"
AMI_PORT="5038"
COMPANY="${CC_COMPANY:-Call Center}"
TIMEZONE="${CC_TIMEZONE:-America/Asuncion}"
SUPERVISOR_TECH="${CC_SUPERVISOR_TECH:-PJSIP}"
ADMIN_USER="${CC_ADMIN_USER:-admin}"
ADMIN_NAME="${CC_ADMIN_NAME:-Administrador}"
NON_INTERACTIVE="${CC_NON_INTERACTIVE:-0}"
AUTO_INSTALL_CALLCENTER="${CC_AUTO_INSTALL_CALLCENTER:-1}"
CALLCENTER_REPO="${CC_CALLCENTER_REPO:-https://github.com/ISSABELPBX/callcenter-issabel5.git}"
# Revisión verificada de Call Center Community V5.0.0-1. Puede sobrescribirse con
# CC_CALLCENTER_GIT_REF=master para utilizar la revisión más reciente.
CALLCENTER_GIT_REF="${CC_CALLCENTER_GIT_REF:-82843e063722274276e787c795d8ae20740bd569}"

say(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok(){ printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Ejecute este instalador como root: sudo bash install.sh"
for cmd in php mysql systemctl awk sed grep cp find; do command -v "$cmd" >/dev/null 2>&1 || die "Falta el comando requerido: $cmd"; done
php -r 'exit(version_compare(PHP_VERSION,"7.2.0",">=")?0:1);' || die "Se requiere PHP 7.2 o superior. Detectado: $(php -r 'echo PHP_VERSION;')"
php -m | grep -qi '^PDO$' || die "Falta la extensión PHP PDO."
php -m | grep -qi '^pdo_mysql$' || die "Falta la extensión PHP pdo_mysql/php-mysqlnd."

if id apache >/dev/null 2>&1; then WEB_USER=apache; WEB_GROUP=apache
elif id www-data >/dev/null 2>&1; then WEB_USER=www-data; WEB_GROUP=www-data
else die "No se encontró el usuario web apache ni www-data."; fi

random_secret(){
  if command -v openssl >/dev/null 2>&1; then openssl rand -hex 24
  else php -r 'echo bin2hex(random_bytes(24));'; fi
}

prompt_value(){
  local var="$1" label="$2" default="$3" value=""
  if [[ "$NON_INTERACTIVE" == "1" ]]; then printf -v "$var" '%s' "${!var:-$default}"; return; fi
  read -r -p "$label [$default]: " value
  printf -v "$var" '%s' "${value:-$default}"
}
prompt_secret(){
  local var="$1" label="$2" value=""
  if [[ "$NON_INTERACTIVE" == "1" ]]; then [[ -n "${!var:-}" ]] || die "Falta variable $var en modo no interactivo."; return; fi
  while [[ -z "$value" ]]; do read -r -s -p "$label: " value; echo; done
  printf -v "$var" '%s' "$value"
}
sql_escape(){ printf "%s" "$1" | sed "s/'/''/g"; }

say "Instalador Cybermatica Call Center Monitor v${APP_VERSION}"
prompt_value TARGET_DIR "Directorio web" "$TARGET_DIR"
prompt_value COMPANY "Nombre de empresa/call center" "$COMPANY"
prompt_value TIMEZONE "Zona horaria PHP" "$TIMEZONE"
prompt_value DB_ADMIN_USER "Usuario administrador MySQL/MariaDB" "$DB_ADMIN_USER"
DB_ADMIN_PASS="${CC_DB_ADMIN_PASS:-}"
if [[ "$NON_INTERACTIVE" != "1" ]]; then
  read -r -s -p "Contraseña de ${DB_ADMIN_USER} en MySQL/MariaDB (Enter si no tiene): " DB_ADMIN_PASS; echo
fi

MYSQL=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_ADMIN_USER" --default-character-set=utf8mb4)
mysql_run(){ MYSQL_PWD="$DB_ADMIN_PASS" "${MYSQL[@]}" "$@"; }

schema_exists(){
  local db="$1"
  [[ "$(mysql_run -NBe "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$(sql_escape "$db")';")" == "1" ]]
}

table_exists(){
  local db="$1" tb="$2"
  [[ "$(mysql_run -NBe "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$(sql_escape "$db")' AND TABLE_NAME='$(sql_escape "$tb")';")" == "1" ]]
}

CALLCENTER_REQUIRED_TABLES=(
  agent audit break call_entry calls campaign campaign_entry queue_call_entry
  call_recording call_progress_log current_calls current_call_entry
  form_data_recolected form_data_recolected_entry form_field
)

callcenter_missing_tables(){
  local tb missing=()
  if ! schema_exists "$DB_CALLCENTER"; then
    printf '%s\n' "__DATABASE__"
    return 0
  fi
  for tb in "${CALLCENTER_REQUIRED_TABLES[@]}"; do
    table_exists "$DB_CALLCENTER" "$tb" || missing+=("$tb")
  done
  ((${#missing[@]} > 0)) && printf '%s\n' "${missing[@]}"
  return 0
}

callcenter_installation_complete(){
  local missing
  missing="$(callcenter_missing_tables)"
  [[ -z "$missing" ]] || return 1
  [[ -d /var/www/html/modules/agent_console ]] || return 1
  [[ -f /etc/systemd/system/issabeldialer.service || -f /usr/lib/systemd/system/issabeldialer.service ]] || return 1
  return 0
}

install_or_repair_callcenter(){
  [[ "$AUTO_INSTALL_CALLCENTER" == "1" ]] || die "Issabel Call Center no está completo y la instalación automática está desactivada (CC_AUTO_INSTALL_CALLCENTER=0)."

  say "Issabel Call Center no está instalado/completo. Instalando dependencia automáticamente"
  warn "Se instalará Call Center Community para Issabel 5 desde: $CALLCENTER_REPO"
  warn "Revisión configurada: $CALLCENTER_GIT_REF"

  [[ -f /etc/rocky-release ]] || die "La instalación automática de Call Center incluida en este paquete está diseñada para Issabel 5 sobre Rocky Linux 8. Instale un Call Center compatible manualmente o use CC_AUTO_INSTALL_CALLCENTER=0."
  command -v asterisk >/dev/null 2>&1 || die "No se encontró Asterisk. Verifique primero la instalación base de Issabel."
  asterisk -rx "core show version" >/dev/null 2>&1 || die "Asterisk no responde. Inicie Asterisk antes de instalar el módulo Call Center."

  if ! command -v git >/dev/null 2>&1; then
    say "Instalando git (requerido para obtener Issabel Call Center)"
    if command -v dnf >/dev/null 2>&1; then dnf -y install git
    elif command -v yum >/dev/null 2>&1; then yum -y install git
    else die "No se encontró dnf/yum para instalar git."; fi
  fi

  local dep_installer="$SOURCE_DIR/bin/ensure_issabel_callcenter.sh"
  [[ -f "$dep_installer" ]] || die "Falta el instalador de dependencia: $dep_installer"

  CC_CALLCENTER_REPO="$CALLCENTER_REPO" \
  CC_CALLCENTER_GIT_REF="$CALLCENTER_GIT_REF" \
  bash "$dep_installer" || die "Falló la instalación automática de Issabel Call Center. Revise /var/log/callcenter-panel-callcenter-install.log"

  # La instalación oficial no aborta necesariamente ante todos los fallos internos,
  # por eso el panel hace una verificación independiente antes de continuar.
  local retry missing
  for retry in 1 2 3 4 5; do
    missing="$(callcenter_missing_tables)"
    [[ -z "$missing" ]] && break
    sleep 2
  done
  missing="$(callcenter_missing_tables)"
  [[ -z "$missing" ]] || die "Call Center fue ejecutado, pero siguen faltando componentes de base de datos: $(echo "$missing" | tr '\n' ' '). Revise /var/log/callcenter-panel-callcenter-install.log"

  [[ -d /var/www/html/modules/agent_console ]] || die "La base de Call Center existe, pero no se instaló /var/www/html/modules/agent_console."
  if [[ -f /etc/systemd/system/issabeldialer.service || -f /usr/lib/systemd/system/issabeldialer.service ]]; then
    systemctl daemon-reload || true
    systemctl enable issabeldialer >/dev/null 2>&1 || true
    systemctl is-active --quiet issabeldialer || systemctl restart issabeldialer >/dev/null 2>&1 || true
    systemctl is-active --quiet issabeldialer || die "El servicio issabeldialer qued� inactivo después de la instalación. Ejecute: systemctl status issabeldialer -l"
  else
    die "No se instaló el servicio issabeldialer. Revise el log de instalación."
  fi
  ok "Issabel Call Center quedó instalado y validado."
}

say "Verificando plataforma y bases de Issabel"
mysql_run -NBe "SELECT VERSION();" >/dev/null || die "No se pudo conectar a MySQL/MariaDB con las credenciales indicadas."

# Estas bases pertenecen a la instalación base de Issabel y deben existir antes
# de intentar instalar el módulo Call Center.
for db in "$DB_CDR" "$DB_ASTERISK"; do
  schema_exists "$db" || die "No existe la base requerida de Issabel: $db"
  ok "Base encontrada: $db"
done

table_exists "$DB_CDR" "cdr" || die "Falta la tabla requerida ${DB_CDR}.cdr. Verifique primero la instalación base de Issabel."
ok "Tabla encontrada: ${DB_CDR}.cdr"

if callcenter_installation_complete; then
  ok "Issabel Call Center detectado: base, módulos web y servicio presentes."
else
  missing="$(callcenter_missing_tables)"
  if [[ -n "$missing" ]]; then
    warn "Call Center incompleto. Componentes de base faltantes: $(echo "$missing" | tr '\n' ' ')"
  else
    warn "La base de Call Center está completa, pero faltan módulos web o el servicio issabeldialer."
  fi
  install_or_repair_callcenter
fi

# Validación final de todas las tablas que usa el panel. Esto evita que la
# instalación continúe y falle más adelante al abrir reportes/productividad.
for tb in "${CALLCENTER_REQUIRED_TABLES[@]}"; do
  table_exists "$DB_CALLCENTER" "$tb" || die "Falta la tabla requerida ${DB_CALLCENTER}.${tb} después de validar Call Center."
done
ok "Base de Issabel Call Center validada (${#CALLCENTER_REQUIRED_TABLES[@]} tablas requeridas)."

APP_DB_PASS="${CC_APP_DB_PASS:-$(random_secret)}"
AMI_SECRET="${CC_AMI_SECRET:-$(random_secret)}"

say "Creando base propia, usuario de aplicación y permisos mínimos"