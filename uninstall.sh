#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗑️  Brightness Fix - Complete Uninstallation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root"
    echo "Run: sudo bash uninstall.sh"
    exit 1
fi

echo "⚠️  This will remove all brightness fix modifications"
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Removing modifications..."

# Restore original supergfxctl
if [ -f /usr/bin/supergfxctl-original ]; then
    rm -f /usr/bin/supergfxctl
    mv /usr/bin/supergfxctl-original /usr/bin/supergfxctl
    echo "✓ Restored original supergfxctl"
fi

# Remove wrapper backup
rm -f /usr/local/bin/supergfxctl-wrapper.sh
echo "✓ Removed wrapper backup"

# Remove udev rules
rm -f /etc/udev/rules.d/90-backlight.rules
udevadm control --reload-rules
echo "✓ Removed udev rules"

# Remove pacman hook
rm -f /etc/pacman.d/hooks/supergfxctl-wrapper.hook
echo "✓ Removed pacman hook"

# Remove monitoring scripts
rm -f /usr/local/bin/brightness-check.sh
rm -f /usr/local/bin/brightness-restore.sh
echo "✓ Removed monitoring scripts"

echo ""
echo "⚠️  Note: /etc/kernel/cmdline was NOT removed"
echo "   You may want to manually review and edit it"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Uninstallation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Reboot to complete: sudo reboot"
