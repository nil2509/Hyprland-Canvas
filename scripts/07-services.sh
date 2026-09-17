#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring system and user services..."

# ------------------------------------------------------------
# Required system services
# ------------------------------------------------------------

SYSTEM_SERVICES=(
    NetworkManager.service
    bluetooth.service
    power-profiles-daemon.service
)

for service in "${SYSTEM_SERVICES[@]}"; do
    log "Enabling and starting $service..."

    sudo systemctl enable --now "$service"

    if sudo systemctl is-enabled --quiet "$service"; then
        log "[ok] $service is enabled."
    else
        die "$service could not be enabled."
    fi

    if sudo systemctl is-active --quiet "$service"; then
        log "[ok] $service is active."
    else
        die "$service is not active."
    fi
done

# ------------------------------------------------------------
# Required user services
# ------------------------------------------------------------

USER_SERVICES=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
    hyprpolkitagent.service
    dms.service
)

for service in "${USER_SERVICES[@]}"; do
    log "Enabling and starting user service: $service..."

    systemctl --user enable "$service"

    if systemctl --user is-enabled --quiet "$service"; then
        log "[ok] $service is enabled."
    else
        die "User service could not be enabled: $service"
    fi

    if systemctl --user is-active --quiet "$service"; then
        log "[ok] $service is active."
    else
        log "[warn] User service is not active: $service"
    fi
done

# ------------------------------------------------------------
# DankMaterialShell
# ------------------------------------------------------------

log "Configuring DankMaterialShell systemd service..."

if ! systemctl --user cat dms.service >/dev/null 2>&1; then
    die "DMS systemd user service is not available."
fi

# ------------------------------------------------------------
# Verify DMS session integration
# ------------------------------------------------------------

DMS_WANTS_DIR="$HOME/.config/systemd/user/graphical-session.target.wants"
DMS_WANTS_LINK="$DMS_WANTS_DIR/dms.service"

if [[ -L "$DMS_WANTS_LINK" ]]; then
    log "[ok] dms.service is attached to graphical-session.target."
else
    die "dms.service is not attached to graphical-session.target."
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log "System and user services configured successfully."
log ""
log "DMS will start with the UWSM-managed graphical session."
log "It is intentionally not started immediately by this stage."

exit 0