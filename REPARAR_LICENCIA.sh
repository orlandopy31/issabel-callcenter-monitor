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

if id apache >/dev/null 2>&1; then WEB_USER=apache; WEB_GROUP=apache
elif id www-data >/dev/null 2>&1; then WEB_USER=www-data; WEB_GROUP=www-data
else die "No se encontró usuario apache/www-data."; fi

mkdir -p "$LICENSE_DIR"
chown root:"$WEB_GROUP" "$LICENSE_DIR"
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

chown root:"$WEB_GROUP" "$STATE_FILE"
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
    restorecon -v "$LICENSE_DIR" "$STATE_FILE" || true
  elif command -v chcon >/dev/null 2>&1; then
    chcon -t httpd_sys_content_t "$LICENSE_DIR" "$STATE_FILE" || true
  fi
fi

ok "Permisos y contexto SELinux del estado de licencia corregidos."

echo
echo "Estado de archivos:"
ls -ldZ "$LICENSE_DIR" || true
ls -lZ "$STATE_FILE" || true
[[ ! -f "$CLIENT_FILE" ]] || ls -lZ "$CLIENT_FILE" || true

echo
echo "Verificando licencia contra Cybermatica..."
php "$TARGET_DIR/bin/license_check.php" || die "La verificación de licencia sigue fallando."

systemctl restart php-fpm 2>/dev/null || true
systemctl restart httpd 2>/dev/null || true
systemctl restart cybermatica-license-check.timer 2>/dev/null || true

ok "Licencia reparada y servicios reiniciados."
echo "Pruebe nuevamente: http://IP_DEL_ISSABEL/$(basename "$TARGET_DIR")/"
