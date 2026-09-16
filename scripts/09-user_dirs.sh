#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring user directories..."

command -v xdg-user-dirs-update >/dev/null 2>&1 \
    || die "xdg-user-dirs-update is not installed."

log "Initializing XDG user directories..."
xdg-user-dirs-update

USER_DIRS_FILE="$HOME/.config/user-dirs.dirs"

if [[ -f "$USER_DIRS_FILE" ]]; then
    log "XDG user directories configured:"
    log "  $USER_DIRS_FILE"
else
    die "XDG user directory configuration was not created: $USER_DIRS_FILE"
fi

log "User directory configuration complete."

exit 0