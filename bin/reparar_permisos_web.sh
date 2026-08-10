#!/usr/bin/env bash
set -Eeuo pipefail
TARGET_DIR="${1:-/var/www/html/callcenter-panel}"

[[ $EUID -eq 0 ]] || { echo "Ejecute como root: sudo bash $0 [directorio]" >&2; exit 1; }
[[ -d "$TARGET_DIR" ]] || { echo "No existe: $TARGET_DIR" >&2; exit 1; }

if id apache >/dev/null 2>&1; then WEB_USER=apache; WEB_GROUP=apache
elif id www-data >/dev/null 2>&1; then WEB_USER=www-data; WEB_GROUP=www-data
else echo "No se encontró usuario apache/www-data" >&2; exit 1; fi

chown -R root:"$WEB_GROUP" "$TARGET_DIR"
find "$TARGET_DIR" -type d -exec chmod 0750 {} \;
find "$TARGET_DIR" -type f -exec chmod 0640 {} \;
if [[ -d "$TARGET_DIR/cache" ]]; then
  chown -R "$WEB_USER":"$WEB_GROUP" "$TARGET_DIR/cache"
  chmod 0770 "$TARGET_DIR/cache"
  find "$TARGET_DIR/cache" -type f -exec chmod 0660 {} \;
fi

HT="$TARGET_DIR/.htaccess"
if [[ ! -f "$HT" ]]; then
  printf 'DirectoryIndex index.php\nOptions -Indexes\n' > "$HT"
elif ! grep -Eq '^[[:space:]]*DirectoryIndex[[:space:]]+.*index\.php' "$HT"; then
  { echo 'DirectoryIndex index.php'; echo; cat "$HT"; } > "$HT.tmp"
  mv "$HT.tmp" "$HT"
fi
chown root:"$WEB_GROUP" "$HT"
chmod 0640 "$HT"

if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null)" != "Disabled" ]]; then
  if command -v semanage >/dev/null 2>&1; then
    semanage fcontext -a -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null \
      || semanage fcontext -m -t httpd_sys_content_t "${TARGET_DIR}(/.*)?" 2>/dev/null || true
    [[ -d "$TARGET_DIR/cache" ]] && {
      semanage fcontext -a -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null \
        || semanage fcontext -m -t httpd_sys_rw_content_t "${TARGET_DIR}/cache(/.*)?" 2>/dev/null || true
    }
    restorecon -Rv "$TARGET_DIR"
  elif command -v chcon >/dev/null 2>&1; then
    chcon -R -t httpd_sys_content_t "$TARGET_DIR"
    [[ -d "$TARGET_DIR/cache" ]] && chcon -R -t httpd_sys_rw_content_t "$TARGET_DIR/cache"
  fi
fi

if [[ -d /etc/httpd/conf.d ]]; then
  cat > /etc/httpd/conf.d/callcenter-panel.conf <<EOF
<Directory "${TARGET_DIR}">
    Options -Indexes
    AllowOverride All
    Require all granted
    DirectoryIndex index.php
</Directory>
EOF
  chmod 0644 /etc/httpd/conf.d/callcenter-panel.conf
  restorecon /etc/httpd/conf.d/callcenter-panel.conf 2>/dev/null || true
fi

if command -v apachectl >/dev/null 2>&1; then apachectl -t
elif command -v httpd >/dev/null 2>&1; then httpd -t
fi
systemctl restart httpd
systemctl restart php-fpm 2>/dev/null || true

echo "Permisos web reparados: $TARGET_DIR"
