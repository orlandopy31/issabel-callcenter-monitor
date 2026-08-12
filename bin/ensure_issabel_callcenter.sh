#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

REPO="${CC_CALLCENTER_REPO:-https://github.com/ISSABELPBX/callcenter-issabel5.git}"
REF="${CC_CALLCENTER_GIT_REF:-82843e063722274276e787c795d8ae20740bd569}"
WORK_ROOT="${CC_CALLCENTER_WORK_ROOT:-/usr/src}"
WORK_DIR="${WORK_ROOT}/callcenter-issabel5-ccpanel"
LOG="${CC_CALLCENTER_INSTALL_LOG:-/var/log/callcenter-panel-callcenter-install.log}"

log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"; }
die(){ log "ERROR: $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Ejecute como root."
[[ -f /etc/rocky-release ]] || die "Este instalador automático está destinado a Issabel 5 sobre Rocky Linux 8."
command -v asterisk >/dev/null 2>&1 || die "No se encontró Asterisk."
asterisk -rx "core show version" >/dev/null 2>&1 || die "Asterisk no está respondiendo."

if ! command -v git >/dev/null 2>&1; then
  log "Instalando git..."
  if command -v dnf >/dev/null 2>&1; then dnf -y install git 2>&1 | tee -a "$LOG"
  elif command -v yum >/dev/null 2>&1; then yum -y install git 2>&1 | tee -a "$LOG"
  else die "No existe dnf/yum."; fi
fi

mkdir -p "$WORK_ROOT"
rm -rf "$WORK_DIR"
log "Clonando $REPO"
git clone "$REPO" "$WORK_DIR" 2>&1 | tee -a "$LOG" || die "No se pudo clonar el repositorio. Revise conectividad/DNS."

if [[ -n "$REF" && "$REF" != "master" ]]; then
  log "Fijando revisión $REF"
  git -C "$WORK_DIR" checkout --detach "$REF" 2>&1 | tee -a "$LOG" \
    || { git -C "$WORK_DIR" fetch origin "$REF" 2>&1 | tee -a "$LOG" && git -C "$WORK_DIR" checkout --detach FETCH_HEAD 2>&1 | tee -a "$LOG"; } \
    || die "No se pudo seleccionar la revisión $REF"
fi

INSTALLER="$WORK_DIR/build/5.0/install-issabel-callcenter.sh"
[[ -f "$INSTALLER" ]] || die "No existe el instalador esperado: $INSTALLER"
chmod +x "$INSTALLER"

log "Ejecutando instalador oficial de Issabel Call Center en modo local"
(
  cd "$WORK_DIR"
  bash "$INSTALLER" -l
) 2>&1 | tee -a "$LOG"

# El script upstream puede continuar aunque una orden interna falle; estas
# comprobaciones son deliberadamente independientes.
[[ -d /var/www/html/modules/agent_console ]] || die "No apareció el módulo web agent_console."
[[ -f /etc/systemd/system/issabeldialer.service || -f /usr/lib/systemd/system/issabeldialer.service ]] || die "No apareció issabeldialer.service."

systemctl daemon-reload || true
systemctl enable issabeldialer 2>&1 | tee -a "$LOG" || true
if ! systemctl is-active --quiet issabeldialer; then
  systemctl restart issabeldialer 2>&1 | tee -a "$LOG" || true
fi
systemctl is-active --quiet issabeldialer || die "issabeldialer no quedó activo."

asterisk -rx "core reload" >/dev/null 2>&1 || true
log "Dependencia Issabel Call Center instalada."
