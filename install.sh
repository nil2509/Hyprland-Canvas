#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# openSUSE Tumbleweed + Hyprland + UWSM + DMS
# Bootstrap Installer
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

LOG_FILE="$SCRIPT_DIR/install-$(date '+%Y%m%d-%H%M%S').log"

exec > >(tee -a "$LOG_FILE") 2>&1

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

log() {
    printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

# ------------------------------------------------------------
# Make installer scripts executable
#
# This is important because the repository may have been
# created/cloned from Windows, where executable bits aren't
# handled the same way as Linux.
# ------------------------------------------------------------

if [[ -d "$SCRIPT_DIR/scripts" ]]; then
    find "$SCRIPT_DIR/scripts" \
        -type f \
        -name '*.sh' \
        -exec chmod +x {} +
fi

chmod +x "$SCRIPT_DIR/install.sh" 2>/dev/null || true

# ------------------------------------------------------------
# Installer stages
# ------------------------------------------------------------

STAGES=(
    "00-preflight.sh"
    "01-repos.sh"
    "02-packages.sh"
    "03-sddm.sh"
    "04-session.sh"
    "05-dms.sh"
    "99-verify.sh"
)

# ------------------------------------------------------------
# Verify all stage scripts exist
# ------------------------------------------------------------

log "Checking installer stages..."

for stage in "${STAGES[@]}"; do
    stage_path="$SCRIPT_DIR/scripts/$stage"

    if [[ ! -f "$stage_path" ]]; then
        die "Missing installer stage: scripts/$stage"
    fi

    log "Found: $stage"
done

# ------------------------------------------------------------
# Run stages
# ------------------------------------------------------------

log "========================================"
log "openSUSE Hyprland installer"
log "========================================"
log "Repository: $SCRIPT_DIR"
log "Log file:   $LOG_FILE"
log "========================================"

for stage in "${STAGES[@]}"; do
    stage_path="$SCRIPT_DIR/scripts/$stage"

    log ""
    log "----------------------------------------"
    log "Running: $stage"
    log "----------------------------------------"

    if bash "$stage_path"; then
        log "Completed: $stage"
    else
        status=$?

        log ""
        log "========================================"
        log "FAILED: $stage"
        log "Exit code: $status"
        log "========================================"
        log "Installation stopped."
        log "Check the log:"
        log "$LOG_FILE"

        exit "$status"
    fi
done

# ------------------------------------------------------------
# Finished
# ------------------------------------------------------------

log ""
log "========================================"
log "INSTALLATION COMPLETE"
log "========================================"

log "All installer stages completed successfully."
log ""
log "A reboot is recommended before starting the new session."
log ""

exit 0