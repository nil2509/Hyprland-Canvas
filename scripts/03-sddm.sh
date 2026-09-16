#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-preflight.sh"

log "Configuring SDDM..."

command -v sddm >/dev/null 2>&1 || die "SDDM is not installed."
command -v systemctl >/dev/null 2>&1 || die "systemctl is not available."

SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="$SDDM_CONF_DIR/10-hyprland.conf"

log "Creating SDDM configuration directory..."

sudo mkdir -p "$SDDM_CONF_DIR"

log "Writing Hyprland SDDM configuration..."

sudo tee "$SDDM_CONF" >/dev/null <<'EOF'
[General]
DisplayServer=wayland
EOF

log "Enabling SDDM..."

sudo systemctl enable sddm.service

log "Checking available Wayland sessions..."

UWSM_SESSION="/usr/share/wayland-sessions/hyprland-uwsm.desktop"

if [[ -f "$UWSM_SESSION" ]]; then
    log "Found Hyprland UWSM session:"
    log "  $UWSM_SESSION"
else
    die "Hyprland UWSM session was not found: $UWSM_SESSION"
fi

log "Verifying SDDM configuration..."

if sudo grep -q '^DisplayServer=wayland$' "$SDDM_CONF"; then
    log "SDDM greeter is configured for Wayland."
else
    die "Failed to configure SDDM Wayland display server."
fi

log "SDDM configuration complete."

exit 0