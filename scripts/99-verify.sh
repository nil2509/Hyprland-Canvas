#!/usr/bin/env bash

# ============================================================

# openSUSE Hyprland Desktop Bootstrap

# 99-verify.sh

# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

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
    zsh
    cargo
    xdg-user-dirs-update
    xdg-user-dir
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

if [[ -f "$SDDM_CONF" ]] && \
    grep -q '^DisplayServer=wayland$' "$SDDM_CONF"; then
    pass "SDDM is configured to use a Wayland display server."
else
    fail "SDDM Wayland configuration is missing."
fi

if sudo systemctl is-enabled --quiet sddm.service; then
    pass "SDDM is enabled."
else
    fail "SDDM is not enabled."
fi

DEFAULT_TARGET="$(systemctl get-default)"

if [[ "$DEFAULT_TARGET" == "graphical.target" ]]; then
    pass "Default system target is graphical.target."
else
    fail "Default system target is $DEFAULT_TARGET; expected graphical.target."
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

if [[ -f "$UWSM_SESSION" ]] && \
    grep -qE '^Exec=uwsm[[:space:]]+start[[:space:]]+--[[:space:]]+hyprland.desktop$' \
    "$UWSM_SESSION"; then
    pass "UWSM session correctly launches hyprland.desktop."
else
    fail "UWSM session has an unexpected or missing Exec entry."
fi

if [[ -f "$UWSM_SESSION" ]] && \
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

if [[ -f "$DMS_ENV_FILE" ]] && \
    grep -q '^QT_QPA_PLATFORM=wayland$' "$DMS_ENV_FILE"; then
    pass "QT_QPA_PLATFORM=wayland is configured."
else
    fail "QT_QPA_PLATFORM=wayland is missing from DMS environment."
fi

if [[ -f "$DMS_ENV_FILE" ]] && \
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

if command -v dms >/dev/null 2>&1; then
    pass "DankMaterialShell is available."
else
    fail "DankMaterialShell was not found."
fi

if [[ -d "$DMS_HYPR_DIR" ]]; then
    pass "DMS Hyprland configuration exists: $DMS_HYPR_DIR"
else
    fail "DMS Hyprland configuration directory was not found: $DMS_HYPR_DIR"
fi

# ------------------------------------------------------------

# XDG user directories

# ------------------------------------------------------------

log "Checking XDG user directories..."

USER_DIRS_FILE="$HOME/.config/user-dirs.dirs"

if [[ -f "$USER_DIRS_FILE" ]]; then
    pass "XDG user directories configuration exists: $USER_DIRS_FILE"
else
    fail "XDG user directories configuration was not found: $USER_DIRS_FILE"
fi

# ------------------------------------------------------------

# Cargo-installed tools

# ------------------------------------------------------------

log "Checking Cargo-installed tools..."

CARGO_BIN_DIR="${CARGO_HOME:-$HOME/.cargo}/bin"

CARGO_BINARIES=(
    pokeget
    zoxide
    matugen
)

for binary in "${CARGO_BINARIES[@]}"; do
    if [[ -x "$CARGO_BIN_DIR/$binary" ]]; then
        pass "Cargo binary exists: $CARGO_BIN_DIR/$binary"
    else
        fail "Cargo binary was not found: $CARGO_BIN_DIR/$binary"
    fi
done

# ------------------------------------------------------------

# Zsh / Oh My Zsh / Powerlevel10k

# ------------------------------------------------------------

log "Checking shell configuration..."

ZSH_PATH="$(command -v zsh || true)"
ZSH_DIR="$HOME/.oh-my-zsh"
P10K_DIR="$ZSH_DIR/custom/themes/powerlevel10k"
ZSHRC="$HOME/.zshrc"

if [[ -n "$ZSH_PATH" ]]; then
    pass "Zsh executable exists: $ZSH_PATH"
else
    fail "Zsh executable was not found."
fi

if [[ -f "$ZSHRC" ]]; then
    pass "Zsh configuration exists: $ZSHRC"
else
    fail "Zsh configuration was not found: $ZSHRC"
fi

if [[ -d "$ZSH_DIR" ]]; then
    pass "Oh My Zsh installation exists: $ZSH_DIR"
else
    fail "Oh My Zsh installation was not found: $ZSH_DIR"
fi

if [[ -d "$P10K_DIR" ]]; then
    pass "Powerlevel10k installation exists: $P10K_DIR"
else
    fail "Powerlevel10k installation was not found: $P10K_DIR"
fi

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ -n "$ZSH_PATH" && "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    pass "Zsh is configured as the default shell."
else
    fail "Zsh is not configured as the default shell."
fi

if [[ -f "$ZSHRC" ]] && \
    grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"$' "$ZSHRC"; then
    pass "Powerlevel10k is configured as the Zsh theme."
else
    fail "Powerlevel10k is not configured as the Zsh theme."
fi

