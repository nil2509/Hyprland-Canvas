#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring Flatpak..."

# ------------------------------------------------------------
# Required command
# ------------------------------------------------------------

command -v flatpak >/dev/null 2>&1 \
    || die "flatpak is not installed."

# ------------------------------------------------------------
# Flathub
# ------------------------------------------------------------

log "Configuring the Flathub remote..."

flatpak remote-add --system --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

log "Verifying the Flathub remote..."

if flatpak remotes --system --columns=name | grep -qx "flathub"; then
    log "[ok] Flathub remote is configured."
else
    die "Flathub remote was not configured."
fi

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

if flatpak remotes --system >/dev/null 2>&1; then
    log "[ok] Flatpak system installation is accessible."
else
    die "Flatpak system installation could not be queried."
fi

log "Flatpak/Flathub configuration complete."

exit 0