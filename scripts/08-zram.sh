#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log "Configuring zram..."

ZRAM_CONF="/etc/systemd/zram-generator.conf"

if ! command -v rpm >/dev/null 2>&1; then
log "[warn] rpm is unavailable; cannot verify zram-generator."
exit 0
fi

if ! rpm -q zram-generator >/dev/null 2>&1; then
log "[warn] zram-generator is not installed; skipping configuration."
exit 0
fi

if [[ -f "$ZRAM_CONF" ]]; then
log "[ok] $ZRAM_CONF already exists; preserving it."
else
log "Creating $ZRAM_CONF..."

sudo tee "$ZRAM_CONF" >/dev/null <<'EOF'

[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

sudo systemctl daemon-reload

log "[ok] zram configuration created."

fi

exit 0