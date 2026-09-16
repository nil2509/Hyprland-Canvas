#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Creating installation recovery snapshot..."

if ! command -v snapper >/dev/null 2>&1; then
    log "Snapper is not installed."
    log "Skipping installation snapshot."
    exit 0
fi

if ! sudo snapper list-configs | grep -q '^root[[:space:]]'; then
    log "No usable 'root' Snapper configuration was found."
    log "Skipping installation snapshot."
    exit 0
fi

log "Creating Snapper snapshot for Hyprland-Canvas installation..."

SNAPSHOT_ID="$(
    sudo snapper -c root create \
        --description "Hyprland-Canvas installation" \
        --print-number
)"

if [[ -z "$SNAPSHOT_ID" ]]; then
    die "Failed to create installation snapshot."
fi

log "Created recovery snapshot: $SNAPSHOT_ID"
log "Snapshot description: Hyprland-Canvas installation"

exit 0