#!/usr/bin/env bash
set -Eeuo pipefail
TARGET_DIR="${1:-/var/www/html/callcenter-panel}"

[[ $EUID -eq 0 ]] || { echo "Ejecute como root: sudo bash $0 [directorio]" >&2; exit 1; }
[[ -d "$TARGET_DIR" ]] || { echo "No existe: $TARGET_DIR" >&2; exit 1; }

if id apache >/dev/null 2>&1; then WEB_USER=apache; WEB_GROUP=apache
elif id www-data >/dev/null 2>&1; then WEB_USER=www-data; WEB_GROUP=www-data
else echo "No se encontró usuario apache/www-data" >&2; exit 1; fi

ok(){ printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

echo "[1/6] Corrigiendo permisos del DocumentRoot..."
chown -R root:"$WEB_GROUP" "$TARGET_DIR"
find "$TARGET_DIR" -type d -exec chmod 0755 {} \;
find "$TARGET_DIR" -type f -exec chmod 0644 {} \;
[[ -d /var/www ]] && chmod 0755 /var/www || true
[[ -d /var/www/html ]] && chmod 0755 /var/www/html || true
PARENT_DIR="$(dirname "$TARGET_DIR")"
[[ -d "$PARENT_DIR" ]] && chmod a+x "$PARENT_DIR" || true

if [[ -f "$TARGET_DIR/config.php" ]]; then
  chown root:"$WEB_GROUP" "$TARGET_DIR/config.php"
  chmod 0640 "$TARGET_DIR/config.php"
fi
if [[ -f "$TARGET_DIR/.htaccess" ]]; then
  chown root:"$WEB_GROUP" "$TARGET_DIR/.htaccess"
  chmod 0644 "$TARGET_DIR/.htaccess"
fi
if [[ -d "$TARGET_DIR/cache" ]]; then
  chown -R "$WEB_USER":"$WEB_GROUP" "$TARGET_DIR/cache"
  find "$TARGET_DIR/cache" -type d -exec chmod 0770 {} \;
  find "$TARGET_DIR/cache" -type f -exec chmod 0660 {} \;
fi
ok "Permisos Unix corregidos."

echo "[2/6] Instalando regla explícita de Apache..."
if [[ -d /etc/httpd/conf.d ]]; then
  APACHE_PANEL_CONF="/etc/httpd/conf.d/callcenter-panel.conf"
  cat > "$APACHE_PANEL_CONF" <<APACHEEOF
<Directory "${TARGET_DIR}">
    Options -Indexes
    AllowOverride None
    Require all granted
    DirectoryIndex index.php

    <Files "config.php">
        Require all denied
    </Files>

    <FilesMatch "\.(sql|md|log|bak|zip)$">
        Require all denied
    </FilesMatch>

    <IfModule mod_headers.c>
        Header always set X-Frame-Options "SAMEORIGIN"
        Header always set X-Content-Type-Options "nosniff"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
    </IfModule>
</Directory>
APACHEEOF
  chown root:root "$APACHE_PANEL_CONF"
  chmod 0644 "$APACHE_PANEL_CONF"
  restorecon "$APACHE_PANEL_CONF" 2>/dev/null || true
  ok "Apache ya no depende de .htaccess para autorizar el panel."
fi

echo "[3/6] Corrigiendo SELinux..."
if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null)" != "Disabled" ]]; then
  if ! command -v semanage >/dev/null 2>&1 && command -v dnf >/dev/null 2>&1; then
    dnf -y install policycoreutils-python-utils >/dev/null 2>&1 || warn "No se pudo instalar policycoreutils-python-utils."
  fi
  if command -v setsebool >/dev/null 2>&1; then
    setsebool -P httpd_can_network_connect 1 >/dev/null 2>&1 || true
  fi
  if command -v semanage >/dev/null 2>&1; then
    semanage fcontext -a -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null \
      || semanage fcontext -m -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null || true
    if [[ -d "$TARGET_DIR/cache" ]]; then
      semanage fcontext -a -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null \
        || semanage fcontext -m -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null || true
    fi
    restorecon -Rv "$TARGET_DIR" >/dev/null 2>&1 || true
  elif command -v chcon >/dev/null 2>&1; then
    chcon -R -t httpd_sys_content_t "$TARGET_DIR" || true
    [[ -d "$TARGET_DIR/cache" ]] && chcon -R -t httpd_sys_rw_content_t "$TARGET_DIR/cache" || true
  fi
fi
ok "SELinux revisado."

echo "[4/6] Comprobando lectura real como ${WEB_USER}..."
if command -v runuser >/dev/null 2>&1; then
  runuser -u "$WEB_USER" -- test -x "$TARGET_DIR" || die "$WEB_USER no puede atravesar $TARGET_DIR"
  runuser -u "$WEB_USER" -- test -r "$TARGET_DIR/index.php" || die "$WEB_USER no puede leer index.php"
  [[ ! -f "$TARGET_DIR/.htaccess" ]] || runuser -u "$WEB_USER" -- test -r "$TARGET_DIR/.htaccess" || die "$WEB_USER no puede leer .htaccess"
  [[ ! -f "$TARGET_DIR/config.php" ]] || runuser -u "$WEB_USER" -- test -r "$TARGET_DIR/config.php" || die "$WEB_USER no puede leer config.php"
fi
ok "Apache puede leer los archivos necesarios."

echo "[5/6] Validando configuración Apache..."
if command -v apachectl >/dev/null 2>&1; then apachectl -t
elif command -v httpd >/dev/null 2>&1; then httpd -t
fi

echo "[6/6] Reiniciando servicios..."
systemctl restart httpd
systemctl restart php-fpm 2>/dev/null || true
ok "Servicios reiniciados."

echo
echo "Reparación terminada. Pruebe:"
echo "  http://IP_DEL_SERVIDOR/$(basename "$TARGET_DIR")/"
echo
echo "Si todavía aparece 403, ejecute y comparta:"
echo "  namei -l '$TARGET_DIR/.htaccess'"
echo "  ls -ldZ /var /var/www /var/www/html '$TARGET_DIR'"
echo "  ls -lZ '$TARGET_DIR/.htaccess' '$TARGET_DIR/index.php' '$TARGET_DIR/config.php'"
echo "  apachectl -t -D DUMP_RUN_CFG | head -80"
echo "  tail -n 100 /var/log/httpd/error_log"
