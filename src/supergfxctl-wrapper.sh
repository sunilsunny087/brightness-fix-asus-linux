#!/bin/bash

# Override --supported to show all possible modes (not just currently available)
# The plasmoid needs to see all modes to allow switching
if [[ "$1" == "--supported" || "$1" == "-s" ]]; then
    echo "[Hybrid, AsusMuxDgpu]"
    exit 0
fi

# Run the original supergfxctl command with all arguments
/usr/bin/supergfxctl-original "$@"
SUPERGFX_EXIT_CODE=$?

# If the command was a mode switch (-m or --mode), adjust boot parameters
if [[ "$1" == "-m" || "$1" == "--mode" ]]; then
    NEW_MODE="$2"

    CMDLINE_FILE="/etc/kernel/cmdline"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Adjusting boot parameters for $NEW_MODE mode..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if we have root permissions
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  Root permissions required for boot parameter changes"
        echo "Please run: sudo supergfxctl -m $NEW_MODE"
        exit 1
    fi

    if [[ "$NEW_MODE" == "AsusMuxDgpu" ]]; then
        # Add acpi_backlight=native if not present
        if ! grep -q "acpi_backlight=native" "$CMDLINE_FILE"; then
            sed -i 's/$/ acpi_backlight=native/' "$CMDLINE_FILE"
            echo "✓ Added acpi_backlight=native for nvidia_0 backlight"
        else
            echo "✓ acpi_backlight=native already present"
        fi

    elif [[ "$NEW_MODE" == "Hybrid" || "$NEW_MODE" == "Integrated" ]]; then
        # Remove acpi_backlight=native if present
        if grep -q "acpi_backlight=native" "$CMDLINE_FILE"; then
            sed -i 's/ acpi_backlight=native//g' "$CMDLINE_FILE"
            echo "✓ Removed acpi_backlight=native for nvidia_wmi_ec_backlight"
        else
            echo "✓ acpi_backlight=native already absent"
        fi
    fi

    # Regenerate boot entries
    echo "🔄 Regenerating boot entries..."
    reinstall-kernels 2>&1 | grep -E "(Installing|Generating)" || reinstall-kernels
    echo "✓ Boot configuration updated"
    echo ""
    echo "⚠️  Reboot required for brightness changes to take effect"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

# Return the original exit code
exit $SUPERGFX_EXIT_CODE
