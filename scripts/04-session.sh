#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-preflight.sh"

log "Configuring Hyprland session..."

command -v uwsm >/dev/null 2>&1 || die "uwsm is not installed."
command -v Hyprland >/dev/null 2>&1 || die "Hyprland is not installed."
command -v sddm >/dev/null 2>&1 || die "SDDM is not installed."

WAYLAND_SESSION_DIR="/usr/share/wayland-sessions"
UWSM_SESSION="$WAYLAND_SESSION_DIR/hyprland-uwsm.desktop"

if [[ -f "$UWSM_SESSION" ]]; then
    log "Found UWSM Hyprland session:"
    log "  $UWSM_SESSION"
else
    die "UWSM Hyprland session entry was not found: $UWSM_SESSION"
fi

log "Enabling SDDM..."
sudo systemctl enable sddm.service

log "Hyprland UWSM session entry is ready."
log "SDDM will provide the Hyprland (UWSM) session at login."

exit 0