# Contributing to Brightness Fix

Thank you for considering contributing! This document outlines the process.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/YOUR_USERNAME/brightness-fix-asus-linux/issues)
2. Create a new issue with:
   - Clear title
   - System information (`uname -a`, GPU model, supergfxctl version)
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs (`journalctl -u supergfxd -b`)

### Suggesting Features

1. Open an issue with `[Feature Request]` in the title
2. Describe the feature and use case
3. Explain why it would be useful

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test thoroughly on your system
5. Update documentation if needed
6. Commit with clear messages
7. Push and create a PR

### Code Style

- Use bash for scripts
- Follow existing formatting
- Add comments for complex logic
- Include error handling
- Test on Arch Linux

### Testing Checklist

Before submitting PR:
- [ ] Tested on fresh Arch install
- [ ] Tested GPU mode switching (Hybrid ↔ dGPU)
- [ ] Brightness controls work in both modes
- [ ] Survives reboot
- [ ] `brightness-check.sh` passes all checks
- [ ] No errors in `journalctl -u supergfxd`
