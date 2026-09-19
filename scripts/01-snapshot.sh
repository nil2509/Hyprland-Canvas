#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Creating installation recovery snapshot..."

# ------------------------------------------------------------
# Snapshot flag
# ------------------------------------------------------------

NO_SNAPSHOT="${NO_SNAPSHOT:-0}"

if [[ "$NO_SNAPSHOT" == "1" ]]; then
    log "[info] --no-snapshot was specified."
    log "[info] Skipping installation recovery snapshot."
    exit 0
fi

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
# Snapshot state
# ------------------------------------------------------------

SNAPSHOT_STATE="$SCRIPT_DIR/../.installation-snapshot"

if [[ -f "$SNAPSHOT_STATE" ]]; then
    EXISTING_SNAPSHOT_ID="$(<"$SNAPSHOT_STATE")"

    # Ensure the state file contains only a valid numeric snapshot ID.
    if [[ "$EXISTING_SNAPSHOT_ID" =~ ^[0-9]+$ ]]; then

        # Check whether the recorded snapshot still exists.
        if sudo snapper -c root list 2>/dev/null \
            | awk -v id="$EXISTING_SNAPSHOT_ID" \
                '$1 == id { found=1; exit } END { exit !found }'; then

            log "[ok] Existing installation snapshot found: $EXISTING_SNAPSHOT_ID"

            if [[ -r /dev/tty && -w /dev/tty ]]; then
                printf 'Create another installation recovery snapshot? [y/N] ' > /dev/tty
                read -r CREATE_SNAPSHOT < /dev/tty
            else
                log "[info] Non-interactive execution detected."
                log "[info] Keeping existing installation snapshot."
                exit 0
            fi

            if [[ ! "$CREATE_SNAPSHOT" =~ ^[Yy]$ ]]; then
                log "[info] Keeping existing installation snapshot."
                log "[info] Skipping installation recovery snapshot."
                exit 0
            fi

        else
            log "[info] Recorded snapshot $EXISTING_SNAPSHOT_ID no longer exists."
            log "[info] A new installation recovery snapshot will be created."
        fi

    else
        log "[info] Snapshot state file is invalid."
        log "[info] A new installation recovery snapshot will be created."
    fi
fi

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

if sudo snapper -c root list 2>/dev/null \
    | awk -v id="$SNAPSHOT_ID" \
        '$1 == id { found=1; exit } END { exit !found }'; then

    log "[ok] Installation recovery snapshot verified."
else
    die "Snapper reported snapshot $SNAPSHOT_ID, but it could not be found afterward."
fi

# ------------------------------------------------------------
# Save snapshot state
# ------------------------------------------------------------

printf '%s\n' "$SNAPSHOT_ID" > "$SNAPSHOT_STATE"

log "[ok] Installation snapshot ID saved."
log "Created recovery snapshot: $SNAPSHOT_ID"
log "Snapshot description: Hyprland-Canvas installation"
log ""
log "Snapshot stage completed successfully."

exit 0