#!/bin/bash

ASUSCTLTRAY="/usr/local/bin/asusctltray"
BACKUP="/usr/local/bin/asusctltray.original"
PATCHED="/usr/local/bin/asusctltray.patched"

echo "Patching asusctltray for brightness fix..."

# Backup original if not already backed up
if [ ! -f "$BACKUP" ]; then
    cp "$ASUSCTLTRAY" "$BACKUP"
    echo "✓ Created backup"
fi

# Check if already patched
if grep -q "cli_mode_map" "$ASUSCTLTRAY"; then
    echo "✓ Already patched"
    exit 0
fi

# Check if pre-patched version exists
if [ ! -f "$PATCHED" ]; then
    echo "⚠ Pre-patched version not found at $PATCHED"
    echo "  Please run: sudo cp /usr/local/bin/asusctltray /usr/local/bin/asusctltray.patched"
    echo "  after manually applying the patches"
    exit 1
fi

# Replace with patched version
cp "$PATCHED" "$ASUSCTLTRAY"
echo "✓ Restored patched version"

# Restart tray if running
if pgrep -f "asusctltray" > /dev/null; then
    pkill -f asusctltray
    nohup asusctltray >/dev/null 2>&1 &
    echo "✓ Restarted asusctltray"
fi

echo "✓ Patching complete"
