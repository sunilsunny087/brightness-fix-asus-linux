# Everything has been created by AI in this project
I ran through a problem on my system and i was just starting to learn prompting so i thought of testing my prompting and this is the end result.
# 🔆 Arch Linux Brightness Fix for ASUS Laptops

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff)](https://archlinux.org/)
[![Tested on EndeavourOS](https://img.shields.io/badge/EndeavourOS-7F7FFF?logo=endeavouros&logoColor=fff)](https://endeavouros.com/)

**Automatic brightness control solution for ASUS laptops with hybrid graphics (NVIDIA dGPU + Intel iGPU) using supergfxctl.**

## ✨ Features

- ✅ **Automatic boot parameter management** - Configures kernel parameters based on GPU mode
- ✅ **AsusCtlTray integration** - Patched tray with all GPU modes always visible
- ✅ **Hybrid & dGPU mode support** - Full brightness control in both modes
- ✅ **GPU status monitor** - Automatically refreshes tray when GPU power state changes
- ✅ **Zero manual configuration** - One command installation, works immediately
- ✅ **Update-proof** - Survives kernel updates, driver updates, and package upgrades
- ✅ **Universal CLI compatibility** - Works perfectly via command line
- ✅ **Intelligent wrapper** - Detects GPU mode and adjusts configuration automatically
- ✅ **Self-healing** - Includes monitoring and recovery tools
- ⚠️ **KDE plasmoid limitation** - Use AsusCtlTray or CLI instead

## 🎯 Problem Statement

On ASUS laptops with hybrid graphics, brightness controls stop working when switching between GPU modes:

- **dGPU mode** requires `nvidia_0` backlight interface (needs `acpi_backlight=native` kernel parameter)
- **Hybrid mode** requires `nvidia_wmi_ec_backlight` interface (needs NO `acpi_backlight=native`)

Without proper configuration, brightness keys, desktop environment sliders, and manual brightness control all fail.

## 🆕 What's New in v2.0

- **AsusCtlTray Integration**: Automatically installs and patches asusctltray
- **All GPU modes visible**: No more greyed-out options in the tray
- **Auto-refresh tray**: GPU status monitor detects power state changes
- **Correct mode indication**: Tray shows which GPU mode is currently active
- **Dynamic tray icons**: Different icons for dGPU, Hybrid active, and Hybrid suspended
- **One-command install**: Handles everything including AUR packages

## 🎨 Tray Icons

The system tray icon changes dynamically based on GPU mode and power state:

| Icon | Mode | Description |
|------|------|-------------|
| ![dGPU](src/asusctltray/icons/Dgpu.svg) | AsusMuxDgpu | Dedicated GPU mode (always active) |
| ![Hybrid Active](src/asusctltray/icons/hybrid_active.svg) | Hybrid (Active) | Hybrid mode with dGPU active |
| ![Hybrid Suspended](src/asusctltray/icons/hybrid_suspended.svg) | Hybrid (Suspended) | Hybrid mode with dGPU suspended |

Icons automatically update when:
- Switching GPU modes
- GPU power state changes (active ↔ suspended)
- Tray restarts

## 🚀 Quick Start

### Prerequisites

- Arch Linux or Arch-based distro (EndeavourOS, Manjaro, etc.)
- systemd-boot bootloader
- [supergfxctl](https://gitlab.com/asus-linux/supergfxctl) installed
- NVIDIA proprietary drivers

### Installation
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/brightness-fix-asus-linux.git
cd brightness-fix-asus-linux

# Run installer
sudo bash install.sh

# Reboot
sudo reboot
```

That's it! Brightness will now work in all GPU modes.

## 📖 Usage

### Switching GPU Modes

**✅ Method 1: Via AsusCtlTray (Recommended)**
1. Click the tray icon
2. Select Graphics → desired mode (Hybrid or AsusMuxDiscreet)
3. Click "Reboot the system" when prompted
4. Brightness will work after reboot

**✅ Method 2: Via Command Line**
```bash
# Switch to Hybrid mode
sudo supergfxctl -m Hybrid
sudo reboot

# Switch to dGPU mode
sudo supergfxctl -m AsusMuxDgpu
sudo reboot
```

**❌ Method 3: KDE Plasmoid/Widget**
- Not recommended - has greyed-out options issue
- Use AsusCtlTray or CLI instead

### Supported GPU Modes

- **Hybrid** - Intel iGPU for display, NVIDIA for compute (better battery)
- **AsusMuxDgpu** - NVIDIA dGPU for everything (maximum performance)
- **Integrated** - Not officially supported (untested)

### Monitoring & Maintenance

**Check system health:**
```bash
brightness-check.sh
```

**Emergency recovery:**
```bash
sudo brightness-restore.sh
```

## 🔧 How It Works

The solution wraps `supergfxctl` to automatically manage kernel boot parameters:
```
User switches GPU mode
    ↓
Wrapper detects target mode
    ↓
Adds/removes acpi_backlight=native in /etc/kernel/cmdline
    ↓
Regenerates boot entries
    ↓
User reboots
    ↓
Correct backlight interface created
    ↓
Brightness controls work! ✨
```

### Boot Parameters by Mode

| GPU Mode | Boot Parameter | Backlight Interface | Status |
|----------|----------------|---------------------|--------|
| AsusMuxDgpu | `acpi_backlight=native` | `nvidia_0` | ✅ Works |
| Hybrid | _(removed)_ | `nvidia_wmi_ec_backlight` | ✅ Works |
| Integrated | _(removed)_ | `intel_backlight` | ✅ Works |

## 📦 What Gets Installed
```
/etc/kernel/cmdline                              # Base kernel parameters
/usr/bin/supergfxctl                             # Intelligent wrapper
/usr/bin/supergfxctl-original                    # Original binary backup
/usr/local/bin/supergfxctl-wrapper.sh            # Wrapper backup
/etc/udev/rules.d/90-backlight.rules             # Backlight permissions
/etc/pacman.d/hooks/supergfxctl-wrapper.hook     # Update protection
/usr/local/bin/brightness-check.sh               # Health monitoring
/usr/local/bin/brightness-restore.sh             # Emergency recovery
```

## 🛠️ Advanced

### Manual Brightness Control
```bash
# Check available backlight interfaces
ls /sys/class/backlight/

# Set brightness (0-100 or 0-max_brightness)
echo 50 > /sys/class/backlight/*/brightness

# Check current brightness
cat /sys/class/backlight/*/brightness
```

### Verify Installation
```bash
# Run health check
brightness-check.sh

# Check boot parameters
cat /etc/kernel/cmdline

# Check running kernel parameters  
cat /proc/cmdline

# Check current GPU mode
supergfxctl -g
```

### Logs and Debugging
```bash
# Check supergfxd daemon logs
journalctl -u supergfxd -b

# Check wrapper execution
journalctl -b | grep "Adjusting boot parameters"

# Check backlight initialization
journalctl -b | grep -i backlight
```

## ❌ Uninstallation
```bash
cd brightness-fix-asus-linux
sudo bash uninstall.sh
sudo reboot
```

This removes all modifications and restores original `supergfxctl`.

## ⚠️ Known Limitations

### Plasmoid/Widget Limitations

**KDE Plasma supergfxctl widget:**
- ❌ Greyed-out modes issue not fixed
- The widget queries the daemon's `Supported()` method directly via D-Bus
- Only shows modes available in *current* hardware state (not switchable modes)
- **Workaround:** Use AsusCtlTray or CLI instead

**Recommended alternatives:**
- ✅ **AsusCtlTray** (fully working with all modes visible)
- ✅ **CLI commands** (`sudo supergfxctl -m <mode>`)

### GPU Mode Support

| Mode | Brightness Control | Switching | Status |
|------|-------------------|-----------|--------|
| **Hybrid** | ✅ Works | ✅ Works | Fully supported |
| **AsusMuxDgpu** | ✅ Works | ✅ Works | Fully supported |
| **Integrated** | ❓ Untested | ❓ Untested | Not officially supported |

**Note on Integrated mode:**
- The installer and wrapper support Hybrid and AsusMuxDgpu modes
- Integrated mode (Intel iGPU only) is untested and may not work correctly
- If you need Integrated mode support, please open an issue with your testing results

### Mode Persistence

**Important:** GPU mode changes require:
1. Running the switch command (CLI or tray)
2. **Rebooting the system**
3. The BIOS MUX switch changes during reboot

If your system stays in Hybrid mode after reboot:
- Check `/etc/supergfxd.conf` - may need manual editing
- Check BIOS settings for GPU switching options
- See [Troubleshooting](#troubleshooting) section below

## 🐛 Troubleshooting

<details>
<summary><b>Brightness doesn't work after switching modes</b></summary>

1. Verify you rebooted after switching
2. Run diagnostics: `brightness-check.sh`
3. Check backlight interface: `ls /sys/class/backlight/`
4. Check boot params: `cat /proc/cmdline`

**Solution:** Re-apply configuration:
```bash
sudo supergfxctl -m $(supergfxctl -g)
sudo reboot
```
</details>

<details>
<summary><b>Permission denied when changing brightness</b></summary>

Check if you're in the `video` group:
```bash
groups | grep video
```

If not, add yourself:
```bash
sudo usermod -aG video $USER
```
Then logout and login (or reboot).
</details>

<details>
<summary><b>Wrapper not working after supergfxctl update</b></summary>

The pacman hook should restore it automatically. If not:
```bash
sudo brightness-restore.sh
```
</details>

<details>
<summary><b>Boot entries not regenerating</b></summary>

Manually trigger regeneration:
```bash
sudo reinstall-kernels
```

Verify boot entry:
```bash
cat /boot/loader/entries/*.conf | grep options
```
</details>

## 🧪 Tested On

- ✅ Arch Linux with CachyOS kernel 6.18.2
- ✅ EndeavourOS with standard kernel
- ✅ ASUS ROG laptops with RTX 4000 series + Intel iGPU
- ✅ systemd-boot bootloader
- ✅ supergfxctl 5.x
- ✅ KDE Plasma 6 with supergfxctl plasmoid

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Credits

- [ASUS Linux Community](https://asus-linux.org/) - asusctl and supergfxctl projects
- [Arch Linux Wiki](https://wiki.archlinux.org/) - Comprehensive documentation
- All contributors and testers

## ⭐ Star History

If this helped you, consider giving it a star! ⭐

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/brightness-fix-asus-linux/issues)
- **Discussions:** [GitHub Discussions](https://github.com/YOUR_USERNAME/brightness-fix-asus-linux/discussions)
- **ASUS Linux Discord:** [Join here](https://asus-linux.org/discord)

---

Made with ❤️ for the ASUS Linux community
