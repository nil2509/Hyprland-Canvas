#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring Cargo-installed tools..."

command -v cargo >/dev/null 2>&1 \
    || die "cargo is not installed."

CARGO_BIN_DIR="${CARGO_HOME:-$HOME/.cargo}/bin"

mkdir -p "$CARGO_BIN_DIR"

install_cargo_package() {
    local package="$1"
    local binary="$2"

    if [[ -x "$CARGO_BIN_DIR/$binary" ]]; then
        log "$binary is already installed."
        return
    fi

    log "Installing Cargo package: $package"
    cargo install "$package"
}

install_cargo_package "pokeget" "pokeget"
install_cargo_package "zoxide" "zoxide"
install_cargo_package "matugen" "matugen"

log "Cargo-installed tools configured."

exit 0