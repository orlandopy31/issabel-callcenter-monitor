#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${CC_MONITOR_REPO:-orlandopy31/issabel-callcenter-monitor}"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
WORK_DIR="${CC_LATEST_WORK_DIR:-/tmp/issabel-callcenter-monitor-latest}"
TARGET_DIR="${CC_TARGET_DIR:-/var/www/html/callcenter-panel}"
REPAIR_URL="https://raw.githubusercontent.com/${REPO}/main/REPARAR_403.sh"

say(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok(){ printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Ejecute como root: sudo bash $0"

install_pkg(){
  local pkg="$1"
  if command -v dnf >/dev/null 2>&1; then dnf -y install "$pkg"
  elif command -v yum >/dev/null 2>&1; then yum -y install "$pkg"
  else die "Falta $pkg y no se encontró dnf/yum para instalarlo."; fi
}

command -v curl >/dev/null 2>&1 || install_pkg curl
command -v unzip >/dev/null 2>&1 || install_pkg unzip
command -v find >/dev/null 2>&1 || die "Falta el comando find."

say "Consultando la última Release estable en GitHub"
LATEST_JSON="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$API_URL")" \
  || die "No se pudo consultar la última Release de ${REPO}."

TAG="$(printf '%s\n' "$LATEST_JSON" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
ZIP_URL="$(printf '%s\n' "$LATEST_JSON" | grep -oE '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]+\.zip"' | head -n1 | sed -E 's/^.*"(https:[^"]+\.zip)"$/\1/')"

[[ -n "$TAG" ]] || die "GitHub no devolvió el tag de la última Release."
[[ -n "$ZIP_URL" ]] || die "La Release ${TAG} no contiene un ZIP instalable."

ZIP_FILE="/tmp/$(basename "$ZIP_URL")"
printf 'Última versión estable: %s\n' "$TAG"
printf 'Paquete: %s\n' "$(basename "$ZIP_URL")"

say "Descargando ${TAG}"
curl -fL "$ZIP_URL" -o "$ZIP_FILE" || die "No se pudo descargar $ZIP_URL"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
unzip -q "$ZIP_FILE" -d "$WORK_DIR" || die "No se pudo descomprimir $ZIP_FILE"

INSTALL_SH="$(find "$WORK_DIR" -type f -name install.sh -print -quit)"
[[ -n "$INSTALL_SH" ]] || die "El paquete ${TAG} no contiene install.sh."

say "Ejecutando instalador de ${TAG}"
cd "$(dirname "$INSTALL_SH")"
bash ./install.sh

# Aplica siempre la versión más reciente del reparador de permisos publicada en
# main. Esto protege incluso instalaciones hechas con una Release anterior.
if [[ -d "$TARGET_DIR" ]]; then
  say "Normalizando permisos web y Apache"
  REPAIR_FILE="/tmp/callcenter-panel-reparar-403.sh"
  curl -fsSL "$REPAIR_URL" -o "$REPAIR_FILE" || die "No se pudo descargar el reparador de permisos."
  chmod +x "$REPAIR_FILE"
  bash "$REPAIR_FILE" "$TARGET_DIR"
  ok "Permisos web verificados."
else
  printf '\033[1;33m[AVISO]\033[0m No se encontró %s para ejecutar la reparación automática.\n' "$TARGET_DIR"
  printf 'Si eligió otro directorio durante la instalación, ejecute REPARAR_403.sh indicando esa ruta.\n'
fi
