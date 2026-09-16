#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-preflight.sh"

log "Running final installation verification..."

FAILED=0

pass() {
    printf '  [OK]   %s\n' "$*"
}

warn() {
    printf '  [WARN] %s\n' "$*"
}

fail() {
    printf '  [FAIL] %s\n' "$*" >&2
    FAILED=1
}

check_command() {
    local command_name="$1"

    if command -v "$command_name" >/dev/null 2>&1; then
        pass "$command_name is installed."
    else
        fail "$command_name was not found."
    fi
}

check_file() {
    local file_path="$1"
    local description="$2"

    if [[ -f "$file_path" ]]; then
        pass "$description"
    else
        fail "$description"
    fi
}

printf '\n'
log "Checking required commands..."

check_command Hyprland
check_command uwsm
check_command dms
check_command quickshell
check_command kitty
check_command sddm
check_command systemctl

printf '\n'
log "Checking SDDM configuration..."

SDDM_CONF="/etc/sddm.conf.d/10-hyprland.conf"

if sudo test -f "$SDDM_CONF"; then
    pass "SDDM configuration exists: $SDDM_CONF"
else
    fail "SDDM configuration is missing: $SDDM_CONF"
fi

if sudo grep -q '^DisplayServer=wayland$' "$SDDM_CONF" 2>/dev/null; then
    pass "SDDM is configured to use the Wayland display server."
else
    fail "SDDM configuration does not contain DisplayServer=wayland."
fi

if systemctl is-enabled sddm.service >/dev/null 2>&1; then
    pass "SDDM is enabled."
else
    fail "SDDM is not enabled."
fi

printf '\n'
log "Checking Hyprland UWSM session..."

UWSM_SESSION="/usr/share/wayland-sessions/hyprland-uwsm.desktop"

if [[ -f "$UWSM_SESSION" ]]; then
    pass "Hyprland UWSM session exists."
else
    fail "Hyprland UWSM session is missing: $UWSM_SESSION"
fi

if [[ -f "$UWSM_SESSION" ]]; then
    if grep -qE '^Exec=.*uwsm[[:space:]]+start' "$UWSM_SESSION"; then
        pass "Hyprland session is launched through UWSM."
    else
        fail "Hyprland UWSM session does not contain an expected uwsm start command."
    fi
fi

printf '\n'
log "Checking DMS environment..."

DMS_ENV="$HOME/.config/environment.d/90-dms.conf"

check_file \
    "$DMS_ENV" \
    "DMS environment file exists: $DMS_ENV"

if [[ -f "$DMS_ENV" ]]; then
    if grep -q '^QT_QPA_PLATFORM=wayland$' "$DMS_ENV"; then
        pass "Qt is configured to use Wayland."
    else
        fail "QT_QPA_PLATFORM=wayland is missing."
    fi

    if grep -q '^QT_QPA_PLATFORMTHEME=gtk3$' "$DMS_ENV"; then
        pass "Qt platform theme is configured."
    else
        fail "QT_QPA_PLATFORMTHEME=gtk3 is missing."
    fi

    if grep -q '^ELECTRON_OZONE_PLATFORM_HINT=auto$' "$DMS_ENV"; then
        pass "Electron Wayland hint is configured."
    else
        fail "ELECTRON_OZONE_PLATFORM_HINT=auto is missing."
    fi

    if grep -q '^TERMINAL=kitty$' "$DMS_ENV"; then
        pass "DMS terminal is configured as kitty."
    else
        fail "TERMINAL=kitty is missing."
    fi
fi

printf '\n'
log "Checking Hyprland systemd session target..."

SESSION_TARGET="$HOME/.config/systemd/user/hyprland-session.target"

check_file \
    "$SESSION_TARGET" \
    "Hyprland session target exists: $SESSION_TARGET"

