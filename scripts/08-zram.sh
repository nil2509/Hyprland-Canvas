#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/common.sh"

log "Configuring zram..."

# ------------------------------------------------------------
# Required commands
# ------------------------------------------------------------

command -v rpm >/dev/null 2>&1 \
    || die "rpm is not available."

command -v systemctl >/dev/null 2>&1 \
    || die "systemctl is not available."

# ------------------------------------------------------------
# Verify zram-generator
# ------------------------------------------------------------

if ! rpm -q zram-generator >/dev/null 2>&1; then
    die "zram-generator is not installed."
fi

log "[ok] zram-generator is installed."

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

ZRAM_CONF="/etc/systemd/zram-generator.conf"

if [[ -f "$ZRAM_CONF" ]]; then
    log "[ok] Existing zram configuration found:"
    log "  $ZRAM_CONF"
    log "Preserving existing configuration."

else
    log "Creating zram configuration:"
    log "  $ZRAM_CONF"

    sudo tee "$ZRAM_CONF" >/dev/null <<'EOF'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF

    log "[ok] zram configuration created."
fi

# ------------------------------------------------------------
# Verify configuration
# ------------------------------------------------------------

if [[ ! -f "$ZRAM_CONF" ]]; then
    die "zram configuration was not created: $ZRAM_CONF"
fi

if grep -q '^zram-size = ram / 2$' "$ZRAM_CONF"; then
    log "[ok] zram size is configured to half of system RAM."
else
    log "[warn] Existing zram configuration uses a different zram-size."
fi

if grep -q '^compression-algorithm = zstd$' "$ZRAM_CONF"; then
    log "[ok] zram compression is configured to zstd."
else
    log "[warn] Existing zram configuration uses a different compression algorithm."
fi

# ------------------------------------------------------------
# Regenerate systemd units
# ------------------------------------------------------------

log "Reloading systemd configuration..."

sudo systemctl daemon-reload

log "[ok] systemd configuration reloaded."

# ------------------------------------------------------------
# Runtime status
# ------------------------------------------------------------

if command -v zramctl >/dev/null 2>&1; then
    if zramctl /dev/zram0 >/dev/null 2>&1; then
        log "[ok] /dev/zram0 is currently available."
    else
        log "[info] /dev/zram0 is not currently active."
        log "       It will be created by zram-generator during boot."
    fi
else
    log "[warn] zramctl is not available; runtime zram status cannot be checked."
fi

log "zram configuration complete."

exit 0