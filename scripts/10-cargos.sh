#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring Cargo-installed tools..."

# ------------------------------------------------------------
# Required command
# ------------------------------------------------------------

command -v cargo >/dev/null 2>&1 \
    || die "cargo is not installed."

# ------------------------------------------------------------
# Cargo environment
# ------------------------------------------------------------

CARGO_BIN_DIR="${CARGO_HOME:-$HOME/.cargo}/bin"

mkdir -p "$CARGO_BIN_DIR"

export PATH="$CARGO_BIN_DIR:$PATH"

log "Cargo binary directory:"
log "  $CARGO_BIN_DIR"

# ------------------------------------------------------------
# Install helper
# ------------------------------------------------------------

install_cargo_package() {
    local package="$1"
    local binary="$2"

    if [[ -x "$CARGO_BIN_DIR/$binary" ]]; then
        log "[ok] $binary is already installed."
        return 0
    fi

    log "Installing Cargo package: $package..."

    if cargo install "$package"; then
        log "[ok] Installed $package."
    else
        die "Failed to install Cargo package: $package"
    fi

    if [[ -x "$CARGO_BIN_DIR/$binary" ]]; then
        log "[ok] Verified binary: $CARGO_BIN_DIR/$binary"
    else
        die "Cargo reported success, but binary was not found: $CARGO_BIN_DIR/$binary"
    fi
}

# ------------------------------------------------------------
# Required Cargo tools
# ------------------------------------------------------------

install_cargo_package "pokeget" "pokeget"
install_cargo_package "zoxide" "zoxide"
install_cargo_package "matugen" "matugen"

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

log "Verifying Cargo-installed tools..."

CARGO_BINARIES=(
    pokeget
    zoxide
    matugen
)

for binary in "${CARGO_BINARIES[@]}"; do
    if [[ -x "$CARGO_BIN_DIR/$binary" ]]; then
        log "[ok] $binary is available."
    else
        die "Required Cargo binary is missing: $binary"
    fi
done

log "Cargo-installed tools configured successfully."

exit 0