if [[ -f "$SESSION_TARGET" ]]; then
    if grep -q '^Requires=graphical-session.target$' "$SESSION_TARGET"; then
        pass "Hyprland session target requires graphical-session.target."
    else
        fail "Hyprland session target is missing Requires=graphical-session.target."
    fi

    if grep -q '^After=graphical-session.target$' "$SESSION_TARGET"; then
        pass "Hyprland session target starts after graphical-session.target."
    else
        fail "Hyprland session target is missing After=graphical-session.target."
    fi
fi

printf '\n'
log "Checking DMS systemd service..."

if systemctl --user cat dms.service >/dev/null 2>&1; then
    pass "DMS user service exists."
else
    fail "DMS user service was not found."
fi

DMS_WANTS_DIR="$HOME/.config/systemd/user/hyprland-session.target.wants"
DMS_WANTS_LINK="$DMS_WANTS_DIR/dms.service"

if [[ -L "$DMS_WANTS_LINK" ]]; then
    pass "DMS is attached to hyprland-session.target."
else
    fail "DMS is not attached to hyprland-session.target."
fi

if [[ -L "$DMS_WANTS_LINK" ]]; then
    DMS_WANTS_TARGET="$(readlink -f "$DMS_WANTS_LINK" 2>/dev/null || true)"

    if [[ "$DMS_WANTS_TARGET" == */dms.service ]]; then
        pass "DMS target dependency points to dms.service."
    else
        warn "DMS dependency exists but its target could not be verified."
    fi
fi

printf '\n'
log "Checking DMS Hyprland integration..."

HYPR_CONFIG_DIR="$HOME/.config/hypr"

if [[ -d "$HYPR_CONFIG_DIR" ]]; then
    pass "Hyprland configuration directory exists."
else
    fail "Hyprland configuration directory is missing: $HYPR_CONFIG_DIR"
fi

DMS_HYPR_DIR="$HOME/.config/hypr/dms"

if [[ -d "$DMS_HYPR_DIR" ]]; then
    pass "DMS Hyprland configuration directory exists."
else
    warn "DMS Hyprland configuration directory was not created."
fi

printf '\n'
log "Checking core backend services..."

for service in \
    NetworkManager.service \
    bluetooth.service \
    pipewire.service \
    pipewire-pulse.service \
    wireplumber.service; do

    if systemctl cat "$service" >/dev/null 2>&1; then
        pass "$service is installed."
    else
        fail "$service was not found."
    fi
done

printf '\n'
log "Checking important user configuration directories..."

for directory in \
    "$HOME/.config/systemd/user" \
    "$HOME/.config/environment.d"; do

    if [[ -d "$directory" ]]; then
        pass "$directory exists."
    else
        warn "$directory does not exist."
    fi
done

printf '\n'
log "Checking current user systemd manager..."

if systemctl --user is-system-running >/dev/null 2>&1; then
    pass "User systemd manager is reachable."
else
    warn "User systemd manager could not be queried."
    warn "This is normal if the installer is running outside a complete user session."
fi

printf '\n'
log "Checking DMS setup command..."

if dms setup headless \
    --compositor hyprland \
    --terminal kitty \
    --skip-existing \
    >/dev/null 2>&1; then

    pass "DMS headless setup can run successfully."
else
    fail "DMS headless setup returned an error."
fi

printf '\n'

if (( FAILED != 0 )); then
    log "========================================"
    log "VERIFICATION FAILED"
    log "========================================"
    log "One or more required components are missing or incorrectly configured."
    log "Review the messages above before rebooting."
    exit 1
fi

log "========================================"
log "VERIFICATION PASSED"
log "========================================"
log "The baseline installation appears to be complete."
log ""
log "Recommended next step:"
log "  Reboot the system."
log ""
log "After reboot:"
log "  1. SDDM should appear."
log "  2. Select the Hyprland (UWSM) session."
log "  3. Log in."
log "  4. DMS should start with the Hyprland session."
log ""

exit 0