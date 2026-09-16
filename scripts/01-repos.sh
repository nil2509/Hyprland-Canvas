#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 01-repos.sh
# ============================================================

log() {
    printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

# ------------------------------------------------------------
# Repository definitions
# ------------------------------------------------------------

REPO_ALIASES=(
    "wayland"
    "danklinux"
    "dms"
)

declare -A REPO_URLS=(
    [wayland]="https://download.opensuse.org/repositories/X11:Wayland/openSUSE_Tumbleweed/X11:Wayland.repo"
    [danklinux]="https://download.opensuse.org/repositories/home:/AvengeMedia:/danklinux/openSUSE_Tumbleweed/home:AvengeMedia:danklinux.repo"
    [dms]="https://download.opensuse.org/repositories/home:/AvengeMedia:/dms/openSUSE_Tumbleweed/home:AvengeMedia:dms.repo"
)

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

repo_exists() {
    local alias="$1"

    sudo zypper --non-interactive repos --details \
        | awk -v target="$alias" '$1 == target { found=1 } END { exit !found }'
}

add_repo() {
    local alias="$1"
    local uri="$2"

    if repo_exists "$alias"; then
        log "Repository '$alias' already exists."

        log "Ensuring repository '$alias' is enabled and refreshed automatically..."

        sudo zypper \
            --non-interactive \
            modifyrepo \
            --enable \
            --refresh \
            "$alias" >/dev/null

        return 0
    fi

    log "Adding repository '$alias'..."

    sudo zypper \
        --non-interactive \
        --gpg-auto-import-keys \
        addrepo \
        --refresh \
        "$uri" \
        "$alias"

    log "Repository '$alias' added."
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

log "Configuring additional repositories..."

for alias in "${REPO_ALIASES[@]}"; do
    add_repo "$alias" "${REPO_URLS[$alias]}"
done

# ------------------------------------------------------------
# Refresh repository metadata
# ------------------------------------------------------------

log "Refreshing repository metadata..."

sudo zypper \
    --non-interactive \
    --gpg-auto-import-keys \
    refresh

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

log "Configured repositories:"

sudo zypper repos

log "Repository stage completed successfully."

exit 0