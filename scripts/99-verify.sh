#!/usr/bin/env bash

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
    quickshell
    kitty
    sddm
    zsh
    cargo
    xdg-user-dirs-update
    xdg-user-dir
    systemctl
    rpm
    fc-list
    flatpak
)

for command_name in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$command_name" >/dev/null 2>&1; then
        pass "$command_name is available."
    else
        fail "$command_name was not found."
    fi
done

# ------------------------------------------------------------
# SDDM
# ------------------------------------------------------------

log "Checking SDDM configuration..."

SDDM_CONF="/etc/sddm.conf.d/x11.conf"

if [[ -f "$SDDM_CONF" ]]; then
    pass "SDDM configuration exists: $SDDM_CONF"
else
    fail "SDDM configuration was not found: $SDDM_CONF"
fi

if [[ -f "$SDDM_CONF" ]] && \
    sudo grep -q '^DisplayServer=x11$' "$SDDM_CONF"; then
    pass "SDDM is configured to use X11."
else
    fail "SDDM X11 configuration is missing."
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
    pass "Hyprland session exists."
else
    fail "Hyprland session was not found."
fi

if [[ -f "$UWSM_SESSION" ]]; then
    pass "UWSM Hyprland session exists."
else
    fail "UWSM Hyprland session was not found."
fi

if [[ -f "$UWSM_SESSION" ]] && \
    grep -qE '^Exec=uwsm[[:space:]]+start[[:space:]]+' \
    "$UWSM_SESSION"; then
    pass "UWSM session launches through uwsm start."
else
    fail "UWSM session has an unexpected or missing Exec entry."
fi

if [[ -f "$UWSM_SESSION" ]] && \
    grep -q '^TryExec=uwsm$' "$UWSM_SESSION"; then
    pass "UWSM session contains TryExec=uwsm."
else
    fail "UWSM session is missing TryExec=uwsm."
fi

if [[ -f "$UWSM_SESSION" ]] && \
    grep -q '^Type=Application$' "$UWSM_SESSION"; then
    pass "UWSM session is an Application entry."
else
    fail "UWSM session is missing Type=Application."
fi

# ------------------------------------------------------------
# XDG user directories
# ------------------------------------------------------------

log "Checking XDG user directories..."

USER_DIRS_FILE="$HOME/.config/user-dirs.dirs"

if [[ -f "$USER_DIRS_FILE" ]]; then
    pass "XDG user directories configuration exists."
else
    fail "XDG user directories configuration was not found."
fi

XDG_USER_DIRS=(
    DESKTOP
    DOWNLOAD
    TEMPLATES
    PUBLICSHARE
    DOCUMENTS
    MUSIC
    PICTURES
    VIDEOS
)

for directory_name in "${XDG_USER_DIRS[@]}"; do
    if grep -qE "^XDG_${directory_name}_DIR=" "$USER_DIRS_FILE" 2>/dev/null; then
        pass "XDG_${directory_name}_DIR is configured."
    else
        warn "XDG_${directory_name}_DIR is not configured."
    fi
done

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
        pass "Cargo binary exists: $binary"
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
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

if [[ -n "$ZSH_PATH" ]]; then
    pass "Zsh executable exists."
else
    fail "Zsh executable was not found."
fi

if [[ -f "$ZSHRC" ]]; then
    pass "Zsh configuration exists."
else
    fail "Zsh configuration was not found."
fi

if [[ -d "$ZSH_DIR" ]]; then
    pass "Oh My Zsh installation exists."
else
    fail "Oh My Zsh installation was not found."
fi

if [[ -d "$P10K_DIR" ]]; then
    pass "Powerlevel10k installation exists."
else
    fail "Powerlevel10k installation was not found."
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
    pass "Cargo bin directory is configured in Zsh."
else
    fail "Cargo bin directory is missing from Zsh configuration."
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

if fc-list | grep -ci "Annotation Mono" >/dev/null; then
    pass "Annotation Mono Nerd Font is installed."
else
    fail "Annotation Mono Nerd Font was not found."
fi

# ------------------------------------------------------------
# Kitty
# ------------------------------------------------------------

log "Checking Kitty configuration..."

KITTY_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"

if [[ -f "$KITTY_CONF" ]]; then
    pass "Kitty configuration exists."
else
    fail "Kitty configuration was not found."
fi

