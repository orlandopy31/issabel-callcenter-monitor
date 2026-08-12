#!/usr/bin/env bash
set -Eeuo pipefail

# Bootstrapper de instalación desde main.
# Instala siempre la última Release estable y aplica las correcciones publicadas
# en main (incluidos permisos Apache/SELinux).
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LATEST_LOCAL="$SOURCE_DIR/install-latest.sh"
LATEST_URL="https://raw.githubusercontent.com/orlandopy31/issabel-callcenter-monitor/main/install-latest.sh"

[[ $EUID -eq 0 ]] || { echo "[ERROR] Ejecute como root: sudo bash install.sh" >&2; exit 1; }

if [[ -f "$LATEST_LOCAL" ]]; then
  exec bash "$LATEST_LOCAL"
fi

if ! command -v curl >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1; then dnf -y install curl
  elif command -v yum >/dev/null 2>&1; then yum -y install curl
  else echo "[ERROR] Falta curl y no se encontró dnf/yum." >&2; exit 1; fi
fi

TMP_INSTALLER="/tmp/issabel-callcenter-monitor-install-latest.sh"
curl -fsSL "$LATEST_URL" -o "$TMP_INSTALLER" || {
  echo "[ERROR] No se pudo descargar install-latest.sh" >&2
  exit 1
}
chmod +x "$TMP_INSTALLER"
exec bash "$TMP_INSTALLER"
