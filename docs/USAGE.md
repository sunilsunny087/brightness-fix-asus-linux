# Usage Guide

Daily usage instructions for the brightness fix.

## Basic Usage

### Switching GPU Modes

The wrapper automatically manages boot parameters when you switch modes.

**Command Line (Recommended):**
```bash
# Switch to Hybrid mode
sudo supergfxctl -m Hybrid
sudo reboot

# Switch to dGPU mode
sudo supergfxctl -m AsusMuxDgpu
sudo reboot

# Switch to Integrated mode (if supported)
sudo supergfxctl -m Integrated
sudo reboot
```

**What Happens:**
1. Wrapper detects target mode
2. Updates `/etc/kernel/cmdline` appropriately
3. Regenerates boot entries
4. Prompts for reboot

**Via KDE Plasmoid:**
1. Click GPU mode widget in system tray
2. Select desired mode
3. System prompts for reboot
4. Reboot to apply changes

### Controlling Brightness

After switching modes and rebooting, brightness controls work automatically:

**Function Keys:**
- `Fn + F5` / `Fn + F6` (or your laptop's brightness keys)

**Desktop Environment:**
- KDE: System Settings → Display & Monitor → Brightness
- GNOME: Settings → Power → Brightness
- Use brightness slider in system tray

**Command Line:**
```bash
# Check current brightness
cat /sys/class/backlight/*/brightness

# Set brightness (0 to max_brightness)
echo 50 > /sys/class/backlight/*/brightness

# Check maximum value
cat /sys/class/backlight/*/max_brightness
```

## Advanced Usage

### Manual Boot Parameter Management

If you need to manually adjust boot parameters:
```bash
# Edit kernel cmdline
sudo nano /etc/kernel/cmdline

# After editing, regenerate boot entries
sudo reinstall-kernels

# Verify
cat /boot/loader/entries/*.conf | grep options
```

### Checking System Status
```bash
# Quick health check
brightness-check.sh

# Check current GPU mode
supergfxctl -g

# Check available modes
supergfxctl -s

# Check backlight interface
ls /sys/class/backlight/

# Check boot parameters
cat /etc/kernel/cmdline
cat /proc/cmdline
```

### Emergency Recovery

If something breaks:
```bash
# Full system restoration
sudo brightness-restore.sh

# Reboot
sudo reboot
```

## Workflows

### Daily Laptop Usage

**Portable Mode (Battery Life):**
```bash
sudo supergfxctl -m Hybrid
sudo reboot
# Uses iGPU, better battery life
# Brightness works with nvidia_wmi_ec_backlight
```

**Gaming/Performance Mode:**
```bash
sudo supergfxctl -m AsusMuxDgpu
sudo reboot
# Uses dGPU only, maximum performance
# Brightness works with nvidia_0
```

### After System Updates
```bash
# After kernel or driver updates
sudo reboot

# Verify brightness still works
brightness-check.sh

# If issues, restore configuration
sudo brightness-restore.sh
sudo reboot
```

## Tips & Best Practices

### Always Reboot After Switching

GPU mode changes require a reboot to:
- Apply new kernel parameters
- Initialize correct backlight interface
- Load appropriate drivers

**Don't skip the reboot!**

### Use the Health Check

Run `brightness-check.sh` regularly:
- After system updates
- After switching GPU modes
- If brightness stops working
- To verify configuration integrity

### Aliases for Convenience

Add to `~/.bashrc`:
```bash
# GPU mode aliases
alias gpu-hybrid='sudo supergfxctl -m Hybrid && echo "Reboot to apply: sudo reboot"'
alias gpu-dgpu='sudo supergfxctl -m AsusMuxDgpu && echo "Reboot to apply: sudo reboot"'
alias gpu-status='supergfxctl -g && ls /sys/class/backlight/'

# Brightness aliases
alias brightness-up='echo $(($(cat /sys/class/backlight/*/brightness) + 10)) > /sys/class/backlight/*/brightness'
alias brightness-down='echo $(($(cat /sys/class/backlight/*/brightness) - 10)) > /sys/class/backlight/*/brightness'
```

Reload shell:
```bash
source ~/.bashrc
```

### Monitoring Logs

Watch for issues:
```bash
# Monitor supergfxd in real-time
journalctl -u supergfxd -f

# Check recent brightness-related events
journalctl -b | grep -i backlight

# Check wrapper execution
journalctl -b | grep "Adjusting boot parameters"
```

## Understanding Backlight Interfaces

### nvidia_0 (dGPU Mode)

- **Created when:** `acpi_backlight=native` is set
- **Used in:** AsusMuxDgpu mode
- **Characteristics:**
  - Direct NVIDIA GPU control
  - Maximum compatibility
  - Requires dGPU to be active

### nvidia_wmi_ec_backlight (Hybrid Mode)

- **Created when:** No `acpi_backlight` parameter
- **Used in:** Hybrid mode
- **Characteristics:**
  - WMI-based control
  - Works with iGPU active
  - ASUS-specific implementation

### intel_backlight (Integrated Mode)

- **Created when:** Only iGPU active
- **Used in:** Integrated mode
- **Characteristics:**
  - Intel-native control
  - Best power efficiency
  - Standard Linux backlight

## Next Steps

- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for issues
- Check [CONTRIBUTING.md](../CONTRIBUTING.md) to help improve
- Join [ASUS Linux Community](https://asus-linux.org/)
