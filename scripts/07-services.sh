#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log "Configuring system services..."

# System services

SYSTEM_SERVICES=(
NetworkManager.service
bluetooth.service
power-profiles-daemon.service
)

for service in "${SYSTEM_SERVICES[@]}"; do
log "Enabling $service..."
if sudo systemctl enable --now "$service"; then
log "[ok] $service"
else
log "[warn] Could not enable/start $service"
fi
done

# User audio services

USER_AUDIO_SERVICES=(
pipewire.service
pipewire-pulse.service
wireplumber.service
)

for service in "${USER_AUDIO_SERVICES[@]}"; do
log "Enabling user service $service..."
if systemctl --user enable --now "$service"; then
log "[ok] $service"
else
log "[warn] Could not enable/start $service"
fi
done

# Hyprpolkitagent is installed as an extra package.

# DMS/Hyprland owns the graphical session, so don't create another

# session-management layer here.

if systemctl --user list-unit-files hyprpolkitagent.service >/dev/null 2>&1; then
log "Enabling hyprpolkitagent..."
if systemctl --user enable --now hyprpolkitagent.service; then
log "[ok] hyprpolkitagent"
else
log "[warn] Could not enable/start hyprpolkitagent"
fi
else
log "[info] hyprpolkitagent.service not available; skipping."
fi

log "System services configured."
exit 0