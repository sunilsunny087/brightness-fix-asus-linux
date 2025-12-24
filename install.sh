#!/bin/bash

# Arch Linux Brightness Fix Installer
# For ASUS laptops with NVIDIA dGPU + Intel iGPU using supergfxctl
# Version 1.0

set -e  # Exit on any error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "              Arch Linux Brightness Fix Installer v1.0                "
echo "          For ASUS Laptops with NVIDIA dGPU + Intel iGPU              "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root"
    echo "Run: sudo bash install.sh"
    exit 1
fi

# Get the actual user (not root)
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
else
    echo "❌ Could not determine actual user. Run with sudo, not as root."
    exit 1
fi

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📋 Prerequisites Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for required packages
echo -n "Checking for supergfxctl... "
if command -v supergfxctl &> /dev/null; then
    echo "✓ Found"
else
    echo "✗ Not found"
    echo ""
    echo "❌ supergfxctl is not installed!"
    echo "Install it first: yay -S supergfxctl"
    exit 1
fi

echo -n "Checking for asusctl... "
if command -v asusctl &> /dev/null; then
    echo "✓ Found"
else
    echo "⚠ Not found (optional)"
fi

echo -n "Checking for systemd-boot... "
if [ -f /usr/lib/systemd/boot/efi/systemd-bootx64.efi ]; then
    echo "✓ Found"
else
    echo "⚠ Not found - this installer is designed for systemd-boot"
    read -p "Continue anyway? (yes/no): " continue
    if [ "$continue" != "yes" ]; then
        exit 1
    fi
fi

echo -n "Checking for reinstall-kernels... "
if command -v reinstall-kernels &> /dev/null; then
    echo "✓ Found"
else
    echo "✗ Not found"
    echo ""
    echo "❌ reinstall-kernels is required but not found!"
    exit 1
fi

echo ""
echo "📝 System Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "User: $ACTUAL_USER"
echo "Current GPU mode: $(supergfxctl -g 2>/dev/null || echo 'Unknown')"
echo ""

# Detect root partition UUID
ROOT_UUID=$(findmnt -no UUID /)
if [ -z "$ROOT_UUID" ]; then
    echo "❌ Could not detect root partition UUID"
    echo "Please enter your root partition UUID manually:"
    read -p "UUID: " ROOT_UUID
fi
echo "Root partition UUID: $ROOT_UUID"
echo ""

read -p "Proceed with installation? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "🚀 Starting Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Create base kernel cmdline
echo "📝 [1/7] Creating base kernel command line..."
cat > /etc/kernel/cmdline << EOF
nvme_load=YES nowatchdog rw root=UUID=$ROOT_UUID nvidia_drm.modeset=1 nvidia.NVreg_EnableBacklightHandler=1
EOF
echo "✓ Created /etc/kernel/cmdline"

# Step 2: Backup original supergfxctl
echo ""
echo "📦 [2/7] Setting up supergfxctl wrapper..."
if [ -f /usr/bin/supergfxctl ] && [ ! -f /usr/bin/supergfxctl-original ]; then
    cp /usr/bin/supergfxctl /usr/bin/supergfxctl-original
    echo "✓ Backed up original supergfxctl"
fi

# Step 3: Install wrapper script
echo "Installing wrapper script..."
cp "$INSTALL_DIR/src/supergfxctl-wrapper.sh" /usr/bin/supergfxctl
chmod +x /usr/bin/supergfxctl
echo "✓ Installed wrapper"

# Step 4: Create wrapper backup
cp /usr/bin/supergfxctl /usr/local/bin/supergfxctl-wrapper.sh
echo "✓ Created wrapper backup"

# Step 5: Install udev rules
echo ""
echo "🔧 [3/7] Installing udev rules..."
cp "$INSTALL_DIR/src/90-backlight.rules" /etc/udev/rules.d/90-backlight.rules
udevadm control --reload-rules
echo "✓ Installed and reloaded udev rules"

# Step 6: Add user to video group
echo ""
echo "👤 [4/7] Adding user to video group..."
usermod -aG video "$ACTUAL_USER"
echo "✓ Added $ACTUAL_USER to video group"

# Step 7: Install pacman hook
echo ""
echo "🪝 [5/7] Installing pacman hook..."
mkdir -p /etc/pacman.d/hooks
cp "$INSTALL_DIR/src/supergfxctl-wrapper.hook" /etc/pacman.d/hooks/supergfxctl-wrapper.hook
echo "✓ Installed pacman hook"

# Step 8: Install monitoring tools
echo ""
echo "🔍 [6/7] Installing monitoring tools..."
cp "$INSTALL_DIR/src/brightness-check.sh" /usr/local/bin/brightness-check.sh
chmod +x /usr/local/bin/brightness-check.sh
echo "✓ Installed brightness-check.sh"

cp "$INSTALL_DIR/src/brightness-restore.sh" /usr/local/bin/brightness-restore.sh
chmod +x /usr/local/bin/brightness-restore.sh
echo "✓ Installed brightness-restore.sh"

# Step 9: Initialize for current mode
echo ""
echo "🔄 [7/7] Initializing for current GPU mode..."
CURRENT_MODE=$(supergfxctl -g 2>/dev/null)
if [ -n "$CURRENT_MODE" ]; then
    echo "Detected mode: $CURRENT_MODE"
    /usr/bin/supergfxctl -m "$CURRENT_MODE" 2>/dev/null || true
    echo "✓ Initialized"
else
    echo "⚠ Could not detect GPU mode"
    echo "  Run manually after reboot: sudo supergfxctl -m <mode>"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    ✅ Installation Complete!                         "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was installed:"
echo "   • Base kernel parameters in /etc/kernel/cmdline"
echo "   • Intelligent supergfxctl wrapper"
echo "   • Automatic boot entry regeneration"
echo "   • Backlight permission rules (udev)"
echo "   • Update protection (pacman hook)"
echo "   • Monitoring tools (brightness-check.sh)"
echo ""
echo "⚡ Next Steps:"
echo "   1. REBOOT your system: sudo reboot"
echo "   2. After reboot, test brightness controls"
echo "   3. Switch GPU modes with: sudo supergfxctl -m <Hybrid|AsusMuxDgpu>"
echo "   4. Always reboot after switching modes"
echo ""
echo "🔍 Verify installation:"
echo "   Run: brightness-check.sh"
echo ""
echo "📖 Usage:"
echo "   • Switch to Hybrid:  sudo supergfxctl -m Hybrid && sudo reboot"
echo "   • Switch to dGPU:    sudo supergfxctl -m AsusMuxDgpu && sudo reboot"
echo ""
echo "⚠️  IMPORTANT: Group membership requires logout/login to take effect."
echo "             Reboot will handle this automatically."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
