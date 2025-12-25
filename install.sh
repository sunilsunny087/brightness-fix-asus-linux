#!/bin/bash

# Arch Linux Brightness Fix + AsusCtlTray Integration
# Complete installation script
# Version 2.0

set -e  # Exit on any error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "     Arch Linux Brightness Fix + AsusCtlTray Integration v2.0          "
echo "          For ASUS Laptops with NVIDIA dGPU + Intel iGPU               "
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
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    echo "❌ Could not determine actual user. Run with sudo, not as root."
    exit 1
fi

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📋 System Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "User: $ACTUAL_USER"
echo "Home: $ACTUAL_HOME"
echo "Current GPU mode: $(supergfxctl -g 2>/dev/null || echo 'Unknown')"
echo ""

# ============================================================================
# PART 1: Prerequisites Check
# ============================================================================
echo "📋 [1/9] Checking Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

MISSING_DEPS=()

# Check supergfxctl
if command -v supergfxctl &> /dev/null; then
    echo "✓ supergfxctl found"
else
    echo "✗ supergfxctl not found"
    MISSING_DEPS+=("supergfxctl")
fi

# Check reinstall-kernels
if command -v reinstall-kernels &> /dev/null; then
    echo "✓ reinstall-kernels found"
else
    echo "✗ reinstall-kernels not found"
    MISSING_DEPS+=("kernel-install-for-dracut")
fi

# Check systemd-boot
if [ -f /usr/lib/systemd/boot/efi/systemd-bootx64.efi ]; then
    echo "✓ systemd-boot found"
else
    echo "⚠ systemd-boot might not be installed"
fi

# Check yay or paru
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
    echo "✓ yay found"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
    echo "✓ paru found"
else
    echo "✗ No AUR helper found (yay or paru required)"
    MISSING_DEPS+=("yay")
fi

# Check asusctltray
ASUSCTLTRAY_INSTALLED=false
if [ -f /usr/local/bin/asusctltray ]; then
    echo "✓ asusctltray found"
    ASUSCTLTRAY_INSTALLED=true
else
    echo "⚠ asusctltray not found (will be installed)"
fi

# Check inotify-tools
if command -v inotifywait &> /dev/null; then
    echo "✓ inotify-tools found"
else
    echo "⚠ inotify-tools not found (will be installed)"
    MISSING_DEPS+=("inotify-tools")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    echo "❌ Missing required packages: ${MISSING_DEPS[*]}"
    echo ""
    read -p "Install missing packages? (yes/no): " install_deps
    if [ "$install_deps" = "yes" ]; then
        for pkg in "${MISSING_DEPS[@]}"; do
            echo "Installing $pkg..."
            if [ "$pkg" = "supergfxctl" ] || [ "$pkg" = "yay" ]; then
                echo "⚠ Please install $pkg manually from AUR first"
                exit 1
            else
                pacman -S --noconfirm "$pkg"
            fi
        done
    else
        echo "Cannot continue without required packages."
        exit 1
    fi
fi

# Detect root partition UUID
echo ""
echo "🔍 Detecting root partition..."
ROOT_UUID=$(findmnt -no UUID /)
if [ -z "$ROOT_UUID" ]; then
    echo "❌ Could not detect root partition UUID"
    read -p "Enter your root partition UUID: " ROOT_UUID
fi
echo "✓ Root partition UUID: $ROOT_UUID"
echo ""

read -p "Proceed with installation? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi

# ============================================================================
# PART 2: Install AsusCtlTray if needed
# ============================================================================
echo ""
echo "📦 [2/9] Installing AsusCtlTray"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$ASUSCTLTRAY_INSTALLED" = false ]; then
    echo "Installing asusctltray-upgraded-git from AUR..."

    # Run as actual user
    su - "$ACTUAL_USER" -c "
        cd /tmp
        $AUR_HELPER -S --noconfirm --needed asusctltray-upgraded-git
    "

    if [ $? -eq 0 ]; then
        echo "✓ asusctltray installed successfully"
    else
        echo "❌ Failed to install asusctltray"
        exit 1
    fi
else
    echo "✓ asusctltray already installed"
fi

# ============================================================================
# PART 3: Brightness Fix - Base Kernel Cmdline
# ============================================================================
echo ""
echo "📝 [3/9] Creating base kernel command line"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat > /etc/kernel/cmdline << EOF
nvme_load=YES nowatchdog rw root=UUID=$ROOT_UUID nvidia_drm.modeset=1 nvidia.NVreg_EnableBacklightHandler=1
EOF
echo "✓ Created /etc/kernel/cmdline"

# ============================================================================
# PART 4: Brightness Fix - Supergfxctl Wrapper
# ============================================================================
echo ""
echo "📦 [4/9] Setting up supergfxctl wrapper"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f /usr/bin/supergfxctl ] && [ ! -f /usr/bin/supergfxctl-original ]; then
    cp /usr/bin/supergfxctl /usr/bin/supergfxctl-original
    echo "✓ Backed up original supergfxctl"
fi

cp "$INSTALL_DIR/src/supergfxctl-wrapper.sh" /usr/bin/supergfxctl
chmod +x /usr/bin/supergfxctl
echo "✓ Installed wrapper"

cp /usr/bin/supergfxctl /usr/local/bin/supergfxctl-wrapper.sh
echo "✓ Created wrapper backup"

# ============================================================================
# PART 5: Brightness Fix - Udev Rules
# ============================================================================
echo ""
echo "🔧 [5/9] Installing udev rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cp "$INSTALL_DIR/src/90-backlight.rules" /etc/udev/rules.d/90-backlight.rules
udevadm control --reload-rules
echo "✓ Installed and reloaded udev rules"

