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
SDDM_CONF="$SDDM_CONF_DIR/x11.conf"

log "Creating SDDM configuration directory..."

sudo mkdir -p "$SDDM_CONF_DIR"

log "Writing SDDM X11 configuration..."

sudo tee "$SDDM_CONF" >/dev/null <<'EOF'
[General]
DisplayServer=x11
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

if sudo grep -q '^DisplayServer=x11$' "$SDDM_CONF"; then
    log "[ok] SDDM greeter is configured to use X11."
else
    die "Failed to configure SDDM X11 display server."
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
# UWSM Hyprland session
#
# openSUSE's Hyprland package provides hyprland.desktop, but
# does not provide a separate UWSM-managed session entry.
# Create the UWSM session explicitly for SDDM.
# ------------------------------------------------------------

UWSM_SESSION="/usr/share/wayland-sessions/hyprland-uwsm.desktop"

# ------------------------------------------------------------
# Create hyprland-uwsm.desktop if it doesnt exist
# ------------------------------------------------------------

if [[ -f "$UWSM_SESSION" ]]; then
    log "[ok] UWSM-managed Hyprland session entry already exists."
else
    log "Creating UWSM-managed Hyprland session entry..."

    sudo tee "$UWSM_SESSION" >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland (uwsm-managed)
Comment=Hyprland session managed by UWSM
Exec=uwsm start hyprland.desktop
TryExec=uwsm
Type=Application
DesktopNames=Hyprland
EOF
fi

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

log "SDDM configuration complete."

exit 0