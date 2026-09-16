#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 04-session.sh
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/00-preflight.sh"

log "Configuring Hyprland session..."

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

command -v uwsm >/dev/null 2>&1 \
    || die "uwsm is not installed."

command -v Hyprland >/dev/null 2>&1 \
    || die "Hyprland is not installed."

command -v sddm >/dev/null 2>&1 \
    || die "SDDM is not installed."

# ------------------------------------------------------------
# Wayland session files
# ------------------------------------------------------------

WAYLAND_SESSION_DIR="/usr/share/wayland-sessions"

HYPRLAND_SESSION="$WAYLAND_SESSION_DIR/hyprland.desktop"
UWSM_SESSION="$WAYLAND_SESSION_DIR/hyprland-uwsm.desktop"

# ------------------------------------------------------------
# Verify the distro-provided Hyprland session
# ------------------------------------------------------------

if [[ ! -f "$HYPRLAND_SESSION" ]]; then
    die "Hyprland session entry was not found: $HYPRLAND_SESSION"
fi

log "Found Hyprland session:"
log "  $HYPRLAND_SESSION"

# ------------------------------------------------------------
# Create UWSM session entry
# ------------------------------------------------------------

if [[ -f "$UWSM_SESSION" ]]; then
    log "Found existing UWSM Hyprland session:"
    log "  $UWSM_SESSION"
else
    log "UWSM Hyprland session entry not found."
    log "Creating:"
    log "  $UWSM_SESSION"

    sudo tee "$UWSM_SESSION" >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland (UWSM)
Comment=Hyprland compositor managed by UWSM
Exec=uwsm start -- hyprland.desktop
TryExec=uwsm
Type=Application
DesktopNames=Hyprland
EOF

    log "UWSM Hyprland session entry created."
fi

# ------------------------------------------------------------
# Verify UWSM session entry
# ------------------------------------------------------------

if [[ ! -f "$UWSM_SESSION" ]]; then
    die "Failed to create UWSM Hyprland session entry: $UWSM_SESSION"
fi

if ! sudo grep -q '^Exec=uwsm start -- hyprland\.desktop$' "$UWSM_SESSION"; then
    die "UWSM session entry has an unexpected Exec line."
fi

if ! sudo grep -q '^TryExec=uwsm$' "$UWSM_SESSION"; then
    die "UWSM session entry is missing TryExec=uwsm."
fi

log "Verified UWSM session entry."

# ------------------------------------------------------------
# Enable SDDM
# ------------------------------------------------------------

log "Enabling SDDM..."

sudo systemctl enable sddm.service

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log "Hyprland UWSM session is ready."
log "Session entry:"
log "  $UWSM_SESSION"

log "SDDM is enabled."
log "At login, select:"
log "  Hyprland (UWSM)"

log "Hyprland session configuration complete."

exit 0