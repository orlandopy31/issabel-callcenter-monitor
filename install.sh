#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

APP_VERSION="1.0.1"
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

say "Verificando bases de Issabel"
mysql_run -NBe "SELECT VERSION();" >/dev/null || die "No se pudo conectar a MySQL/MariaDB con las credenciales indicadas."
for db in "$DB_CALLCENTER" "$DB_CDR" "$DB_ASTERISK"; do
  exists="$(mysql_run -NBe "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$(sql_escape "$db")';")"
  [[ "$exists" == "1" ]] || die "No existe la base requerida: $db"
  ok "Base encontrada: $db"
done

for spec in "$DB_CALLCENTER:agent" "$DB_CALLCENTER:audit" "$DB_CALLCENTER:call_entry" "$DB_CDR:cdr"; do
  db="${spec%%:*}"; tb="${spec##*:}"
  exists="$(mysql_run -NBe "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$(sql_escape "$db")' AND TABLE_NAME='$(sql_escape "$tb")';")"
  [[ "$exists" == "1" ]] || die "Falta la tabla requerida ${db}.${tb}. Verifique que Issabel Call Center esté instalado/configurado."
  ok "Tabla encontrada: ${db}.${tb}"
done

APP_DB_PASS="${CC_APP_DB_PASS:-$(random_secret)}"
AMI_SECRET="${CC_AMI_SECRET:-$(random_secret)}"

