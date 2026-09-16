#!/usr/bin/env bash

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 00-preflight.sh
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Starting preflight checks..."

# ------------------------------------------------------------
# Root / required commands
# ------------------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run this installer as root. Run it as your normal user."
fi

command -v sudo >/dev/null 2>&1 \
    || die "sudo is required."

command -v zypper >/dev/null 2>&1 \
    || die "zypper is required. This installer targets openSUSE."

# ------------------------------------------------------------
# OS check
# ------------------------------------------------------------

if [[ ! -r /etc/os-release ]]; then
    die "/etc/os-release was not found."
fi

source /etc/os-release

log "Detected OS: ${PRETTY_NAME:-unknown}"

if [[ "${ID:-}" != "opensuse-tumbleweed" ]]; then
    die "This installer currently supports openSUSE Tumbleweed only."
fi

# ------------------------------------------------------------
# Curl
# ------------------------------------------------------------

if ! command -v curl >/dev/null 2>&1; then
    log "curl is not installed. Installing it now..."

    sudo zypper --non-interactive install curl

    command -v curl >/dev/null 2>&1 \
        || die "Failed to install curl."

    log "curl installed successfully."
else
    log "curl is already installed."
fi

# ------------------------------------------------------------
# Architecture
# ------------------------------------------------------------

ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)
        log "Architecture: x86_64"
        ;;
    *)
        die "Unsupported architecture: $ARCH"
        ;;
esac

# ------------------------------------------------------------
# Session sanity
# ------------------------------------------------------------

if [[ -z "${HOME:-}" ]]; then
    die "HOME is not set."
fi

if [[ "$(id -u)" -lt 1000 ]]; then
    log "Warning: current user has an unusually low UID ($(id -u))."
fi

# ------------------------------------------------------------
# Network
# ------------------------------------------------------------

log "Checking network connectivity..."

if curl -fsSI --max-time 10 https://download.opensuse.org >/dev/null 2>&1; then
    log "Network connectivity check passed."
else
    log "Warning: direct connectivity check to download.opensuse.org failed."
    log "Continuing; zypper will perform the definitive repository connectivity check."
fi

# ------------------------------------------------------------
# Sudo
# ------------------------------------------------------------

log "Checking sudo access..."
sudo -v

# The master installer owns the long-lived sudo keep-alive.
# This stage intentionally does not create another background loop.

# ------------------------------------------------------------
# Project structure
# ------------------------------------------------------------

if [[ ! -d "$PROJECT_DIR/scripts" ]]; then
    die "scripts directory not found: $PROJECT_DIR/scripts"
fi

if [[ ! -f "$PROJECT_DIR/install.sh" ]]; then
    die "install.sh not found at: $PROJECT_DIR/install.sh"
fi

# ------------------------------------------------------------
# Snapper
# ------------------------------------------------------------

if command -v snapper >/dev/null 2>&1; then
    log "Snapper detected."

    if sudo snapper list-configs >/dev/null 2>&1; then
        log "Snapper appears to be configured."
    else
        log "Snapper is installed but no usable configuration was detected."
    fi
else
    log "Snapper is not installed. Continuing without Snapper."
fi

# ------------------------------------------------------------
# Existing session detection
# ------------------------------------------------------------

if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
    log "Current desktop: ${XDG_CURRENT_DESKTOP}"
fi

if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
    log "Current session type: ${XDG_SESSION_TYPE}"
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log "Preflight checks passed."
log "Project directory: $PROJECT_DIR"
log "User: $USER"
log "Architecture: $ARCH"
log "OS: ${PRETTY_NAME:-unknown}"

exit 0