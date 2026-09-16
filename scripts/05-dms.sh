#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-preflight.sh"

log "Configuring DankMaterialShell..."

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

command -v dms >/dev/null 2>&1 \
    || die "dms is not installed."

command -v quickshell >/dev/null 2>&1 \
    || die "quickshell is not installed."

command -v kitty >/dev/null 2>&1 \
    || die "kitty is not installed."

# ------------------------------------------------------------
# User environment
# ------------------------------------------------------------

log "Configuring user environment..."

mkdir -p "$HOME/.config/environment.d"

cat > "$HOME/.config/environment.d/90-dms.conf" <<'EOF'
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=gtk3
ELECTRON_OZONE_PLATFORM_HINT=auto
TERMINAL=kitty
EOF

# ------------------------------------------------------------
# DMS setup
# ------------------------------------------------------------

log "Running DMS headless setup..."

dms setup headless \
    --compositor hyprland \
    --terminal kitty \
    --skip-existing

# ------------------------------------------------------------
# Verify DMS configuration
# ------------------------------------------------------------

DMS_HYPR_DIR="$HOME/.config/hypr/dms"

if [[ -d "$DMS_HYPR_DIR" ]]; then
    log "DMS Hyprland configuration directory exists:"
    log "  $DMS_HYPR_DIR"
else
    die "DMS Hyprland configuration directory was not created: $DMS_HYPR_DIR"
fi

# ------------------------------------------------------------
# Systemd session note
# ------------------------------------------------------------

log "Hyprland/UWSM systemd integration is handled by the"
log "Hyprland UWSM session and graphical-session.target."

log "DankMaterialShell configuration complete."

exit 0