say "Creando base propia, usuario de aplicación y permisos mínimos"
mysql_run < "$SOURCE_DIR/sql/usuarios_permisos.sql"
APP_DB_USER_ESC="$(sql_escape "$APP_DB_USER")"; APP_DB_PASS_ESC="$(sql_escape "$APP_DB_PASS")"
mysql_run <<SQL
CREATE USER IF NOT EXISTS '${APP_DB_USER_ESC}'@'${APP_DB_HOST}' IDENTIFIED BY '${APP_DB_PASS_ESC}';
ALTER USER '${APP_DB_USER_ESC}'@'${APP_DB_HOST}' IDENTIFIED BY '${APP_DB_PASS_ESC}';
GRANT SELECT, SHOW VIEW ON \`${DB_CALLCENTER}\`.* TO '${APP_DB_USER_ESC}'@'${APP_DB_HOST}';
GRANT SELECT, SHOW VIEW ON \`${DB_CDR}\`.* TO '${APP_DB_USER_ESC}'@'${APP_DB_HOST}';
GRANT SELECT, SHOW VIEW ON \`${DB_ASTERISK}\`.* TO '${APP_DB_USER_ESC}'@'${APP_DB_HOST}';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`${DB_PANEL}\`.* TO '${APP_DB_USER_ESC}'@'${APP_DB_HOST}';
FLUSH PRIVILEGES;
SQL
ok "Usuario MySQL dedicado creado: ${APP_DB_USER}@localhost"

say "Creando superadministrador del panel"
prompt_value ADMIN_USER "Usuario administrador del panel" "$ADMIN_USER"
prompt_value ADMIN_NAME "Nombre del administrador" "$ADMIN_NAME"
ADMIN_PASS="${CC_ADMIN_PASS:-}"
prompt_secret ADMIN_PASS "Contraseña inicial del panel (mínimo 10 caracteres)"
[[ ${#ADMIN_PASS} -ge 10 ]] || die "La contraseña del panel debe tener al menos 10 caracteres."
ADMIN_HASH="$(php -r 'echo password_hash($argv[1], PASSWORD_DEFAULT);' "$ADMIN_PASS")"
ADMIN_USER_ESC="$(sql_escape "$ADMIN_USER")"; ADMIN_NAME_ESC="$(sql_escape "$ADMIN_NAME")"; ADMIN_HASH_ESC="$(sql_escape "$ADMIN_HASH")"
mysql_run "$DB_PANEL" <<SQL
INSERT INTO users (username, full_name, password_hash, active, is_superadmin, must_change_password)
VALUES ('${ADMIN_USER_ESC}','${ADMIN_NAME_ESC}','${ADMIN_HASH_ESC}',1,1,0)
ON DUPLICATE KEY UPDATE full_name=VALUES(full_name), password_hash=VALUES(password_hash), active=1, is_superadmin=1;
SQL
ok "Superadministrador preparado: $ADMIN_USER"

say "Instalando archivos web"
if [[ -d "$TARGET_DIR" && "$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" != "" ]]; then
  BACKUP="${TARGET_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
  cp -a "$TARGET_DIR" "$BACKUP"
  ok "Backup previo: $BACKUP"
fi
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp -a "$SOURCE_DIR/." "$TARGET_DIR/"
rm -f "$TARGET_DIR/install.sh" "$TARGET_DIR/bin/render_config.php" 2>/dev/null || true
rm -rf "$TARGET_DIR/docs" "$TARGET_DIR/sql" 2>/dev/null || true
rm -f "$TARGET_DIR"/*.md "$TARGET_DIR"/VERSION.txt 2>/dev/null || true

export CC_APP_NAME="Panel Ejecutivo Issabel Call Center"
export CC_COMPANY="$COMPANY" CC_TIMEZONE="$TIMEZONE"
export CC_DB_HOST="$DB_HOST" CC_DB_PORT="$DB_PORT" CC_DB_USER="$APP_DB_USER" CC_DB_PASS="$APP_DB_PASS"
export CC_DB_CALLCENTER="$DB_CALLCENTER" CC_DB_CDR="$DB_CDR" CC_DB_ASTERISK="$DB_ASTERISK" CC_DB_PANEL="$DB_PANEL"
export CC_AMI_ENABLED=1 CC_AMI_HOST="$AMI_HOST" CC_AMI_PORT="$AMI_PORT" CC_AMI_USER="$AMI_USER" CC_AMI_SECRET="$AMI_SECRET"
export CC_SUPERVISOR_TECH="$SUPERVISOR_TECH"
php "$SOURCE_DIR/bin/render_config.php" "$TARGET_DIR/config.php"

chown -R root:"$WEB_GROUP" "$TARGET_DIR"
find "$TARGET_DIR" -type d -exec chmod 0750 {} \;
find "$TARGET_DIR" -type f -exec chmod 0640 {} \;
chown -R "$WEB_USER":"$WEB_GROUP" "$TARGET_DIR/cache"
chmod 0770 "$TARGET_DIR/cache"
find "$TARGET_DIR/cache" -type f -exec chmod 0660 {} \;
chmod 0640 "$TARGET_DIR/config.php"
ok "Código instalado en $TARGET_DIR"

say "Configurando AMI dedicado"
MANAGER_CUSTOM="/etc/asterisk/manager_custom.conf"
if [[ -d /etc/asterisk ]]; then
  touch "$MANAGER_CUSTOM"
  cp -a "$MANAGER_CUSTOM" "${MANAGER_CUSTOM}.backup_$(date +%Y%m%d_%H%M%S)"
  MANAGER_MAIN="/etc/asterisk/manager.conf"
  if [[ -f "$MANAGER_MAIN" ]] && ! grep -Eq '^[[:space:]]*#include[[:space:]]+["<]?manager_custom\.conf' "$MANAGER_MAIN"; then
    cp -a "$MANAGER_MAIN" "${MANAGER_MAIN}.backup_$(date +%Y%m%d_%H%M%S)"
    printf '\n#include manager_custom.conf\n' >> "$MANAGER_MAIN"
  fi
  awk '
    BEGIN{skip=0}
    /^; BEGIN CYBERMATICA CCPANEL$/{skip=1; next}
    /^; END CYBERMATICA CCPANEL$/{skip=0; next}
    skip==0{print}
  ' "$MANAGER_CUSTOM" > "${MANAGER_CUSTOM}.tmp"
  AMI_SECRET_ESC="$(printf '%s' "$AMI_SECRET" | sed 's/[&/]/\\&/g')"
  cat >> "${MANAGER_CUSTOM}.tmp" <<EOF

; BEGIN CYBERMATICA CCPANEL
[${AMI_USER}]
secret = ${AMI_SECRET_ESC}
deny = 0.0.0.0/0.0.0.0
permit = 127.0.0.1/255.255.255.255
read = system,call
write = call,originate
; END CYBERMATICA CCPANEL
EOF
  mv "${MANAGER_CUSTOM}.tmp" "$MANAGER_CUSTOM"
  chown asterisk:asterisk "$MANAGER_CUSTOM" 2>/dev/null || true
  chmod 0640 "$MANAGER_CUSTOM"
  restorecon "$MANAGER_CUSTOM" 2>/dev/null || true
  if command -v asterisk >/dev/null 2>&1; then
    asterisk -rx "manager reload" >/dev/null 2>&1 || warn "No se pudo recargar AMI automáticamente. Ejecute: asterisk -rx 'manager reload'"
  fi
  ok "AMI configurado para acceso local: $AMI_USER"
else
  warn "No existe /etc/asterisk. Configure AMI manualmente usando docs/INSTALACION_DESDE_CERO.md."
fi

say "Ajustando SELinux y cache (si corresponde)"
if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null)" != "Disabled" ]]; then
  if command -v setsebool >/dev/null 2>&1; then
    setsebool -P httpd_can_network_connect 1 >/dev/null 2>&1 || warn "No se pudo activar httpd_can_network_connect."
  fi

  if command -v semanage >/dev/null 2>&1; then
    semanage fcontext -a -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null \
      || semanage fcontext -m -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null \
      || true
    semanage fcontext -a -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null \
      || semanage fcontext -m -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null \
      || true
    restorecon -Rv "$TARGET_DIR" >/dev/null 2>&1 || true
  elif command -v chcon >/dev/null 2>&1; then
    chcon -R -t httpd_sys_content_t "$TARGET_DIR" 2>/dev/null || true
    chcon -R -t httpd_sys_rw_content_t "$TARGET_DIR/cache" 2>/dev/null || true
  fi
fi

say "Validando PHP y configuración web"
PHP_ERRORS=0
while IFS= read -r -d '' f; do php -l "$f" >/dev/null || PHP_ERRORS=$((PHP_ERRORS+1)); done < <(find "$TARGET_DIR" -name '*.php' -print0)
[[ "$PHP_ERRORS" == "0" ]] || die "Se detectaron $PHP_ERRORS archivos PHP con error de sintaxis."
if command -v apachectl >/dev/null 2>&1; then
  apachectl -t >/dev/null 2>&1 || die "La configuración de Apache tiene errores. Ejecute: apachectl -t"
elif command -v httpd >/dev/null 2>&1; then
  httpd -t >/dev/null 2>&1 || die "La configuración de Apache tiene errores. Ejecute: httpd -t"
fi
systemctl restart httpd 2>/dev/null || warn "No se pudo reiniciar httpd automáticamente."
systemctl restart php-fpm 2>/dev/null || true
ok "Sintaxis PHP validada."

say "Prueba de conexión con el usuario de aplicación"
MYSQL_PWD="$APP_DB_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" -u "$APP_DB_USER" -NBe "SELECT COUNT(*) FROM \`${DB_CALLCENTER}\`.agent; SELECT COUNT(*) FROM \`${DB_PANEL}\`.users;" >/dev/null \
  && ok "Permisos MySQL del panel verificados." \
  || warn "No se pudo completar la prueba con el usuario de aplicación. Revise grants/config.php."

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
[[ -n "$IP" ]] || IP="IP_DEL_ISSABEL"
cat <<EOF

============================================================
 INSTALACIÓN COMPLETADA
============================================================
URL:       http://${IP}/$(basename "$TARGET_DIR")/
Usuario:   ${ADMIN_USER}
Wallboard: http://${IP}/$(basename "$TARGET_DIR")/live.php?tv=1
SLA:       80% dentro de 20 s (editable desde Administración)

IMPORTANTE:
- La contraseña del administrador es la que acaba de definir; no se imprime aquí.
- config.php contiene las credenciales del usuario técnico del panel y está protegido por permisos de archivo.
- Para la pantalla TV cree un usuario con únicamente el permiso live.view.
- Si las grabaciones no abren, consulte la sección de permisos de grabaciones en la guía.
============================================================
EOF
