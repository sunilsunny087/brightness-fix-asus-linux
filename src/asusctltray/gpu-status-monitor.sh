#!/bin/bash
# GPU Status Monitor - Restarts asusctltray when GPU power state changes
# Uses efficient polling since inotify doesn't work on sysfs files

# Find the NVIDIA GPU device path - try direct path first
GPU_DEVICE="/sys/bus/pci/devices/0000:01:00.0"

# If direct path doesn't exist, search for NVIDIA device
if [ ! -d "$GPU_DEVICE" ]; then
    for dev in /sys/bus/pci/devices/*; do
        if [ -f "$dev/vendor" ] && grep -q "0x10de" "$dev/vendor" 2>/dev/null; then
            GPU_DEVICE="$dev"
            break
        fi
    done
fi

if [ -z "$GPU_DEVICE" ]; then
    echo "Error: Could not find NVIDIA GPU device"
    exit 1
fi

POWER_STATUS_FILE="${GPU_DEVICE}/power/runtime_status"

if [ ! -f "$POWER_STATUS_FILE" ]; then
    echo "Error: Power status file not found at $POWER_STATUS_FILE"
    exit 1
fi

echo "Monitoring GPU power status at: $POWER_STATUS_FILE"
echo "Started GPU status monitor for asusctltray"

LAST_STATUS=$(cat "$POWER_STATUS_FILE" 2>/dev/null)
echo "Initial GPU status: $LAST_STATUS"

# Poll every 2 seconds (more efficient than asusctltray's 250ms polling)
while true; do
    CURRENT_STATUS=$(cat "$POWER_STATUS_FILE" 2>/dev/null)

    # Only restart if status actually changed
    if [ "$CURRENT_STATUS" != "$LAST_STATUS" ] && [ -n "$CURRENT_STATUS" ]; then
        echo "[$(date '+%H:%M:%S')] GPU status changed: $LAST_STATUS -> $CURRENT_STATUS"

        # Restart asusctltray if it's running (it's a Python script)
        if pgrep -f "asusctltray" > /dev/null; then
            pkill -f "asusctltray"
            sleep 1

            # Start asusctltray in the background
            asusctltray >/dev/null 2>&1 &

            echo "[$(date '+%H:%M:%S')] Restarted asusctltray"
        fi

        LAST_STATUS="$CURRENT_STATUS"
    fi

    sleep 2
done
