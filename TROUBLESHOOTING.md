# Troubleshooting Guide

Complete troubleshooting guide for common issues with the Arch Linux Brightness Fix.

---

## Table of Contents

1. [Brightness Issues](#brightness-issues)
2. [GPU Mode Switching Issues](#gpu-mode-switching-issues)
3. [AsusCtlTray Issues](#asusctltray-issues)
4. [Update-Related Issues](#update-related-issues)
5. [Boot Issues](#boot-issues)
6. [Diagnostic Commands](#diagnostic-commands)

---

## Brightness Issues

### Brightness Controls Don't Work

**Symptoms:**
- Function keys don't change brightness
- Desktop environment slider doesn't work
- Manual brightness commands fail

**Diagnosis:**
```bash
# Check which backlight interface exists
ls /sys/class/backlight/

# Check current GPU mode
supergfxctl -g

# Check permissions
ls -la /sys/class/backlight/*/brightness

# Check if you're in video group
groups | grep video
```

**Expected backlight interfaces by mode:**
- **Hybrid mode:** `nvidia_wmi_ec_backlight`
- **AsusMuxDgpu mode:** `nvidia_0`

**Solutions:**

**1. Wrong backlight interface for current mode:**
```bash
# Check boot parameters
cat /proc/cmdline | grep acpi_backlight

# In dGPU mode, should have: acpi_backlight=native
# In Hybrid mode, should NOT have it

# Fix: Re-apply current mode
sudo supergfxctl -m $(supergfxctl -g)
sudo reboot
```

**2. Permission denied:**
```bash
# Add yourself to video group
sudo usermod -aG video $USER

# Logout and login (or reboot)
```

**3. Udev rules not loaded:**
```bash
# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reboot to be sure
sudo reboot
```

### Brightness Works But Values Don't Stick

**Symptom:** Brightness resets on reboot

**Solution:** This is normal - the system saves brightness state via systemd-backlight service. If it's not working:
```bash
# Check backlight service
systemctl status systemd-backlight@backlight:*.service

# Manually save current brightness
sudo systemctl start systemd-backlight@backlight:nvidia_wmi_ec_backlight.service
```

---

## GPU Mode Switching Issues

### System Stays in Hybrid Mode After Switching

**Symptom:** You switch to dGPU mode but after reboot, still in Hybrid

**Diagnosis:**
```bash
# Check daemon config
cat /etc/supergfxd.conf

# Check boot parameters
cat /etc/kernel/cmdline

# Check what the daemon loaded
journalctl -u supergfxd -b | grep -i "reload\|mode"
```

**Possible causes:**

**1. Boot parameters not applied:**
```bash
# Manually check boot entry
cat /boot/loader/entries/*.conf | grep options

# If acpi_backlight=native is missing in dGPU mode, regenerate
sudo reinstall-kernels
sudo reboot
```

**2. Daemon config not updated:**
```bash
# Check config
cat /etc/supergfxd.conf

# Should show:
# "mode": "AsusMuxDgpu"  (for dGPU)
# "mode": "Hybrid"       (for Hybrid)

# If wrong, edit manually
sudo nano /etc/supergfxd.conf

# Then restart daemon
sudo systemctl restart supergfxd
```

**3. BIOS/UEFI settings:**
- Some laptops have BIOS options that override software GPU switching
- Check BIOS for "GPU Mode" or "Graphics Switching" settings
- Ensure it's set to "Auto" or "Switchable"

### Can't Switch to dGPU Mode

**Symptom:** Command runs but mode doesn't change

**Solutions:**
```bash
# Check if wrapper is working
which supergfxctl
# Should be: /usr/bin/supergfxctl

# Check if it's the wrapper
head -5 /usr/bin/supergfxctl
# Should show: #!/bin/bash

# If not, restore wrapper
sudo cp /usr/local/bin/supergfxctl-wrapper.sh /usr/bin/supergfxctl
sudo chmod +x /usr/bin/supergfxctl
```

### Mode Shows Wrong in Tray

**Symptom:** Tray shows wrong GPU mode or status

**Solution:**
```bash
# Restart tray
pkill -f asusctltray
asusctltray &

# Check if GPU monitor is running
systemctl --user status gpu-status-monitor

# If not running, start it
systemctl --user start gpu-status-monitor
```

---

## AsusCtlTray Issues

### Tray Not Showing

**Solution:**
```bash
# Check if running
ps aux | grep asusctltray

# If not running, start it
asusctltray &

# Add to autostart
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/asusctltray.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=AsusCtlTray
Exec=asusctltray
X-KDE-autostart-after=panel
EOF
```

### Tray Shows "dGPU: active" in Hybrid Mode

**Symptom:** Status doesn't update after switching modes

**Solutions:**

**1. Restart tray manually:**
```bash
pkill -f asusctltray
sleep 2
asusctltray &
```

**2. Check GPU monitor service:**
```bash
# Should restart tray automatically when GPU state changes
systemctl --user status gpu-status-monitor

# View logs
journalctl --user -u gpu-status-monitor -f
```

**3. Restart GPU monitor:**
```bash
systemctl --user restart gpu-status-monitor
```

### "Share Input" Permission Dialog Appears

**Symptom:** KDE asks for input sharing permission when clicking tray

**Cause:** Tray is running as root instead of your user

**Solution:**
```bash
# Kill root-owned tray
sudo pkill -f asusctltray

# Start as your user
asusctltray &

# Check owner
ps aux | grep asusctltray
# Should show your username, not root
```

### Tray Icon Doesn't Change

**Symptom:** Icon stays the same regardless of GPU mode

**Solutions:**

**1. Check icons are installed:**
```bash
ls -la /usr/share/pixmaps/asusctltray-*.svg

# Should show:
# asusctltray-dgpu.svg
# asusctltray-hybrid-active.svg
# asusctltray-hybrid-suspended.svg
```

**2. If missing, reinstall icons:**
```bash
cd ~/brightness-fix-asus-linux
sudo cp src/asusctltray/icons/*.svg /usr/share/pixmaps/
```

**3. Restart tray:**
```bash
pkill -f asusctltray
asusctltray &
```

---

## Update-Related Issues

### Brightness Stops Working After Kernel Update

**Solution:**
```bash
# Regenerate boot entries
sudo reinstall-kernels

# Verify boot parameters
cat /boot/loader/entries/*.conf | grep options

# Reboot
sudo reboot
```

### Wrapper Lost After supergfxctl Update

**Symptom:** Brightness fix stops working after package update

**Solution:**
```bash
# Check if wrapper exists
ls -l /usr/bin/supergfxctl

# If it's the original binary (not a script), restore wrapper
sudo cp /usr/local/bin/supergfxctl-wrapper.sh /usr/bin/supergfxctl
sudo chmod +x /usr/bin/supergfxctl

# Move original
sudo mv /usr/bin/supergfxctl /usr/bin/supergfxctl-original
sudo cp /usr/local/bin/supergfxctl-wrapper.sh /usr/bin/supergfxctl
```

### AsusCtlTray Stops Working After Update

**Solution:**
```bash
# Run patch script
sudo /usr/local/bin/asusctltray-patch.sh

# Or manually restore
sudo cp /usr/local/bin/asusctltray.patched /usr/local/bin/asusctltray

# Restart tray
pkill -f asusctltray
asusctltray &
```

---

## Boot Issues

### System Won't Boot After Changes

**Symptom:** Black screen or boot failure

**Solution:**

**1. Boot from live USB**

**2. Mount your system:**
```bash
# Mount root partition (adjust device as needed)
sudo mount /dev/nvme0n1p2 /mnt

# Mount EFI partition
sudo mount /dev/nvme0n1p1 /mnt/boot

# Chroot
sudo arch-chroot /mnt
```

**3. Check and fix boot parameters:**
```bash
# View current cmdline
cat /etc/kernel/cmdline

# If corrupted, recreate (replace UUID with yours)
cat > /etc/kernel/cmdline << 'EOF'
nvme_load=YES nowatchdog rw root=UUID=YOUR-UUID-HERE nvidia_drm.modeset=1 nvidia.NVreg_EnableBacklightHandler=1
EOF

# Regenerate boot entries
reinstall-kernels

# Exit and reboot
exit
sudo reboot
```

### Boot Entries Not Regenerating

**Symptom:** Changes to `/etc/kernel/cmdline` don't appear in boot entries

**Solutions:**

**1. Check EFI partition is mounted:**
```bash
mount | grep /boot
# Should show your EFI partition mounted at /boot
```

**2. If not mounted:**
```bash
sudo mount /dev/nvme0n1p1 /boot  # Adjust device as needed
```

**3. Manually regenerate:**
```bash
sudo reinstall-kernels

# Verify
cat /boot/loader/entries/*.conf | grep options
```

---

## Diagnostic Commands

### Complete System Check

Run this comprehensive diagnostic:
```bash
#!/bin/bash
echo "=== System Diagnostics ==="
echo ""

echo "1. GPU Mode:"
supergfxctl -g

echo ""
echo "2. Boot Parameters (File):"
cat /etc/kernel/cmdline

echo ""
echo "3. Boot Parameters (Running):"
cat /proc/cmdline

echo ""
echo "4. Backlight Interface:"
ls /sys/class/backlight/

echo ""
echo "5. Backlight Permissions:"
ls -la /sys/class/backlight/*/brightness

echo ""
echo "6. Video Group:"
groups | grep video

echo ""
echo "7. Wrapper Status:"
ls -l /usr/bin/supergfxctl*

echo ""
echo "8. AsusCtlTray Status:"
ps aux | grep asusctltray | grep -v grep

echo ""
echo "9. GPU Monitor Status:"
systemctl --user is-active gpu-status-monitor

echo ""
echo "10. Daemon Config:"
cat /etc/supergfxd.conf

echo ""
echo "11. Daemon Status:"
systemctl status supergfxd --no-pager -l

echo ""
echo "12. Boot Entry:"
cat /boot/loader/entries/*.conf | grep -A 2 options
```

Save this as `diagnose.sh`, make it executable, and run:
```bash
chmod +x diagnose.sh
./diagnose.sh > diagnostic-report.txt
```

### Collect Logs for Bug Report
```bash
# Collect all relevant logs
{
  echo "=== System Info ==="
  uname -a
  
  echo ""
  echo "=== GPU Mode ==="
  supergfxctl -g
  supergfxctl -s
  
  echo ""
  echo "=== Backlight ==="
  ls -la /sys/class/backlight/
  
  echo ""
  echo "=== Boot Config ==="
  cat /etc/kernel/cmdline
  cat /proc/cmdline
  
  echo ""
  echo "=== Daemon Logs ==="
  journalctl -u supergfxd -b --no-pager | tail -100
  
  echo ""
  echo "=== GPU Monitor Logs ==="
  journalctl --user -u gpu-status-monitor --no-pager | tail -50
  
} > ~/brightness-debug-$(date +%Y%m%d-%H%M%S).log

echo "Debug info saved to: ~/brightness-debug-*.log"
```

---

## Getting Help

If you've tried everything here and still have issues:

1. **Collect diagnostics** using the commands above
2. **Create an issue** on [GitHub](https://github.com/YOUR_USERNAME/brightness-fix-asus-linux/issues)
3. **Include:**
   - Your laptop model
   - GPU models (Intel + NVIDIA)
   - Arch Linux version and kernel
   - Complete diagnostic output
   - What you've already tried

---

## Quick Reference

### Working Configuration Check
```bash
# Quick health check
brightness-check.sh

# Should show all ✓ marks
```

### Emergency Recovery
```bash
# Full restoration from backups
sudo brightness-restore.sh
sudo reboot
```

### Common Quick Fixes
```bash
# Fix 1: Brightness not working - Reapply mode
sudo supergfxctl -m $(supergfxctl -g) && sudo reboot

# Fix 2: Tray wrong status - Restart tray
pkill -f asusctltray && asusctltray &

# Fix 3: After update - Restore wrapper
sudo cp /usr/local/bin/supergfxctl-wrapper.sh /usr/bin/supergfxctl

# Fix 4: Permissions - Add to video group
sudo usermod -aG video $USER && echo "Logout/login required"
```

---

**Last Updated:** December 2025  
**Version:** 2.1
