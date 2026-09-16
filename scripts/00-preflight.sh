#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# openSUSE Hyprland Desktop Bootstrap
# 00-preflight.sh
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

log() {
    printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

log "Starting preflight checks..."

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    die "Do not run this installer as root. Run it as your normal user."
fi

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

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

# shellcheck disable=SC1091
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

    command -v curl >/dev/null 2>&1 || die "Failed to install curl."
    log "curl installed successfully."
else
    log "curl is already installed."
fi

# ------------------------------------------------------------
# Architecture check
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
# Network check
# ------------------------------------------------------------

log "Checking network connectivity..."

if ! curl -fsSI --max-time 10 https://download.opensuse.org >/dev/null; then
    die "Could not reach download.opensuse.org. Check your internet connection."
fi

# ------------------------------------------------------------
# Sudo check
# ------------------------------------------------------------

log "Checking sudo access..."

sudo -v

# Keep sudo credentials alive while this stage runs.
(
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done
) 2>/dev/null &

SUDO_KEEPALIVE_PID=$!

cleanup() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

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
# Snapper availability
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