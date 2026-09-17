#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Creating installation recovery snapshot..."

# ------------------------------------------------------------
# Snapper availability
# ------------------------------------------------------------

if ! command -v snapper >/dev/null 2>&1; then
    log "[info] Snapper is not installed."
    log "[info] Skipping installation recovery snapshot."
    exit 0
fi

log "[ok] Snapper is installed."

# ------------------------------------------------------------
# Root configuration
# ------------------------------------------------------------

if ! sudo snapper list-configs 2>/dev/null \
    | awk '$1 == "root" { found=1 } END { exit !found }'; then

    log "[info] No usable 'root' Snapper configuration was found."
    log "[info] Skipping installation recovery snapshot."
    exit 0
fi

log "[ok] Snapper 'root' configuration is available."

# ------------------------------------------------------------
# Create snapshot
# ------------------------------------------------------------

log "Creating Snapper snapshot for Hyprland-Canvas installation..."

SNAPSHOT_ID="$(
    sudo snapper -c root create \
        --description "Hyprland-Canvas installation" \
        --print-number
)"

if [[ -z "$SNAPSHOT_ID" ]]; then
    die "Failed to create installation snapshot."
fi

# ------------------------------------------------------------
# Verify snapshot
# ------------------------------------------------------------

if sudo snapper -c root list \
    | awk -v id="$SNAPSHOT_ID" '$1 == id { found=1 } END { exit !found }'; then

    log "[ok] Installation recovery snapshot verified."
else
    die "Snapper reported snapshot $SNAPSHOT_ID, but it could not be found afterward."
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log "Created recovery snapshot: $SNAPSHOT_ID"
log "Snapshot description: Hyprland-Canvas installation"
log ""
log "Snapshot stage completed successfully."

exit 0