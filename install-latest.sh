#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${CC_MONITOR_REPO:-orlandopy31/issabel-callcenter-monitor}"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
WORK_DIR="${CC_LATEST_WORK_DIR:-/tmp/issabel-callcenter-monitor-latest}"

say(){ printf '\n==> %s\n' "$*"; }
die(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Ejecute como root: sudo bash $0"
for cmd in curl unzip grep sed basename dirname find; do
  command -v "$cmd" >/dev/null 2>&1 || die "Falta el comando requerido: $cmd"
done

say "Consultando la última versión publicada en GitHub"
LATEST_JSON="$(curl -fsSL -H 'Accept: application/vnd.github+json' "$API_URL")" \
  || die "No se pudo consultar la última Release de ${REPO}."

TAG="$(printf '%s\n' "$LATEST_JSON" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
ZIP_URL="$(printf '%s\n' "$LATEST_JSON" | grep -oE '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]+\.zip"' | head -n1 | sed -E 's/^.*"(https:[^"]+\.zip)"$/\1/')"

[[ -n "$TAG" ]] || die "GitHub no devolvió el tag de la última Release."
[[ -n "$ZIP_URL" ]] || die "La Release ${TAG} no contiene un archivo ZIP instalable."

ZIP_FILE="/tmp/$(basename "$ZIP_URL")"
printf 'Última versión: %s\n' "$TAG"
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
