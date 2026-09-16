#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log "Configuring Kitty..."

KITTY_DIR="$HOME/.config/kitty"
KITTY_CONF="$KITTY_DIR/kitty.conf"

mkdir -p "$KITTY_DIR"

if [[ ! -f "$KITTY_CONF" ]]; then
cat > "$KITTY_CONF" <<'EOF'

# Font configured by Hyprland-Canvas

font_family AnnotationMono Nerd Font
EOF
log "[ok] Created Kitty configuration."
elif grep -Eq '^[[:space:]]*font_family[[:space:]]+AnnotationMono Nerd Font([[:space:]]*)$' "$KITTY_CONF"; then
log "[ok] Annotation Mono Nerd Font is already configured."
else
printf '\n# Font configured by Hyprland-Canvas\nfont_family AnnotationMono Nerd Font\n' >> "$KITTY_CONF"
log "[ok] Added Annotation Mono Nerd Font to existing Kitty configuration."
fi

log "Kitty configured."
exit 0