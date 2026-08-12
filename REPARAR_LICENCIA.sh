#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_DIR="${1:-/var/www/html/callcenter-panel}"
LICENSE_DIR="${CC_LICENSE_DIR:-/var/lib/cybermatica-callcenter}"
STATE_FILE="${CC_LICENSE_STATE_FILE:-${LICENSE_DIR}/license-state.json}"
CLIENT_FILE="${CC_LICENSE_CLIENT_FILE:-${LICENSE_DIR}/license-client.json}"

ok(){ printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Ejecute como root: sudo bash $0"
[[ -d "$TARGET_DIR" ]] || die "No existe el panel: $TARGET_DIR"
[[ -f "$TARGET_DIR/config.php" ]] || die "No existe $TARGET_DIR/config.php"

# Detectar el usuario/grupo que realmente ejecuta PHP-FPM. No asumir apache.
PHP_USER=""
PHP_GROUP=""
for f in /etc/php-fpm.d/*.conf /etc/php-fpm.conf; do
  [[ -f "$f" ]] || continue
  [[ -n "$PHP_USER" ]] || PHP_USER="$(awk -F= '/^[[:space:]]*user[[:space:]]*=/{gsub(/[[:space:]]/,"",$2); print $2; exit}' "$f" 2>/dev/null || true)"
  [[ -n "$PHP_GROUP" ]] || PHP_GROUP="$(awk -F= '/^[[:space:]]*group[[:space:]]*=/{gsub(/[[:space:]]/,"",$2); print $2; exit}' "$f" 2>/dev/null || true)"
done

# Fallback al usuario configurado por Apache y luego a usuarios habituales.
if [[ -z "$PHP_USER" && -f /etc/httpd/conf/httpd.conf ]]; then
  PHP_USER="$(awk '/^[[:space:]]*User[[:space:]]+/{print $2; exit}' /etc/httpd/conf/httpd.conf 2>/dev/null || true)"
fi
if [[ -z "$PHP_GROUP" && -f /etc/httpd/conf/httpd.conf ]]; then
  PHP_GROUP="$(awk '/^[[:space:]]*Group[[:space:]]+/{print $2; exit}' /etc/httpd/conf/httpd.conf 2>/dev/null || true)"
fi
if [[ -z "$PHP_USER" ]]; then
  for u in apache asterisk www-data; do id "$u" >/dev/null 2>&1 && { PHP_USER="$u"; break; }; done
fi
[[ -n "$PHP_USER" ]] || die "No se pudo detectar el usuario que ejecuta PHP/Apache."
[[ -n "$PHP_GROUP" ]] || PHP_GROUP="$(id -gn "$PHP_USER")"
id "$PHP_USER" >/dev/null 2>&1 || die "El usuario detectado no existe: $PHP_USER"
getent group "$PHP_GROUP" >/dev/null 2>&1 || PHP_GROUP="$(id -gn "$PHP_USER")"

printf 'Usuario PHP detectado: %s\n' "$PHP_USER"
printf 'Grupo PHP detectado:   %s\n' "$PHP_GROUP"

mkdir -p "$LICENSE_DIR"
chown root:"$PHP_GROUP" "$LICENSE_DIR"
chmod 0750 "$LICENSE_DIR"

if [[ -f "$CLIENT_FILE" ]]; then
  chown root:root "$CLIENT_FILE"
  chmod 0600 "$CLIENT_FILE"
else
  warn "No existe $CLIENT_FILE. No se generará una instalación nueva automáticamente."
fi

if [[ ! -f "$STATE_FILE" ]]; then
  if [[ -f "$CLIENT_FILE" ]]; then
    warn "No existe el estado firmado. Intentando recuperar la licencia registrada..."
    php "$TARGET_DIR/bin/license_register.php" || die "No se pudo recuperar/registrar el estado de licencia."
  else
    die "No existen las credenciales locales ni el estado de licencia. Debe ejecutar nuevamente el instalador v1.0.5."
  fi
fi

fix_state_permissions(){
  chown root:"$PHP_GROUP" "$STATE_FILE"
  chmod 0640 "$STATE_FILE"

  if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null)" != "Disabled" ]]; then
    if ! command -v semanage >/dev/null 2>&1 && command -v dnf >/dev/null 2>&1; then
      dnf -y install policycoreutils-python-utils >/dev/null 2>&1 || warn "No se pudo instalar policycoreutils-python-utils."
    fi
    if command -v semanage >/dev/null 2>&1; then
      semanage fcontext -a -t httpd_sys_content_t "$LICENSE_DIR" 2>/dev/null \
        || semanage fcontext -m -t httpd_sys_content_t "$LICENSE_DIR" 2>/dev/null || true
      semanage fcontext -a -t httpd_sys_content_t "$STATE_FILE" 2>/dev/null \
        || semanage fcontext -m -t httpd_sys_content_t "$STATE_FILE" 2>/dev/null || true
      restorecon -v "$LICENSE_DIR" "$STATE_FILE" >/dev/null 2>&1 || true
    elif command -v chcon >/dev/null 2>&1; then
      chcon -t httpd_sys_content_t "$LICENSE_DIR" "$STATE_FILE" 2>/dev/null || true
    fi
  fi
}

verify_as_php_user(){
  runuser -u "$PHP_USER" -- test -x "$LICENSE_DIR" || return 10
  runuser -u "$PHP_USER" -- test -r "$STATE_FILE" || return 11
  runuser -u "$PHP_USER" -- test -r "$TARGET_DIR/config.php" || return 12

  runuser -u "$PHP_USER" -- php -r '
    $root=$argv[1];
    $config=require $root."/config.php";
    require $root."/includes/LicenseManager.php";
    LicenseManager::init($config);
    $r=LicenseManager::loadState();
    echo "WEB_VALID=".(!empty($r["valid"])?"SI":"NO")."\n";
    echo "WEB_STATUS=".($r["status"]??"")."\n";
    echo "WEB_ERROR=".($r["error"]??"")."\n";
    exit(!empty($r["valid"])?0:20);
  ' "$TARGET_DIR"
}

fix_state_permissions
ok "Permisos y contexto SELinux del estado de licencia corregidos."

echo
echo "Estado de archivos:"
ls -ldZ "$LICENSE_DIR" || true
ls -lZ "$STATE_FILE" || true
[[ ! -f "$CLIENT_FILE" ]] || ls -lZ "$CLIENT_FILE" || true

echo
echo "Verificación directa como ${PHP_USER}:"
if ! verify_as_php_user; then
  warn "PHP todavía no valida el estado local. Se intentará revalidar contra Cybermatica."
fi

echo
echo "Verificando licencia contra Cybermatica como root..."
if ! php "$TARGET_DIR/bin/license_check.php"; then
  if [[ -f "$CLIENT_FILE" ]]; then
    warn "El check remoto falló. Revalidando la MISMA Installation ID y Licence Key..."
    cp -a "$STATE_FILE" "${STATE_FILE}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    php "$TARGET_DIR/bin/license_register.php" || die "No se pudo revalidar la licencia registrada."
    fix_state_permissions
    php "$TARGET_DIR/bin/license_check.php" || die "La licencia continúa sin validar después de la revalidación."
  else
    die "La verificación falló y no existe el archivo privado de la instalación."
  fi
fi

fix_state_permissions

echo
echo "Verificación FINAL con el mismo usuario que ejecuta PHP:"
verify_as_php_user || die "El estado es válido por CLI/root pero PHP (${PHP_USER}) todavía no puede validarlo. Copie toda esta salida para diagnóstico."

systemctl restart php-fpm 2>/dev/null || true
systemctl restart httpd 2>/dev/null || true
systemctl restart cybermatica-license-check.timer 2>/dev/null || true

ok "Licencia válida para el usuario real de PHP y servicios reiniciados."
echo "Pruebe nuevamente: http://IP_DEL_ISSABEL/$(basename "$TARGET_DIR")/"
