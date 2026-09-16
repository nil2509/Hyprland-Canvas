#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 99-verify.sh
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/00-preflight.sh"

log "Running final installation verification..."

FAILED=0

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

pass() {
    printf '  [PASS] %s\n' "$*"
}

fail() {
    printf '  [FAIL] %s\n' "$*" >&2
    FAILED=1
}

warn() {
    printf '  [WARN] %s\n' "$*"
}

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

log "Checking required commands..."

REQUIRED_COMMANDS=(
    Hyprland
    uwsm
    dms
    quickshell
    kitty
    sddm
    systemctl
)

for command_name in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$command_name" >/dev/null 2>&1; then
        pass "$command_name is available."
    else
        fail "$command_name was not found."
    fi
done

# ------------------------------------------------------------
# SDDM configuration
# ------------------------------------------------------------

log "Checking SDDM configuration..."

SDDM_CONF="/etc/sddm.conf.d/10-hyprland.conf"

if [[ -f "$SDDM_CONF" ]]; then
    pass "SDDM configuration exists: $SDDM_CONF"
else
    fail "SDDM configuration was not found: $SDDM_CONF"
fi

if [[ -f "$SDDM_CONF" ]] &&
   sudo grep -q '^DisplayServer=wayland$' "$SDDM_CONF"; then
    pass "SDDM is configured to use a Wayland display server."
else
    fail "SDDM Wayland configuration is missing."
fi

if systemctl is-enabled --quiet sddm.service; then
    pass "SDDM is enabled."
else
    fail "SDDM is not enabled."
fi

# ------------------------------------------------------------
# Hyprland / UWSM session
# ------------------------------------------------------------

log "Checking Hyprland UWSM session..."

WAYLAND_SESSION_DIR="/usr/share/wayland-sessions"

HYPRLAND_SESSION="$WAYLAND_SESSION_DIR/hyprland.desktop"
UWSM_SESSION="$WAYLAND_SESSION_DIR/hyprland-uwsm.desktop"

if [[ -f "$HYPRLAND_SESSION" ]]; then
    pass "Hyprland session exists: $HYPRLAND_SESSION"
else
    fail "Hyprland session was not found: $HYPRLAND_SESSION"
fi

if [[ -f "$UWSM_SESSION" ]]; then
    pass "UWSM Hyprland session exists: $UWSM_SESSION"
else
    fail "UWSM Hyprland session was not found: $UWSM_SESSION"
fi

if [[ -f "$UWSM_SESSION" ]] &&
   grep -qE '^Exec=uwsm[[:space:]]+start[[:space:]]+--[[:space:]]+hyprland\.desktop$' "$UWSM_SESSION"; then
    pass "UWSM session correctly launches hyprland.desktop."
else
    fail "UWSM session has an unexpected or missing Exec entry."
fi

if [[ -f "$UWSM_SESSION" ]] &&
   grep -q '^TryExec=uwsm$' "$UWSM_SESSION"; then
    pass "UWSM session contains TryExec=uwsm."
else
    fail "UWSM session is missing TryExec=uwsm."
fi

# ------------------------------------------------------------
# DankMaterialShell environment
# ------------------------------------------------------------

log "Checking DankMaterialShell environment..."

DMS_ENV_DIR="$HOME/.config/environment.d"
DMS_ENV_FILE="$DMS_ENV_DIR/90-dms.conf"

if [[ -d "$DMS_ENV_DIR" ]]; then
    pass "User environment.d directory exists."
else
    fail "User environment.d directory was not found: $DMS_ENV_DIR"
fi

if [[ -f "$DMS_ENV_FILE" ]]; then
    pass "DMS environment configuration exists: $DMS_ENV_FILE"
else
    fail "DMS environment configuration was not found: $DMS_ENV_FILE"
fi

if [[ -f "$DMS_ENV_FILE" ]] &&
   grep -q '^QT_QPA_PLATFORM=wayland$' "$DMS_ENV_FILE"; then
    pass "QT_QPA_PLATFORM=wayland is configured."
