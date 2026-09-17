#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring Zsh environment..."

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

command -v zsh >/dev/null 2>&1 \
    || die "zsh is not installed."

command -v git >/dev/null 2>&1 \
    || die "git is not installed."

command -v curl >/dev/null 2>&1 \
    || die "curl is not installed."

command -v unzip >/dev/null 2>&1 \
    || die "unzip is not installed."

command -v fc-cache >/dev/null 2>&1 \
    || die "fontconfig is not installed."

ZSH_PATH="$(command -v zsh)"
ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

log "Zsh: $ZSH_PATH"

# ------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------

if [[ -d "$ZSH_DIR" ]]; then
    log "[ok] Oh My Zsh is already installed."
else
    log "Installing Oh My Zsh..."

    KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended

    [[ -d "$ZSH_DIR" ]] \
        || die "Oh My Zsh installation failed."

    log "[ok] Oh My Zsh installed."
fi

# ------------------------------------------------------------
# Powerlevel10k
# ------------------------------------------------------------

if [[ -d "$P10K_DIR" ]]; then
    log "[ok] Powerlevel10k is already installed."
else
    log "Installing Powerlevel10k..."

    mkdir -p "$(dirname "$P10K_DIR")"

    git clone --depth=1 \
        https://github.com/romkatv/powerlevel10k.git \
        "$P10K_DIR"

    [[ -d "$P10K_DIR" ]] \
        || die "Powerlevel10k installation failed."

    log "[ok] Powerlevel10k installed."
fi

# ------------------------------------------------------------
# Annotation Mono Nerd Font
# ------------------------------------------------------------

FONT_VERSION="3.5.1"
FONT_NAME="AnnotationMono"
FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip"

if fc-list | grep -qi "Annotation Mono"; then
    log "[ok] Annotation Mono Nerd Font is already installed."
else
    log "Installing Annotation Mono Nerd Font..."

    TEMP_DIR="$(mktemp -d)"

    cleanup_font_install() {
        rm -rf "$TEMP_DIR"
    }

    trap cleanup_font_install EXIT

    FONT_ZIP="$TEMP_DIR/${FONT_NAME}.zip"

    curl -fL "$FONT_URL" -o "$FONT_ZIP"

    mkdir -p "$FONT_DIR"

    unzip -q "$FONT_ZIP" -d "$FONT_DIR"

    fc-cache -f "$HOME/.local/share/fonts"

    if fc-list | grep -qi "Annotation Mono"; then
        log "[ok] Annotation Mono Nerd Font installed."
    else
        die "Annotation Mono Nerd Font installation failed."
    fi

    trap - EXIT
    cleanup_font_install
}

# ------------------------------------------------------------
# Zsh configuration
# ------------------------------------------------------------

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

MANAGED_START="# >>> Hyprland-Canvas managed configuration >>>"
MANAGED_END="# <<< Hyprland-Canvas managed configuration <<<"

log "Configuring Zsh: $ZSHRC"

if [[ ! -f "$ZSHRC" ]]; then
    log "No existing .zshrc found; creating one."

    cat > "$ZSHRC" <<EOF
# Hyprland-Canvas Zsh configuration

export ZSH="\$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    sudo
    extract
)

source "\$ZSH/oh-my-zsh.sh"

$MANAGED_START

export PATH="\$HOME/.cargo/bin:\$PATH"

eval "\$(zoxide init zsh)"

[[ -f "\$HOME/.p10k.zsh" ]] && source "\$HOME/.p10k.zsh"

$MANAGED_END
EOF

    log "[ok] Created $ZSHRC."

else
    log "Existing .zshrc found; preserving existing configuration."

    if grep -Fqx "$MANAGED_START" "$ZSHRC"; then
        log "[ok] Hyprland-Canvas configuration block already exists."

    else
        log "Adding Hyprland-Canvas configuration block..."

        cat >> "$ZSHRC" <<EOF

$MANAGED_START

export PATH="\$HOME/.cargo/bin:\$PATH"

eval "\$(zoxide init zsh)"

[[ -f "\$HOME/.p10k.zsh" ]] && source "\$HOME/.p10k.zsh"

$MANAGED_END
EOF

        log "[ok] Hyprland-Canvas configuration block added."
    fi
fi

# ------------------------------------------------------------
# Default shell
# ------------------------------------------------------------

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    log "[ok] Zsh is already the default shell."
else
    log "Setting Zsh as the default shell..."

    chsh -s "$ZSH_PATH"

    NEW_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

    if [[ "$NEW_SHELL" == "$ZSH_PATH" ]]; then
        log "[ok] Zsh is now the default shell."
    else
        die "Failed to set Zsh as the default shell."
    fi
fi

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

log "Shell configuration complete."
log ""
log "Default shell: $ZSH_PATH"
log "Oh My Zsh:     $ZSH_DIR"
log "Powerlevel10k: $P10K_DIR"
log "Font:          Annotation Mono Nerd Font"
log ""
log "Run 'p10k configure' after installation if you want to configure the prompt."

exit 0