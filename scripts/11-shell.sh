#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring Zsh environment..."

command -v zsh >/dev/null 2>&1 || die "zsh is not installed."
command -v git >/dev/null 2>&1 || die "git is not installed."
command -v curl >/dev/null 2>&1 || die "curl is not installed."
command -v fc-cache >/dev/null 2>&1 || die "fontconfig is not installed."

ZSH_PATH="$(command -v zsh)"
ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

log "Zsh: $ZSH_PATH"

# ------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------

if [[ -d "$ZSH_DIR" ]]; then
    log "Oh My Zsh is already installed."
else
    log "Installing Oh My Zsh..."

    KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended

    [[ -d "$ZSH_DIR" ]] \
        || die "Oh My Zsh installation failed."

    log "Oh My Zsh installed."
fi

# ------------------------------------------------------------
# Powerlevel10k
# ------------------------------------------------------------

if [[ -d "$P10K_DIR" ]]; then
    log "Powerlevel10k is already installed."
else
    log "Installing Powerlevel10k..."

    git clone --depth=1 \
        https://github.com/romkatv/powerlevel10k.git \
        "$P10K_DIR"

    log "Powerlevel10k installed."
fi

# ------------------------------------------------------------
# Annotation Mono Nerd Font
# ------------------------------------------------------------

FONT_VERSION="3.5.1"
FONT_NAME="AnnotationMono"
FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip"

if fc-list | grep -qi "Annotation Mono"; then
    log "Annotation Mono Nerd Font is already installed."
else
    log "Installing Annotation Mono Nerd Font..."

    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    FONT_ZIP="$TEMP_DIR/${FONT_NAME}.zip"

    curl -fL "$FONT_URL" -o "$FONT_ZIP"

    mkdir -p "$FONT_DIR"
    unzip -q "$FONT_ZIP" -d "$FONT_DIR"

    fc-cache -f "$HOME/.local/share/fonts"

    if fc-list | grep -qi "Annotation Mono"; then
        log "Annotation Mono Nerd Font installed."
    else
        die "Annotation Mono Nerd Font installation failed."
    fi
fi

# ------------------------------------------------------------
# Zsh configuration
# ------------------------------------------------------------

ZSHRC="$HOME/.zshrc"

log "Configuring ~/.zshrc..."

cat > "$ZSHRC" <<'EOF'
# ------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    sudo
    extract
)

source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------
# Cargo
# ------------------------------------------------------------

export PATH="$HOME/.cargo/bin:$PATH"

# ------------------------------------------------------------
# zoxide
# ------------------------------------------------------------

eval "$(zoxide init zsh)"

# ------------------------------------------------------------
# Powerlevel10k
# ------------------------------------------------------------

[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
EOF

log "Zsh configuration written."

# ------------------------------------------------------------
# Default shell
# ------------------------------------------------------------

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    log "Zsh is already the default shell."
else
    log "Setting Zsh as the default shell..."

    chsh -s "$ZSH_PATH"

    NEW_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

    if [[ "$NEW_SHELL" == "$ZSH_PATH" ]]; then
        log "Zsh is now the default shell."
    else
        die "Failed to set Zsh as the default shell."
    fi
fi

log "Shell configuration complete."
log ""
log "Default shell: $ZSH_PATH"
log "Oh My Zsh:     $ZSH_DIR"
log "Powerlevel10k: $P10K_DIR"
log "Font:          Annotation Mono Nerd Font"
log ""
log "Run 'p10k configure' after installation to create your Powerlevel10k prompt configuration."

exit 0