if [[ -f "$ZSHRC" ]] && \
    grep -q 'export PATH=.*\.cargo/bin' "$ZSHRC"; then
    pass "Cargo bin directory is added to the Zsh PATH."
else
    fail "Cargo bin directory is missing from the Zsh PATH."
fi

if [[ -f "$ZSHRC" ]] && \
    grep -q 'zoxide init zsh' "$ZSHRC"; then
    pass "zoxide is configured for Zsh."
else
    fail "zoxide is not configured for Zsh."
fi

# ------------------------------------------------------------

# Annotation Mono Nerd Font

# ------------------------------------------------------------

log "Checking Annotation Mono Nerd Font..."

if command -v fc-list >/dev/null 2>&1 && \
    fc-list | grep -qi "Annotation Mono"; then
    pass "Annotation Mono Nerd Font is installed."
else
    fail "Annotation Mono Nerd Font was not found."
fi

# ------------------------------------------------------------

# Kitty configuration

# ------------------------------------------------------------

log "Checking Kitty configuration..."

KITTY_CONF="$HOME/.config/kitty/kitty.conf"

if [[ -f "$KITTY_CONF" ]]; then
    pass "Kitty configuration exists: $KITTY_CONF"
else
    fail "Kitty configuration was not found: $KITTY_CONF"
fi

if [[ -f "$KITTY_CONF" ]] && \
    grep -Eq '^[[:space:]]*font_family[[:space:]]+AnnotationMono Nerd Font([[:space:]]*)$' \
    "$KITTY_CONF"; then
    pass "Kitty is configured to use AnnotationMono Nerd Font."
else
    fail "Kitty AnnotationMono Nerd Font configuration is missing."
fi

# ------------------------------------------------------------

# zram

# ------------------------------------------------------------

log "Checking zram configuration..."

ZRAM_CONF="/etc/systemd/zram-generator.conf"

if command -v rpm >/dev/null 2>&1 && \
    rpm -q zram-generator >/dev/null 2>&1; then

    pass "zram-generator is installed."

    if [[ -f "$ZRAM_CONF" ]]; then
        pass "zram configuration exists."

        if grep -q '^zram-size = ram / 2$' "$ZRAM_CONF"; then
            pass "zram size is configured to half of RAM."
        else
            warn "zram size is not configured to half of RAM."
        fi

        if grep -q '^compression-algorithm = zstd$' "$ZRAM_CONF"; then
            pass "zram compression is configured as zstd."
        else
            warn "zram compression is not configured as zstd."
        fi
    else
        fail "zram-generator is installed but its configuration is missing."
    fi

else
    fail "zram-generator is not installed."
fi

# ------------------------------------------------------------

# System services

# ------------------------------------------------------------

log "Checking system-level backend services..."

SYSTEM_SERVICES=(
    NetworkManager.service
    bluetooth.service
    power-profiles-daemon.service
)

for service in "${SYSTEM_SERVICES[@]}"; do
    if systemctl cat "$service" >/dev/null 2>&1; then
        pass "$service is installed."
    else
        fail "$service was not found."
    fi

    if sudo systemctl is-enabled --quiet "$service"; then
        pass "$service is enabled."
    else
        fail "$service is not enabled."
    fi
done

# ------------------------------------------------------------

# User-level PipeWire/WirePlumber

# ------------------------------------------------------------

log "Checking user-level PipeWire/WirePlumber services..."

USER_SERVICES=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
)

for service in "${USER_SERVICES[@]}"; do
    if systemctl --user cat "$service" >/dev/null 2>&1; then
        pass "$service unit is accessible."
    else
        warn "$service unit could not be queried from the current user manager."
    fi
done

# ------------------------------------------------------------

# User systemd integration

# ------------------------------------------------------------

log "Checking user systemd integration..."

if systemctl --user cat hyprland-session.target >/dev/null 2>&1; then
    pass "hyprland-session.target is available to the user manager."
else
    warn "hyprland-session.target could not be queried from the current user manager."
fi

# ------------------------------------------------------------

# Optional HyprMod

# ------------------------------------------------------------

log "Checking optional HyprMod..."

if [[ "${INSTALL_OPTIONAL:-0}" == "1" ]]; then

    if command -v hyprmod >/dev/null 2>&1; then
        pass "Optional HyprMod is installed."

        XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
        HYPRMOD_DESKTOP="$XDG_DATA_HOME/applications/hyprmod.desktop"

        if [[ -f "$HYPRMOD_DESKTOP" ]]; then
            pass "HyprMod desktop entry exists."
        else
            warn "HyprMod is installed but its desktop entry was not found."
        fi
    else
        warn "Optional HyprMod was requested but is not installed."
    fi

else
    log "HyprMod was not requested; skipping verification."
fi

# ------------------------------------------------------------

# User configuration directories

# ------------------------------------------------------------

log "Checking user configuration directories..."

USER_CONFIG_DIRS=(
    "$HOME/.config/hypr"
    "$HOME/.config/hypr/dms"
    "$HOME/.config/environment.d"
    "$HOME/.config/kitty"
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