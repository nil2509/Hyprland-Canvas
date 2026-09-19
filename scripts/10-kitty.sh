#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring Kitty..."

# ------------------------------------------------------------
# Required command
# ------------------------------------------------------------

command -v kitty >/dev/null 2>&1 \
    || die "Kitty is not installed."

# ------------------------------------------------------------
# Configuration paths
# ------------------------------------------------------------

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

KITTY_DIR="$XDG_CONFIG_HOME/kitty"
KITTY_CONF="$KITTY_DIR/kitty.conf"

mkdir -p "$KITTY_DIR"

# ------------------------------------------------------------
# Kitty configuration
# ------------------------------------------------------------

if [[ ! -f "$KITTY_CONF" ]]; then

    log "No existing Kitty configuration found."
    log "Creating:"
    log "  $KITTY_CONF"

    cat > "$KITTY_CONF" <<'EOF'
# Font configured by Hyprland-Canvas

font_family AnnotationMono Nerd Font
EOF

    log "[ok] Created Kitty configuration."

elif grep -Eq \
    '^[[:space:]]*font_family[[:space:]]+AnnotationMono Nerd Font([[:space:]]*)$' \
    "$KITTY_CONF"; then

    log "[ok] Annotation Mono Nerd Font is already configured."

else

    log "Existing Kitty configuration found."
    log "Preserving existing configuration."

    cat >> "$KITTY_CONF" <<'EOF'

# Font configured by Hyprland-Canvas
font_family AnnotationMono Nerd Font
EOF

    log "[ok] Added Annotation Mono Nerd Font to existing Kitty configuration."
fi

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

if grep -Eq \
    '^[[:space:]]*font_family[[:space:]]+AnnotationMono Nerd Font([[:space:]]*)$' \
    "$KITTY_CONF"; then

    log "[ok] Kitty font configuration verified."

else
    die "Kitty font configuration could not be verified."
fi

log "Kitty configuration complete."

exit 0