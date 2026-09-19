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

sudo flatpak remote-add --system --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

log "Verifying the Flathub remote..."

if sudo flatpak remotes --system --columns=name | grep -qx "flathub"; then
    log "[ok] Flathub remote is configured."
else
    die "Flathub remote was not configured."
fi

# ------------------------------------------------------------
# Warehouse
# ------------------------------------------------------------

if flatpak info --system io.github.flattool.Warehouse >/dev/null; then
    log "Warehouse is already installed"
else
    log "Warehouse not found"
    log "Installing Warehouse..."

    sudo flatpak --system install \
        --noninteractive \
        flathub \
        io.github.flattool.Warehouse

    if sudo flatpak info --system io.github.flattool.Warehouse >/dev/null 2>&1; then
        log "[ok] Warehouse is installed."
    else
        die "Warehouse installation could not be verified."
    fi
fi

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

if sudo flatpak remotes --system >/dev/null 2>&1; then
    log "[ok] Flatpak system installation is accessible."
else
    die "Flatpak system installation could not be queried."
fi

log "Flatpak/Flathub configuration complete."

exit 0