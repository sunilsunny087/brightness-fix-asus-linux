#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Brightness Configuration Restoration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root"
    echo "Run: sudo /usr/local/bin/brightness-restore.sh"
    exit 1
fi

# Restore wrapper if missing
if [ ! -f /usr/bin/supergfxctl-original ]; then
    if [ -f /usr/bin/supergfxctl ]; then
        echo "📦 Backing up current supergfxctl..."
        mv /usr/bin/supergfxctl /usr/bin/supergfxctl-original
    fi
fi

if [ -f /usr/local/bin/supergfxctl-wrapper.sh ]; then
    echo "📝 Restoring wrapper..."
    cp /usr/local/bin/supergfxctl-wrapper.sh /usr/bin/supergfxctl
    chmod +x /usr/bin/supergfxctl
    echo "✓ Wrapper restored"
else
    echo "❌ Wrapper backup not found at /usr/local/bin/supergfxctl-wrapper.sh"
    echo "You'll need to recreate the wrapper manually"
    exit 1
fi

# Verify/restore base cmdline
if [ ! -f /etc/kernel/cmdline ]; then
    echo "⚠️  /etc/kernel/cmdline missing! Creating..."
    echo "nvme_load=YES nowatchdog rw root=UUID=fb50d372-4a94-4195-aa8a-37484e05067f nvidia_drm.modeset=1 nvidia.NVreg_EnableBacklightHandler=1" > /etc/kernel/cmdline
    echo "✓ Created /etc/kernel/cmdline"
fi

# Restore udev rules
if [ ! -f /etc/udev/rules.d/90-backlight.rules ]; then
    echo "📝 Restoring udev rules..."
    cat > /etc/udev/rules.d/90-backlight.rules << 'EOF'
# Permissions for nvidia_wmi_ec_backlight (Hybrid/Integrated mode)
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="nvidia_wmi_ec_backlight", \
  RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"

# Permissions for nvidia_0 (dGPU mode)
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="nvidia_0", \
  RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF
    udevadm control --reload-rules
    echo "✓ Udev rules restored"
fi

# Sync with current GPU mode
GPU_MODE=$(supergfxctl -g 2>/dev/null)
echo ""
echo "🔄 Syncing with current GPU mode: $GPU_MODE"
supergfxctl -m "$GPU_MODE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Restoration complete!"
echo "Run: brightness-check.sh to verify"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
