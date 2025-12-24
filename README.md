# 🔆 Arch Linux Brightness Fix for ASUS Laptops

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?logo=arch-linux&logoColor=fff)](https://archlinux.org/)
[![Tested on EndeavourOS](https://img.shields.io/badge/EndeavourOS-7F7FFF?logo=endeavouros&logoColor=fff)](https://endeavouros.com/)

**Automatic brightness control solution for ASUS laptops with hybrid graphics (NVIDIA dGPU + Intel iGPU) using supergfxctl.**

## ✨ Features

- ✅ **Automatic boot parameter management** - Configures kernel parameters based on GPU mode
- ✅ **Zero manual configuration** - One command installation, works immediately
- ✅ **Update-proof** - Survives kernel updates, driver updates, and package upgrades
- ✅ **Universal compatibility** - Works with CLI, KDE plasmoid, and system tray
- ✅ **Intelligent wrapper** - Detects GPU mode and adjusts configuration automatically
- ✅ **Self-healing** - Includes monitoring and recovery tools

## 🎯 Problem Statement

On ASUS laptops with hybrid graphics, brightness controls stop working when switching between GPU modes:

- **dGPU mode** requires `nvidia_0` backlight interface (needs `acpi_backlight=native` kernel parameter)
- **Hybrid mode** requires `nvidia_wmi_ec_backlight` interface (needs NO `acpi_backlight=native`)

Without proper configuration, brightness keys, desktop environment sliders, and manual brightness control all fail.

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

**Command Line (Recommended):**
```bash
# Switch to Hybrid mode
sudo supergfxctl -m Hybrid
sudo reboot

# Switch to dGPU mode  
sudo supergfxctl -m AsusMuxDgpu
sudo reboot
```

**Via KDE Plasmoid or System Tray:**
1. Click the GPU widget
2. Select desired mode
3. Reboot when prompted

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
