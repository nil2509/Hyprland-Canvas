#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log "Configuring Flatpak..."

command -v flatpak >/dev/null 2>&1 || die "flatpak is not installed."

flatpak remote-add --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

if flatpak remotes --columns=name | grep -qx "flathub"; then
    log "Flathub remote is configured."
else
    die "Flathub remote was not configured."
fi

log "Flatpak/Flathub configuration complete."
exit 0