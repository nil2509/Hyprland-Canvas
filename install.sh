#!/usr/bin/env bash

# ============================================================
# openSUSE Tumbleweed + Hyprland + UWSM + DMS
# Bootstrap Installer
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

LOG_FILE="$SCRIPT_DIR/install-$(date '+%Y%m%d-%H%M%S').log"

exec > >(tee -a "$LOG_FILE") 2>&1

# ------------------------------------------------------------
# Basic installer checks
# ------------------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run this installer as root. Run it as your normal user."
fi

command -v sudo >/dev/null 2>&1 \
    || die "sudo is required."

command -v bash >/dev/null 2>&1 \
    || die "bash is required."

# ------------------------------------------------------------
# Optional components
# ------------------------------------------------------------

INSTALL_OPTIONAL=0

case "${1:-}" in
    --with-optional)
        INSTALL_OPTIONAL=1
        ;;

    --without-optional)
        INSTALL_OPTIONAL=0
        ;;

    --help|-h)
        cat <<'EOF'
Usage: ./install.sh [OPTION]

Options:
  --with-optional       Install optional packages and components
  --without-optional    Skip optional packages and components
  -h, --help            Show this help message

With no option, the installer asks whether optional components
should be installed when running interactively.

Optional components include:
  - Optional packages
  - HyprMod
EOF
        exit 0
        ;;

    "")
        if [[ -t 0 && -t 1 ]]; then
            printf '\n'
            printf 'Install optional packages and components? [y/N]: '
            read -r answer

            case "$answer" in
                [yY]|[yY][eE][sS])
                    INSTALL_OPTIONAL=1
                    ;;
                *)
                    INSTALL_OPTIONAL=0
                    ;;
            esac
        else
            log "Non-interactive execution detected; skipping optional components."
        fi
        ;;

    *)
        die "Unknown option: $1"
        ;;
esac

export INSTALL_OPTIONAL

if [[ "$INSTALL_OPTIONAL" == "1" ]]; then
    log "Optional packages and components: ENABLED"
else
    log "Optional packages and components: DISABLED"
fi

# ------------------------------------------------------------
# Sudo authentication
# ------------------------------------------------------------

log "Checking sudo access..."

sudo -v

# Keep sudo credentials alive for the entire installer.
(
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done
) 2>/dev/null &

SUDO_KEEPALIVE_PID=$!

cleanup() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

# ------------------------------------------------------------
# Make installer scripts executable
#
# This is useful when the repository was cloned from a system
# that did not preserve Linux executable bits.
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
    "02-snapshot.sh"
    "03-packages.sh"
    "04-sddm.sh"
    "05-dms.sh"
    "06-session.sh"
    "07-services.sh"
    "08-zram.sh"
    "09-user_dirs.sh"
    "10-cargos.sh"
    "11-shell.sh"
    "12-kitty.sh"
    "13-flatpak.sh"
    "14-hyprmod.sh"
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
# Installer header
# ------------------------------------------------------------

log "========================================"
log "openSUSE Hyprland installer"
log "========================================"
log "Repository: $SCRIPT_DIR"
log "Log file:   $LOG_FILE"

if [[ "$INSTALL_OPTIONAL" == "1" ]]; then
    log "Optional:   enabled"
else
    log "Optional:   disabled"
fi

log "========================================"

# ------------------------------------------------------------
# Run stages
# ------------------------------------------------------------

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