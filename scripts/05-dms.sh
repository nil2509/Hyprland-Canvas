#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-preflight.sh"

log "Configuring DankMaterialShell..."

command -v dms >/dev/null 2>&1 || die "dms is not installed."
command -v quickshell >/dev/null 2>&1 || die "quickshell is not installed."
command -v kitty >/dev/null 2>&1 || die "kitty is not installed."

log "Configuring user environment..."

mkdir -p "$HOME/.config/environment.d"

cat > "$HOME/.config/environment.d/90-dms.conf" <<'EOF'
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=gtk3
ELECTRON_OZONE_PLATFORM_HINT=auto
TERMINAL=kitty
EOF

log "Running DMS headless setup..."

dms setup headless \
    --compositor hyprland \
    --terminal kitty \
    --skip-existing

log "Configuring Hyprland systemd session target..."

mkdir -p "$HOME/.config/systemd/user"

cat > "$HOME/.config/systemd/user/hyprland-session.target" <<'EOF'
[Unit]
Description=Hyprland Session Target
Requires=graphical-session.target
After=graphical-session.target
EOF

systemctl --user daemon-reload

log "Connecting DMS to the Hyprland session target..."

systemctl --user add-wants hyprland-session.target dms.service

log "DankMaterialShell configuration complete."

exit 0