else
    fail "QT_QPA_PLATFORM=wayland is missing from DMS environment."
fi

if [[ -f "$DMS_ENV_FILE" ]] &&
   grep -q '^TERMINAL=kitty$' "$DMS_ENV_FILE"; then
    pass "TERMINAL=kitty is configured."
else
    fail "TERMINAL=kitty is missing from DMS environment."
fi

# ------------------------------------------------------------
# DMS Hyprland configuration
# ------------------------------------------------------------

log "Checking DMS Hyprland configuration..."

DMS_HYPR_DIR="$HOME/.config/hypr/dms"

if [[ -d "$DMS_HYPR_DIR" ]]; then
    pass "DMS Hyprland configuration exists: $DMS_HYPR_DIR"
else
    fail "DMS Hyprland configuration directory was not found: $DMS_HYPR_DIR"
fi

# ------------------------------------------------------------
# User systemd integration
# ------------------------------------------------------------

log "Checking user systemd integration..."

if systemctl --user cat hyprland-session.target >/dev/null 2>&1; then
    pass "hyprland-session.target is available to the user manager."
else
    warn "hyprland-session.target could not be queried from the current user manager."
fi

if systemctl --user cat dms.service >/dev/null 2>&1; then
    pass "dms.service is available to the user manager."
else
    warn "dms.service could not be queried from the current user manager."
fi

if systemctl --user is-system-running >/dev/null 2>&1; then
    pass "User systemd manager is available."
else
    warn "User systemd manager is not currently available; this is expected outside a graphical session."
fi

# ------------------------------------------------------------
# Backend system services
# ------------------------------------------------------------

log "Checking system-level backend services..."

SYSTEM_SERVICES=(
    NetworkManager.service
    bluetooth.service
)

for service in "${SYSTEM_SERVICES[@]}"; do
    if systemctl cat "$service" >/dev/null 2>&1; then
        pass "$service is installed."
    else
        fail "$service was not found."
    fi
done

# ------------------------------------------------------------
# Backend user services
# ------------------------------------------------------------

log "Checking user-level PipeWire/WirePlumber services..."

USER_SERVICE_DIRS=(
    "$HOME/.config/systemd/user"
    "$HOME/.local/share/systemd/user"
    "/etc/systemd/user"
    "/usr/local/lib/systemd/user"
    "/usr/lib/systemd/user"
    "/usr/local/share/systemd/user"
    "/usr/share/systemd/user"
)

USER_SERVICES=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
)

for service in "${USER_SERVICES[@]}"; do
    found=0

    for unit_dir in "${USER_SERVICE_DIRS[@]}"; do
        if [[ -f "$unit_dir/$service" ]]; then
            found=1
            break
        fi
    done

    if [[ "$found" -eq 1 ]]; then
        pass "$service is installed."
    else
        fail "$service was not found in the user systemd unit paths."
    fi
done

# ------------------------------------------------------------
# User configuration directories
# ------------------------------------------------------------

log "Checking user configuration directories..."

USER_CONFIG_DIRS=(
    "$HOME/.config/hypr"
    "$HOME/.config/hypr/dms"
    "$HOME/.config/environment.d"
)

for directory in "${USER_CONFIG_DIRS[@]}"; do
    if [[ -d "$directory" ]]; then
        pass "Directory exists: $directory"
    else
        fail "Directory was not found: $directory"
    fi
done

# ------------------------------------------------------------
# Final result
# ------------------------------------------------------------

log ""

if [[ "$FAILED" -eq 0 ]]; then
    log "========================================"
    log "VERIFICATION PASSED"
    log "========================================"
    log "All required installation checks passed."
    log ""
    log "A reboot is recommended before starting the new session."
    exit 0
fi

log "========================================"
log "VERIFICATION FAILED"
log "========================================"
log "One or more required installation checks failed."
log "Review the [FAIL] entries above."

exit 1