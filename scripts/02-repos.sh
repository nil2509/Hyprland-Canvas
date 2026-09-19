#!/usr/bin/env bash

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 02-repos.sh
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring additional repositories..."

# ------------------------------------------------------------
# Repository definitions
# ------------------------------------------------------------

REPO_ALIASES=(
    "home_AvengeMedia_danklinux"
)

declare -A REPO_URLS=(
    [home_AvengeMedia_danklinux]="https://download.opensuse.org/repositories/home:/AvengeMedia:/danklinux/openSUSE_Tumbleweed/"
)

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

repo_exists() {
    local target="$1"

    sudo zypper repos --details 2>/dev/null |
        awk -F'|' -v target="$target" '
            NR > 2 {
                alias = $2
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", alias)

                if (alias == target) {
                    found = 1
                    exit
                }
            }
            END {
                exit !found
            }
        '
}

repo_uri() {
    local target="$1"

    sudo zypper repos --details 2>/dev/null |
        awk -F'|' -v target="$target" '
            NR > 2 {
                for (i = 1; i <= NF; i++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
                }

                if ($2 == target) {
                    print $10
                    exit
                }
            }
        '
}

repo_enabled() {
    local target="$1"

    sudo zypper repos --details 2>/dev/null |
        awk -F'|' -v target="$target" '
            NR > 2 {
                for (i = 1; i <= NF; i++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
                }

                if ($2 == target) {
                    if ($4 == "Yes") {
                        found = 1
                    }
                    exit
                }
            }
            END {
                exit !found
            }
        '
}

add_repo() {
    local alias="$1"
    local uri="$2"

    # --------------------------------------------------------
    # Existing repository
    # --------------------------------------------------------

    if repo_exists "$alias"; then
        log "Repository '$alias' already exists."

        local existing_uri
        existing_uri="$(repo_uri "$alias")"

        if [[ -n "$existing_uri" ]]; then
            log "Existing URI:"
            log "  $existing_uri"
        fi

        # Do not silently replace a repository with the same
        # alias but a different URI.
        if [[ -n "$existing_uri" && "$existing_uri" != "$uri" ]]; then
            die "Repository '$alias' already exists with a different URI."
        fi

        log "Ensuring repository '$alias' is enabled and refreshed..."

        sudo zypper \
            --non-interactive \
            modifyrepo \
            --enable \
            --refresh \
            "$alias"

        return 0
    fi

    # --------------------------------------------------------
    # New repository
    # --------------------------------------------------------

    log "Adding repository '$alias'..."
    log "  $uri"

    sudo zypper \
        --non-interactive \
        --gpg-auto-import-keys \
        addrepo \
        --refresh \
        --alias "$alias" \
        "$uri"

    log "[ok] Repository '$alias' added."
}

# ------------------------------------------------------------
# Preconditions
# ------------------------------------------------------------

command -v zypper >/dev/null 2>&1 \
    || die "zypper is not available."

# ------------------------------------------------------------
# Configure repositories
# ------------------------------------------------------------

for alias in "${REPO_ALIASES[@]}"; do

    if [[ -z "${REPO_URLS[$alias]+x}" ]]; then
        die "No repository URI defined for alias '$alias'."
    fi

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

    if [[ -z "${REPO_URLS[$alias]+x}" ]]; then
        die "No repository URI defined for alias '$alias'."
    fi

    if ! repo_exists "$alias"; then
        die "Repository '$alias' was not found after configuration."
    fi

    if ! repo_enabled "$alias"; then
        die "Repository '$alias' is not enabled."
    fi

    actual_uri=""
    actual_uri="$(repo_uri "$alias")"

    if [[ -z "$actual_uri" ]]; then
        die "Repository '$alias' has no detectable URI."
    fi

    if [[ "$actual_uri" != "${REPO_URLS[$alias]}" ]]; then
        die "Repository '$alias' has an unexpected URI:
        Expected: ${REPO_URLS[$alias]}
        Actual:   $actual_uri"
    fi

    log "[ok] Repository '$alias' is present, enabled, and has the expected URI."
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