#!/usr/bin/env bash
set -Eeuo pipefail
TARGET_DIR="${1:-/var/www/html/callcenter-panel}"

[[ $EUID -eq 0 ]] || { echo "Ejecute como root: sudo bash $0 [directorio]" >&2; exit 1; }
[[ -d "$TARGET_DIR" ]] || { echo "No existe: $TARGET_DIR" >&2; exit 1; }

if id apache >/dev/null 2>&1; then WEB_USER=apache; WEB_GROUP=apache
elif id www-data >/dev/null 2>&1; then WEB_USER=www-data; WEB_GROUP=www-data
else echo "No se encontró usuario apache/www-data" >&2; exit 1; fi

echo "[1/5] Corrigiendo propietario y permisos..."
chown -R root:"$WEB_GROUP" "$TARGET_DIR"
find "$TARGET_DIR" -type d -exec chmod 0750 {} \;
find "$TARGET_DIR" -type f -exec chmod 0640 {} \;
if [[ -d "$TARGET_DIR/cache" ]]; then
  chown -R "$WEB_USER":"$WEB_GROUP" "$TARGET_DIR/cache"
  chmod 0770 "$TARGET_DIR/cache"
  find "$TARGET_DIR/cache" -type f -exec chmod 0660 {} \;
fi

echo "[2/5] Asegurando DirectoryIndex index.php..."
HT="$TARGET_DIR/.htaccess"
if [[ -f "$HT" ]] && ! grep -Eq '^[[:space:]]*DirectoryIndex[[:space:]]+.*index\.php' "$HT"; then
  { echo 'DirectoryIndex index.php'; echo; cat "$HT"; } > "$HT.tmp"
  mv "$HT.tmp" "$HT"
  chown root:"$WEB_GROUP" "$HT"
  chmod 0640 "$HT"
fi

echo "[3/5] Corrigiendo contexto SELinux..."
if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null)" != "Disabled" ]]; then
  if command -v semanage >/dev/null 2>&1; then
    semanage fcontext -a -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null \
      || semanage fcontext -m -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null || true
    if [[ -d "$TARGET_DIR/cache" ]]; then
      semanage fcontext -a -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null \
        || semanage fcontext -m -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null || true
    fi
    restorecon -Rv "$TARGET_DIR"
  elif command -v chcon >/dev/null 2>&1; then
    chcon -R -t httpd_sys_content_t "$TARGET_DIR"
    [[ -d "$TARGET_DIR/cache" ]] && chcon -R -t httpd_sys_rw_content_t "$TARGET_DIR/cache"
  fi
fi

echo "[4/5] Validando Apache..."
if command -v apachectl >/dev/null 2>&1; then apachectl -t
elif command -v httpd >/dev/null 2>&1; then httpd -t
fi

echo "[5/5] Reiniciando servicios..."
systemctl restart httpd
systemctl restart php-fpm 2>/dev/null || true

echo
echo "Reparación terminada. Pruebe: http://IP_DEL_SERVIDOR/$(basename "$TARGET_DIR")/"
echo "Si persiste el 403:"
echo "  ls -ldZ /var/www /var/www/html '$TARGET_DIR' '$TARGET_DIR/index.php'"
echo "  tail -n 80 /var/log/httpd/error_log"
