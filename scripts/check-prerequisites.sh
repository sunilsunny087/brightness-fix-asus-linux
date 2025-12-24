#!/bin/bash
# Quick prerequisite checker

echo "Checking prerequisites for brightness-fix..."
echo ""

ISSUES=0

if command -v supergfxctl &> /dev/null; then
    echo "✓ supergfxctl found"
else
    echo "✗ supergfxctl not found"
    ((ISSUES++))
fi

if command -v reinstall-kernels &> /dev/null; then
    echo "✓ reinstall-kernels found"
else
    echo "✗ reinstall-kernels not found"
    ((ISSUES++))
fi

if [ -f /usr/lib/systemd/boot/efi/systemd-bootx64.efi ]; then
    echo "✓ systemd-boot found"
else
    echo "⚠ systemd-boot might not be installed"
fi

if [ $ISSUES -eq 0 ]; then
    echo ""
    echo "✅ All prerequisites met! Ready to install."
else
    echo ""
    echo "❌ Missing $ISSUES prerequisite(s). Install them first."
fi