if [[ -f "$KITTY_CONF" ]] && \
    grep -Eq \
    '^[[:space:]]*font_family[[:space:]]+AnnotationMono Nerd Font([[:space:]]*)$' \
    "$KITTY_CONF"; then
    pass "Kitty is configured for AnnotationMono Nerd Font."
else
    fail "Kitty AnnotationMono Nerd Font configuration is missing."
fi

# ------------------------------------------------------------
# zram
# ------------------------------------------------------------

log "Checking zram configuration..."

ZRAM_CONF="/etc/systemd/zram-generator.conf"

if rpm -q zram-generator >/dev/null 2>&1; then
    pass "zram-generator is installed."
else
    fail "zram-generator is not installed."
fi

if [[ -f "$ZRAM_CONF" ]]; then
    pass "zram configuration exists."
else
    fail "zram configuration was not found."
fi

if [[ -f "$ZRAM_CONF" ]] && \
    grep -q '^zram-size = ram / 2$' "$ZRAM_CONF"; then
    pass "zram size is configured to half of RAM."
else
    warn "zram size is not configured to half of RAM."
fi

if [[ -f "$ZRAM_CONF" ]] && \
    grep -q '^compression-algorithm = zstd$' "$ZRAM_CONF"; then
    pass "zram compression is configured as zstd."
else
    warn "zram compression is not configured as zstd."
fi

if command -v zramctl >/dev/null 2>&1; then
    if zramctl /dev/zram0 >/dev/null 2>&1; then
        pass "/dev/zram0 is currently active."
    else
        warn "/dev/zram0 is not currently active."
        warn "This can be expected before the first reboot."
    fi
fi

# ------------------------------------------------------------
# Required system services
# ------------------------------------------------------------

log "Checking required system services..."

SYSTEM_SERVICES=(
    NetworkManager.service
    bluetooth.service
    power-profiles-daemon.service
)

for service in "${SYSTEM_SERVICES[@]}"; do
    if systemctl cat "$service" >/dev/null 2>&1; then
        pass "$service is installed."
    else
        fail "$service is not installed."
        continue
    fi

    if sudo systemctl is-enabled --quiet "$service"; then
        pass "$service is enabled."
    else
        fail "$service is not enabled."
    fi

    if sudo systemctl is-active --quiet "$service"; then
        pass "$service is active."
    else
        fail "$service is not active."
    fi
done

# ------------------------------------------------------------
# Required user services
# ------------------------------------------------------------

log "Checking required user services..."

USER_SERVICES=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
    hyprpolkitagent.service
)

for service in "${USER_SERVICES[@]}"; do
    if systemctl --user cat "$service" >/dev/null 2>&1; then
        pass "$service is installed."
    else
        fail "$service is not available."
        continue
    fi

    if systemctl --user is-enabled --quiet "$service"; then
        pass "$service is enabled."
    else
        fail "$service is not enabled."
    fi

    if systemctl --user is-active --quiet "$service"; then
        pass "$service is active."
    else
        warn "$service is not currently active."
    fi
done

# ------------------------------------------------------------
# Flatpak / Flathub
# ------------------------------------------------------------

log "Checking Flatpak..."

if flatpak remotes --system --columns=name 2>/dev/null | \
    grep -qx "flathub"; then
    pass "Flathub system remote is configured."
else
    fail "Flathub system remote is not configured."
fi

# ------------------------------------------------------------
# Optional HyprMod
# ------------------------------------------------------------

log "Checking optional components..."

if [[ "${INSTALL_OPTIONAL:-0}" == "1" ]]; then

    if command -v hyprmod >/dev/null 2>&1; then
        pass "HyprMod is installed."

        XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
        HYPRMOD_DESKTOP="$XDG_DATA_HOME/applications/hyprmod.desktop"

        if [[ -f "$HYPRMOD_DESKTOP" ]]; then
            pass "HyprMod desktop entry exists."
        else
            warn "HyprMod desktop entry was not found."
        fi
    else
        fail "HyprMod was requested but is not installed."
    fi

else
    log "Optional components were not requested."
    log "Skipping HyprMod verification."
fi

# ------------------------------------------------------------
# User configuration directories
# ------------------------------------------------------------

log "Checking user configuration directories..."

USER_CONFIG_DIRS=(
    "$HOME/.config/hypr"
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
    log "After reboot, select:"
    log "  Hyprland (uwsm-managed)"
    exit 0
fi

log "========================================"
log "VERIFICATION FAILED"
log "========================================"
log "One or more required installation checks failed."
log "Review the [FAIL] entries above."

exit 1