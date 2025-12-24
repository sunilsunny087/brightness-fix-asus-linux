#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Brightness Configuration Integrity Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ISSUES=0

# Check 1: Wrapper exists
if [ -f /usr/bin/supergfxctl ]; then
    echo "✓ supergfxctl wrapper exists"
else
    echo "✗ supergfxctl wrapper MISSING"
    ((ISSUES++))
fi

# Check 2: Original binary exists
if [ -f /usr/bin/supergfxctl-original ]; then
    echo "✓ supergfxctl-original exists"
else
    echo "✗ supergfxctl-original MISSING"
    ((ISSUES++))
fi

# Check 3: Backup exists
if [ -f /usr/local/bin/supergfxctl-wrapper.sh ]; then
    echo "✓ Wrapper backup exists"
else
    echo "✗ Wrapper backup MISSING"
    ((ISSUES++))
fi

# Check 4: Base cmdline exists
if [ -f /etc/kernel/cmdline ]; then
    echo "✓ /etc/kernel/cmdline exists"

    # Check 5: Required parameters
    if grep -q "nvidia.NVreg_EnableBacklightHandler=1" /etc/kernel/cmdline; then
        echo "✓ NVIDIA backlight handler enabled"
    else
        echo "✗ NVIDIA backlight handler MISSING"
        ((ISSUES++))
    fi

    # Check 6: GPU mode vs cmdline consistency
    GPU_MODE=$(supergfxctl -g 2>/dev/null)
    if [[ "$GPU_MODE" == *"Dgpu"* ]]; then
        if grep -q "acpi_backlight=native" /etc/kernel/cmdline; then
            echo "✓ dGPU mode: acpi_backlight=native present"
        else
            echo "⚠ dGPU mode but acpi_backlight=native MISSING"
            echo "  Run: sudo supergfxctl -m AsusMuxDgpu"
            ((ISSUES++))
        fi
    else
        if grep -q "acpi_backlight=native" /etc/kernel/cmdline; then
            echo "⚠ Hybrid/Integrated mode but acpi_backlight=native present"
            echo "  Run: sudo supergfxctl -m Hybrid"
            ((ISSUES++))
        else
            echo "✓ Hybrid/Integrated mode: acpi_backlight=native absent"
        fi
    fi
else
    echo "✗ /etc/kernel/cmdline MISSING"
    ((ISSUES++))
fi

# Check 7: Udev rules
if [ -f /etc/udev/rules.d/90-backlight.rules ]; then
    echo "✓ Backlight udev rules exist"
else
    echo "✗ Backlight udev rules MISSING"
    ((ISSUES++))
fi

# Check 8: Pacman hooks
HOOKS_OK=0
if [ -f /etc/pacman.d/hooks/supergfxctl-wrapper.hook ]; then
    ((HOOKS_OK++))
fi
echo "✓ $HOOKS_OK pacman hooks installed"

# Check 9: Current backlight interface
if [ -d /sys/class/backlight ]; then
    BACKLIGHT=$(ls /sys/class/backlight/ 2>/dev/null | head -n1)
    if [ -n "$BACKLIGHT" ]; then
        echo "✓ Active backlight: $BACKLIGHT"

        # Check permissions
        if [ -w /sys/class/backlight/$BACKLIGHT/brightness ]; then
            echo "✓ Backlight is writable (permissions OK)"
        else
            echo "⚠ Backlight NOT writable (permissions issue)"
            echo "  Run: sudo udevadm control --reload-rules && sudo udevadm trigger"
            ((ISSUES++))
        fi
    else
        echo "⚠ No backlight interface found"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ISSUES -eq 0 ]; then
    echo "✅ All checks passed! Configuration is healthy."
else
    echo "⚠️  Found $ISSUES issue(s). Review above for details."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
