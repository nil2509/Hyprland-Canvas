#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring user directories..."

# ------------------------------------------------------------
# Required command
# ------------------------------------------------------------

command -v xdg-user-dirs-update >/dev/null 2>&1 \
    || die "xdg-user-dirs-update is not installed."

# ------------------------------------------------------------
# User environment
# ------------------------------------------------------------

[[ -n "${HOME:-}" ]] \
    || die "HOME is not set."

[[ -d "$HOME" ]] \
    || die "Home directory does not exist: $HOME"

[[ -w "$HOME" ]] \
    || die "Home directory is not writable: $HOME"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_DIRS_FILE="$XDG_CONFIG_HOME/user-dirs.dirs"

# ------------------------------------------------------------
# Ensure configuration directory exists
# ------------------------------------------------------------

if [[ ! -d "$XDG_CONFIG_HOME" ]]; then
    log "Creating XDG configuration directory:"
    log "  $XDG_CONFIG_HOME"

    mkdir -p "$XDG_CONFIG_HOME"
fi

# ------------------------------------------------------------
# Initialize/update XDG user directories
# ------------------------------------------------------------

log "Initializing XDG user directories..."

xdg-user-dirs-update

# ------------------------------------------------------------
# Verify configuration
# ------------------------------------------------------------

if [[ -f "$USER_DIRS_FILE" ]]; then
    log "[ok] XDG user directory configuration exists:"
    log "  $USER_DIRS_FILE"
else
    die "XDG user directory configuration was not created: $USER_DIRS_FILE"
fi

# ------------------------------------------------------------
# Verify standard XDG entries
# ------------------------------------------------------------

USER_DIR_NAMES=(
    DESKTOP
    DOWNLOAD
    TEMPLATES
    PUBLICSHARE
    DOCUMENTS
    MUSIC
    PICTURES
    VIDEOS
)

for name in "${USER_DIR_NAMES[@]}"; do
    if grep -qE "^XDG_${name}_DIR=" "$USER_DIRS_FILE"; then
        log "[ok] XDG_${name}_DIR is configured."
    else
        log "[warn] XDG_${name}_DIR is not configured."
    fi
done

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log "User directory configuration complete."

exit 0