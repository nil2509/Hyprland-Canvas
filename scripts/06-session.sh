#!/usr/bin/env bash

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 06-session.sh
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Verifying Hyprland UWSM session..."

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
# Verify distro-provided Hyprland session
# ------------------------------------------------------------

if [[ ! -f "$HYPRLAND_SESSION" ]]; then
    die "Hyprland session entry was not found: $HYPRLAND_SESSION"
fi

log "Found Hyprland session:"
log "  $HYPRLAND_SESSION"

# ------------------------------------------------------------
# Verify distro-provided UWSM session [CHECK NOT ASSUME]
# ------------------------------------------------------------

if [[ ! -f "$UWSM_SESSION" ]]; then
    log "[warn] UWSM Hyprland session entry was not found: $UWSM_SESSION"
fi

log "Found UWSM Hyprland session:"
log "  $UWSM_SESSION"

# ------------------------------------------------------------
# Verify UWSM session contents
# ------------------------------------------------------------

if ! grep -qE '^Exec=uwsm[[:space:]]+start[[:space:]]+.*hyprland\.desktop' \
    "$UWSM_SESSION"; then
    die "UWSM session entry does not launch Hyprland through UWSM."
fi

if ! grep -q '^TryExec=uwsm$' "$UWSM_SESSION"; then
    die "UWSM session entry is missing TryExec=uwsm."
fi

if ! grep -q '^Type=Application$' "$UWSM_SESSION"; then
    die "UWSM session entry is missing Type=Application."
fi

log "Verified UWSM session entry."

# ------------------------------------------------------------
# Verify the Hyprland session is not bypassing UWSM
# ------------------------------------------------------------

if grep -qE '^Exec=uwsm[[:space:]]+start' "$HYPRLAND_SESSION"; then
    log "Hyprland session itself is UWSM-managed."
else
    log "Hyprland direct session is present separately from UWSM."
fi

# ------------------------------------------------------------
# Verify SDDM is available
# ------------------------------------------------------------

if sudo systemctl is-enabled --quiet sddm.service; then
    log "SDDM is enabled."
else
    die "SDDM is not enabled."
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log "Hyprland UWSM session is ready."
log ""
log "SDDM session to select:"
log "  Hyprland (uwsm-managed)"
log ""
log "Hyprland UWSM session verification complete."

exit 0