# ============================================================================
# PART 6: Brightness Fix - User Setup
# ============================================================================
echo ""
echo "👤 [6/9] Adding user to video group"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

usermod -aG video "$ACTUAL_USER"
echo "✓ Added $ACTUAL_USER to video group"

# ============================================================================
# PART 7: Brightness Fix - Pacman Hooks
# ============================================================================
echo ""
echo "🪝 [7/9] Installing pacman hooks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

mkdir -p /etc/pacman.d/hooks
cp "$INSTALL_DIR/src/supergfxctl-wrapper.hook" /etc/pacman.d/hooks/
echo "✓ Installed supergfxctl hook"

# ============================================================================
# PART 8: AsusCtlTray Integration
# ============================================================================
echo ""
echo "🔧 [8/9] Installing AsusCtlTray patches and GPU monitor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Install patched asusctltray
if [ -f "$INSTALL_DIR/src/asusctltray/asusctltray.py" ]; then
    cp /usr/local/bin/asusctltray /usr/local/bin/asusctltray.original 2>/dev/null || true
    cp "$INSTALL_DIR/src/asusctltray/asusctltray.py" /usr/local/bin/asusctltray
    chmod +x /usr/local/bin/asusctltray
    cp "$INSTALL_DIR/src/asusctltray/asusctltray.py" /usr/local/bin/asusctltray.patched
    echo "✓ Installed patched asusctltray"

    # Install patch script and hook
    cp "$INSTALL_DIR/src/asusctltray/asusctltray-patch.sh" /usr/local/bin/
    chmod +x /usr/local/bin/asusctltray-patch.sh
    cp "$INSTALL_DIR/src/asusctltray/asusctltray-wrapper.hook" /etc/pacman.d/hooks/
    echo "✓ Installed asusctltray update protection"
fi

# Install patched asusctltray
if [ -f "$INSTALL_DIR/src/asusctltray/asusctltray.py" ]; then
    cp /usr/local/bin/asusctltray /usr/local/bin/asusctltray.original 2>/dev/null || true
    cp "$INSTALL_DIR/src/asusctltray/asusctltray.py" /usr/local/bin/asusctltray
    chmod +x /usr/local/bin/asusctltray
    cp "$INSTALL_DIR/src/asusctltray/asusctltray.py" /usr/local/bin/asusctltray.patched
    echo "✓ Installed patched asusctltray"

    # Install custom icons
    if [ -d "$INSTALL_DIR/src/asusctltray/icons" ]; then
        cp "$INSTALL_DIR/src/asusctltray/icons/"*.svg /usr/share/pixmaps/
        echo "✓ Installed custom tray icons"
    fi

    # Install patch script and hook
    cp "$INSTALL_DIR/src/asusctltray/asusctltray-patch.sh" /usr/local/bin/
    chmod +x /usr/local/bin/asusctltray-patch.sh
    cp "$INSTALL_DIR/src/asusctltray/asusctltray-wrapper.hook" /etc/pacman.d/hooks/
    echo "✓ Installed asusctltray update protection"
fi

# Install GPU status monitor
if [ -f "$INSTALL_DIR/src/asusctltray/gpu-status-monitor.sh" ]; then
    cp "$INSTALL_DIR/src/asusctltray/gpu-status-monitor.sh" /usr/local/bin/
    chmod +x /usr/local/bin/gpu-status-monitor.sh
    echo "✓ Installed GPU status monitor script"

    # Install systemd user service
    mkdir -p "$ACTUAL_HOME/.config/systemd/user"
    cp "$INSTALL_DIR/src/asusctltray/gpu-status-monitor.service" "$ACTUAL_HOME/.config/systemd/user/"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.config/systemd/user"

    # Enable service as user
    su - "$ACTUAL_USER" -c "
        systemctl --user daemon-reload
        systemctl --user enable gpu-status-monitor.service
        systemctl --user start gpu-status-monitor.service
    "
    echo "✓ Enabled GPU status monitor service"
fi

# ============================================================================
# PART 9: Initialize Configuration
# ============================================================================
echo ""
echo "🔄 [9/9] Initializing for current GPU mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CURRENT_MODE=$(supergfxctl -g 2>/dev/null)
if [ -n "$CURRENT_MODE" ]; then
    echo "Detected mode: $CURRENT_MODE"
    /usr/bin/supergfxctl -m "$CURRENT_MODE" 2>/dev/null || true
    echo "✓ Initialized"
else
    echo "⚠ Could not detect GPU mode"
fi

# ============================================================================
# Installation Complete
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    ✅ Installation Complete!                         "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was installed:"
echo "   • Base kernel parameters"
echo "   • Intelligent supergfxctl wrapper"
echo "   • Backlight permission rules"
echo "   • Update protection (pacman hooks)"
echo "   • Patched asusctltray with all GPU modes visible"
echo "   • GPU status monitor (auto-refreshes tray)"
echo ""
echo "⚡ Next Steps:"
echo "   1. REBOOT your system: sudo reboot"
echo "   2. After reboot, test brightness controls"
echo "   3. Test GPU switching:"
echo "      - Via CLI: sudo supergfxctl -m <Hybrid|AsusMuxDgpu>"
echo "      - Via tray: Click asusctltray icon"
echo "   4. Always reboot after switching modes"
echo ""
echo "🔍 Verify everything:"
echo "   • Check GPU monitor: systemctl --user status gpu-status-monitor"
echo "   • Check brightness: echo 50 > /sys/class/backlight/*/brightness"
echo ""
echo "⚠️  IMPORTANT: Group membership requires logout/login to take effect."
echo "             Reboot will handle this automatically."
echo ""
echo "📖 Documentation: See README.md for usage and troubleshooting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
