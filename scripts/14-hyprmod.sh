#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log "Optional component: HyprMod"

if [[ "${INSTALL_OPTIONAL:-0}" != "1" ]]; then
    log "Skipping HyprMod."
    exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
    log "[skipped] uv is not installed."
    log "Install uv separately if HyprMod is desired."
    exit 0
fi

if command -v hyprmod >/dev/null 2>&1; then
    log "[ok] HyprMod is already installed."
else
    log "Installing HyprMod with uv..."

    if ! uv tool install git+https://github.com/BlueManCZ/hyprmod.git; then
        log "[warn] HyprMod installation failed; continuing."
        exit 0
    fi

    log "[ok] HyprMod installed."
fi

# Persist uv's tool executable directory in the user's shell configuration.
log "Configuring uv tool PATH..."

if uv tool update-shell >/dev/null 2>&1; then
    log "[ok] uv tool executable directory configured for future shells."
else
    log "[warn] Could not update shell configuration for uv tools."
fi

# uv may place tool executables in a directory that is not currently
# available in PATH, so discover it for this invocation.
UV_TOOL_BIN="$(uv tool dir --bin 2>/dev/null || true)"

if [[ -n "$UV_TOOL_BIN" && -d "$UV_TOOL_BIN" ]]; then
    export PATH="$UV_TOOL_BIN:$PATH"
fi

if ! command -v hyprmod >/dev/null 2>&1; then
    log "[warn] HyprMod is installed but is not currently on PATH."
    log "A new shell may be required before HyprMod becomes available."
    exit 0
fi

log "Registering HyprMod desktop entry..."

if hyprmod --install; then
    log "[ok] HyprMod desktop entry registered."
else
    log "[warn] HyprMod installed, but desktop-entry registration failed."
fi

exit 0