#!/usr/bin/env bash

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 01-repos.sh
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring additional repositories..."

# ------------------------------------------------------------
# Repository definitions
# ------------------------------------------------------------

REPO_ALIASES=(
    "danklinux"
    "dms"
)

declare -A REPO_URLS=(
    [danklinux]="https://download.opensuse.org/repositories/home:AvengeMedia:danklinux/openSUSE_Tumbleweed/home:AvengeMedia:danklinux.repo"
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

repo_uri() {
    local alias="$1"

    sudo zypper --non-interactive repos --details \
        | awk -v target="$alias" '$1 == target { print $NF; exit }'
}

repo_enabled() {
    local alias="$1"

    sudo zypper --non-interactive repos --details \
        | awk -v target="$alias" '
            $1 == target {
                for (i = 1; i <= NF; i++) {
                    if ($i == "Yes") {
                        print "yes"
                        exit
                    }
                }
                print "no"
                exit
            }
        ' \
        | grep -qx "yes"
}

add_repo() {
    local alias="$1"
    local uri="$2"

    if repo_exists "$alias"; then
        log "Repository '$alias' already exists."

        local existing_uri
        existing_uri="$(repo_uri "$alias")"

        if [[ -n "$existing_uri" ]]; then
            log "Existing URI:"
            log "  $existing_uri"
        fi

        # Do not silently replace an existing repository with the
        # same alias but a different URI.
        if [[ -n "$existing_uri" && "$existing_uri" != "$uri" ]]; then
            die "Repository '$alias' already exists with a different URI."
        fi

        log "Ensuring repository '$alias' is enabled and refreshed..."

        sudo zypper \
            --non-interactive \
            modifyrepo \
            --enable \
            --refresh \
            "$alias" >/dev/null

        return 0
    fi

    log "Adding repository '$alias'..."
    log "  $uri"

    sudo zypper \
        --non-interactive \
        --gpg-auto-import-keys \
        addrepo \
        --refresh \
        "$uri" \
        "$alias"

    log "[ok] Repository '$alias' added."
}

# ------------------------------------------------------------
# Configure repositories
# ------------------------------------------------------------

command -v zypper >/dev/null 2>&1 \
    || die "zypper is not available."

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

log "Verifying configured repositories..."

for alias in "${REPO_ALIASES[@]}"; do
    if ! repo_exists "$alias"; then
        die "Repository '$alias' was not found after configuration."
    fi

    if ! repo_enabled "$alias"; then
        die "Repository '$alias' is not enabled."
    fi

    log "[ok] Repository '$alias' is present and enabled."
done

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log ""
log "Configured repositories:"
sudo zypper repos

log ""
log "Repository stage completed successfully."

exit 0