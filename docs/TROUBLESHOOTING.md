# Troubleshooting Guide

Common issues and solutions.

## Brightness Issues

### Brightness Doesn't Change

**Symptoms:** Brightness value writes successfully but screen doesn't change

**Diagnosis:**
```bash
# Check which interface exists
ls /sys/class/backlight/

# Check if value is writing
cat /sys/class/backlight/*/brightness
echo 50 > /sys/class/backlight/*/brightness
cat /sys/class/backlight/*/brightness
# Value should change to 50
```

**Solutions:**

1. **Wrong GPU mode for current interface:**
```bash
   # Check mode vs interface match
   supergfxctl -g
   ls /sys/class/backlight/
   
   # dGPU mode should have: nvidia_0
   # Hybrid mode should have: nvidia_wmi_ec_backlight
```

2. **Need reboot after mode switch:**
```bash
   sudo reboot
```

3. **Boot parameters not applied:**
```bash
   cat /proc/cmdline | grep acpi_backlight
   # dGPU mode should show: acpi_backlight=native
   # Hybrid mode should NOT show it
```

### Permission Denied

**Symptoms:** `Permission denied` when writing to brightness file

**Diagnosis:**
```bash
ls -la /sys/class/backlight/*/brightness
# Should be: -rw-rw-r-- root video

groups | grep video
# Should include 'video'
```

**Solutions:**

1. **Not in video group:**
```bash
   sudo usermod -aG video $USER
   # Logout and login (or reboot)
```

2. **Udev rules not loaded:**
```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
```

## Wrapper Issues

### Wrapper Not Working

**Symptoms:** Running `supergfxctl -m` doesn't update boot parameters

**Diagnosis:**
```bash
# Check wrapper exists
ls -l /usr/bin/supergfxctl

# Check original exists
ls -l /usr/bin/supergfxctl-original

# Test wrapper
sudo supergfxctl -m Hybrid
# Should show "Adjusting boot parameters..." message
```

**Solutions:**

1. **Wrapper replaced by update:**
```bash
   sudo brightness-restore.sh
```

2. **Original binary missing:**
```bash
   # Reinstall supergfxctl package
   sudo pacman -S supergfxctl --overwrite '*'
   
   # Then reinstall brightness fix
   sudo bash install.sh
```

### Boot Entries Not Regenerating

**Symptoms:** `/etc/kernel/cmdline` updates but boot entries don't change

**Diagnosis:**
```bash
# Check cmdline
cat /etc/kernel/cmdline

# Check boot entry
cat /boot/loader/entries/*.conf | grep options

# They should match
```

**Solutions:**

1. **EFI partition not mounted:**
```bash
   # Check if mounted
   mount | grep /boot
   
   # If not, mount it
   sudo mount /dev/nvme0n1p1 /boot  # Adjust device as needed
```

2. **Manually regenerate:**
```bash
   sudo reinstall-kernels
```

## GPU Switching Issues

### Can't Switch to Hybrid Mode

**Symptoms:** Hybrid option greyed out in plasmoid/tray

**Diagnosis:**
```bash
# Check daemon status
systemctl status supergfxd

# Check logs
journalctl -u supergfxd -b | grep -i hybrid
```

**Solutions:**

1. **Pending reboot:**
```bash
   # Just reboot to complete previous switch
   sudo reboot
```

2. **Daemon thinks reboot needed:**
```bash
   # Clear pending state
   sudo systemctl restart supergfxd
```

### Mode Switches But Brightness Breaks

**Symptoms:** GPU mode changes successfully but brightness stops working

**Cause:** Boot parameters not synced with new mode

**Solution:**
```bash
# Re-sync boot parameters
sudo supergfxctl -m $(supergfxctl -g)
sudo reboot
```

## System Issues

### After Kernel Update

**Symptoms:** Brightness stops working after kernel update

**Solutions:**

1. **Boot entries not regenerated:**
```bash
   sudo reinstall-kernels
   sudo reboot
```

2. **Wrapper lost:**
```bash
   brightness-check.sh
   # If wrapper missing:
   sudo brightness-restore.sh
```

### After supergfxctl Update

**Symptoms:** Wrapper functionality lost

**Solution:**
```bash
# Pacman hook should restore automatically
# If not:
sudo brightness-restore.sh
```

## Diagnostic Commands

### Full System Check
```bash
# Run comprehensive check
brightness-check.sh

# Manual checks
echo "=== GPU Mode ==="
supergfxctl -g

echo "=== Boot Parameters ==="
cat /etc/kernel/cmdline

echo "=== Running Parameters ==="
cat /proc/cmdline

echo "=== Backlight Interface ==="
ls -la /sys/class/backlight/

echo "=== Wrapper Status ==="
ls -l /usr/bin/supergfxctl*

echo "=== Video Group ==="
groups | grep video
```

### Log Collection for Bug Reports
```bash
# Collect all relevant logs
{
  echo "=== System Info ==="
  uname -a
  
  echo "=== GPU Mode ==="
  supergfxctl -g
  supergfxctl -s
  
  echo "=== Backlight ==="
  ls -la /sys/class/backlight/
  
  echo "=== Boot Config ==="
  cat /etc/kernel/cmdline
  cat /proc/cmdline
  
  echo "=== Daemon Logs ==="
  journalctl -u supergfxd -b --no-pager
  
  echo "=== Health Check ==="
  brightness-check.sh
} > ~/brightness-debug.log 2>&1

echo "Debug info saved to ~/brightness-debug.log"
```

## Getting Help

If these solutions don't help:

1. Run the diagnostic command above
2. Create an issue with the debug log
3. Include exact steps to reproduce
4. Mention your laptop model and GPU

GitHub Issues: https://github.com/YOUR_USERNAME/brightness-fix-asus-linux/issues
