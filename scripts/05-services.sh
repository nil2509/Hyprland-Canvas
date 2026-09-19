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
# Summary
# ------------------------------------------------------------

log "System and user services configured successfully."

exit 0