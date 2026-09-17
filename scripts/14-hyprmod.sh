#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Optional component: HyprMod"

# ------------------------------------------------------------
# Optional component gate
# ------------------------------------------------------------

if [[ "${INSTALL_OPTIONAL:-0}" != "1" ]]; then
    log "Skipping HyprMod."
    exit 0
fi

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

command -v curl >/dev/null 2>&1 \
    || die "curl is required to install HyprMod."

# ------------------------------------------------------------
# Existing installation
# ------------------------------------------------------------

if command -v hyprmod >/dev/null 2>&1; then
    log "[ok] HyprMod is already installed."
else
    log "Installing HyprMod..."

    curl -LsSf \
        https://raw.githubusercontent.com/BlueManCZ/hyprmod/main/install.sh \
        | sh

    log "[ok] HyprMod installer completed."
fi

# ------------------------------------------------------------
# Locate HyprMod
# ------------------------------------------------------------

if command -v hyprmod >/dev/null 2>&1; then
    log "[ok] HyprMod is available on PATH."
else
    # uv installs tool executables into its XDG-standard bin directory.
    # Discover it without modifying shell configuration.
    if command -v uv >/dev/null 2>&1; then
        UV_TOOL_BIN="$(uv tool dir --bin 2>/dev/null || true)"

        if [[ -n "$UV_TOOL_BIN" && -d "$UV_TOOL_BIN" ]]; then
            export PATH="$UV_TOOL_BIN:$PATH"
        fi
    fi
fi

if ! command -v hyprmod >/dev/null 2>&1; then
    die "HyprMod was installed, but the hyprmod executable could not be found."
fi

log "[ok] HyprMod executable verified:"
log "  $(command -v hyprmod)"

# ------------------------------------------------------------
# Desktop entry
# ------------------------------------------------------------

log "Registering HyprMod desktop entry..."

if hyprmod --install; then
    log "[ok] HyprMod desktop entry registered."
else
    die "HyprMod desktop-entry registration failed."
fi

log "HyprMod configuration complete."

exit 0