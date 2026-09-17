#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring SDDM..."

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

command -v sddm >/dev/null 2>&1 \
    || die "SDDM is not installed."

command -v systemctl >/dev/null 2>&1 \
    || die "systemctl is not available."

# ------------------------------------------------------------
# SDDM configuration
# ------------------------------------------------------------

SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="$SDDM_CONF_DIR/10-hyprland.conf"

log "Creating SDDM configuration directory..."

sudo mkdir -p "$SDDM_CONF_DIR"

log "Writing SDDM Wayland configuration..."

sudo tee "$SDDM_CONF" >/dev/null <<'EOF'
[General]
DisplayServer=wayland
EOF

# ------------------------------------------------------------
# Enable SDDM
# ------------------------------------------------------------

log "Enabling SDDM as the display manager..."

sudo systemctl enable --force sddm.service

# ------------------------------------------------------------
# Default boot target
# ------------------------------------------------------------

log "Setting graphical.target as the default boot target..."

sudo systemctl set-default graphical.target

# ------------------------------------------------------------
# Verify configuration
# ------------------------------------------------------------

log "Verifying SDDM configuration..."

if sudo grep -q '^DisplayServer=wayland$' "$SDDM_CONF"; then
    log "[ok] SDDM greeter is configured to use Wayland."
else
    die "Failed to configure SDDM Wayland display server."
fi

# ------------------------------------------------------------
# Verify enablement
# ------------------------------------------------------------

log "Verifying SDDM enablement..."

if sudo systemctl is-enabled --quiet sddm.service; then
    log "[ok] SDDM is enabled."
else
    die "SDDM is not enabled."
fi

# ------------------------------------------------------------
# Verify default target
# ------------------------------------------------------------

log "Verifying default boot target..."

DEFAULT_TARGET="$(systemctl get-default)"

if [[ "$DEFAULT_TARGET" == "graphical.target" ]]; then
    log "[ok] Default boot target is graphical.target."
else
    die "Unexpected default boot target: $DEFAULT_TARGET"
fi

# ------------------------------------------------------------
# Verify Hyprland UWSM session
#
# Hyprland provides the UWSM-managed session entry.
# 06-session.sh performs the detailed verification.
# ------------------------------------------------------------

UWSM_SESSION="/usr/share/wayland-sessions/hyprland-uwsm.desktop"

if [[ -f "$UWSM_SESSION" ]]; then
    log "[ok] UWSM-managed Hyprland session entry exists."
else
    log "[info] UWSM-managed Hyprland session entry is not present yet."
    log "       06-session.sh will perform the definitive session check."
fi

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

log "SDDM configuration complete."

exit 0