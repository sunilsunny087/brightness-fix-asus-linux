# Installation Guide

Complete step-by-step installation instructions.

## Prerequisites

### Required Packages
```bash
# Check if supergfxctl is installed
supergfxctl -g

# If not installed:
yay -S supergfxctl
```

### System Requirements

- Arch Linux or Arch-based distribution
- systemd-boot bootloader
- NVIDIA proprietary drivers
- ASUS laptop with hybrid graphics

### Verify Your Setup
```bash
# Check bootloader
ls /boot/loader/

# Check if reinstall-kernels exists
which reinstall-kernels

# Check GPU mode support
supergfxctl -s
```

## Installation Steps

### 1. Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/brightness-fix-asus-linux.git
cd brightness-fix-asus-linux
```

### 2. Review Files (Optional)
```bash
# Check install script
cat install.sh

# Check wrapper script
cat src/supergfxctl-wrapper.sh
```

### 3. Run Installer
```bash
sudo bash install.sh
```

The installer will:
1. Check prerequisites
2. Detect your root partition UUID
3. Create base kernel parameters
4. Install wrapper scripts
5. Configure udev rules
6. Add you to video group
7. Set up update protection

### 4. Reboot
```bash
sudo reboot
```

## Post-Installation

### Verify Installation
```bash
# Run health check
brightness-check.sh

# Expected output: All checks passed ✅
```

### Test Brightness
```bash
# Manual test
echo 30 > /sys/class/backlight/*/brightness
echo 80 > /sys/class/backlight/*/brightness

# Function keys should also work
```

### Test GPU Switching
```bash
# Switch to Hybrid mode
sudo supergfxctl -m Hybrid
sudo reboot

# After reboot, test brightness in Hybrid mode
brightness-check.sh

# Switch back to dGPU
sudo supergfxctl -m AsusMuxDgpu
sudo reboot

# Test brightness in dGPU mode
brightness-check.sh
```

## Troubleshooting Installation

### "supergfxctl not found"

Install supergfxctl first:
```bash
yay -S supergfxctl
```

### "Could not detect root UUID"

Find it manually:
```bash
findmnt -no UUID /
```

Then edit `/etc/kernel/cmdline` and add the UUID.

### "reinstall-kernels not found"

Install kernel-install-for-dracut:
```bash
sudo pacman -S kernel-install-for-dracut
```

### Permission Issues

Ensure you're running as sudo:
```bash
sudo bash install.sh
```

Not as root directly.

## Next Steps

- Read [USAGE.md](USAGE.md) for daily usage
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Join [ASUS Linux Discord](https://asus-linux.org/discord) for support
