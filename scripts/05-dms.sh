#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring DankMaterialShell..."

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

command -v dms >/dev/null 2>&1 \
    || die "dms is not installed."

command -v quickshell >/dev/null 2>&1 \
    || die "quickshell is not installed."

command -v kitty >/dev/null 2>&1 \
    || die "kitty is not installed."

# ------------------------------------------------------------
# User environment
# ------------------------------------------------------------

log "Configuring DMS user environment..."

DMS_ENV_DIR="$HOME/.config/environment.d"
DMS_ENV_FILE="$DMS_ENV_DIR/90-dms.conf"

mkdir -p "$DMS_ENV_DIR"

if [[ -f "$DMS_ENV_FILE" ]]; then
    log "Existing DMS environment file found; preserving it."
else
    cat > "$DMS_ENV_FILE" <<'EOF'
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=gtk3
ELECTRON_OZONE_PLATFORM_HINT=auto
TERMINAL=kitty
EOF

    log "Created DMS environment configuration:"
    log "  $DMS_ENV_FILE"
fi

# ------------------------------------------------------------
# DMS setup
# ------------------------------------------------------------

log "Running DMS headless setup..."

dms setup headless \
    --compositor hyprland \
    --terminal kitty \
    --skip-existing

# ------------------------------------------------------------
# Verify DMS Hyprland configuration
# ------------------------------------------------------------

DMS_HYPR_DIR="$HOME/.config/hypr/dms"

if [[ -d "$DMS_HYPR_DIR" ]]; then
    log "DMS Hyprland configuration directory exists:"
    log "  $DMS_HYPR_DIR"
else
    die "DMS Hyprland configuration directory was not created: $DMS_HYPR_DIR"
fi

# ------------------------------------------------------------
# Verify generated configuration files
# ------------------------------------------------------------

DMS_HYPR_FILES=(
    binds.conf
    colors.conf
    layout.conf
    outputs.conf
    cursor.conf
    windowrules.conf
)

for file in "${DMS_HYPR_FILES[@]}"; do
    if [[ -f "$DMS_HYPR_DIR/$file" ]]; then
        log "[ok] DMS generated: $file"
    else
        log "[warn] DMS configuration file was not generated: $file"
    fi
done

log "DankMaterialShell configuration complete."

exit 0