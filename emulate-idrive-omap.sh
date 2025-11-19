#!/bin/bash

# Try to use OMAP-specific machine if available
# Or configure virt to better match OMAP5430

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎯 QNX iDrive 6 - OMAP5430 Attempt"
echo "=========================================="
echo ""
echo "Checking for OMAP machine support..."
echo ""

# Check if QEMU supports OMAP machines
if qemu-system-arm -M help 2>&1 | grep -qi "omap"; then
    echo "✅ Found OMAP machine support!"
    OMAP_MACHINE=$(qemu-system-arm -M help 2>&1 | grep -i "omap" | head -1 | awk '{print $1}')
    echo "Using: $OMAP_MACHINE"
    echo ""
    
    # sx1 only supports 1 CPU
    if [ "$OMAP_MACHINE" = "sx1" ] || [ "$OMAP_MACHINE" = "sx1-v1" ]; then
        SMP=1
        CPU="arm1136"
    else
        SMP=2
        CPU="cortex-a15"
    fi
    
    qemu-system-arm \
        -M "$OMAP_MACHINE" \
        -cpu "$CPU" \
        -m 2048 \
        -smp "$SMP" \
        -kernel "$BOOT_IMAGE" \
        -drive file="$DISK_IMAGE",if=sd,format=raw \
        -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
        -device virtio-net-device,netdev=net0 \
        -serial stdio \
        -display none \
        -no-reboot
else
    echo "❌ No OMAP machine found in QEMU"
    echo ""
    echo "Available ARM machines:"
    qemu-system-arm -M help 2>&1 | grep -E "^[a-z]" | head -20
    echo ""
    echo "Trying with versatilepb (closer to real hardware)..."
    echo ""
    
    # VersatilePB is closer to real hardware than virt
    # Note: versatilepb uses ARM926EJ-S, not Cortex-A15
    echo "Trying versatilepb with ARM926EJ-S CPU..."
    qemu-system-arm \
        -M versatilepb \
        -cpu arm926 \
        -m 2048 \
        -kernel "$BOOT_IMAGE" \
        -drive file="$DISK_IMAGE",if=sd,format=raw \
        -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
        -device rtl8139,netdev=net0 \
        -serial stdio \
        -display none \
        -no-reboot
    
    echo ""
    echo "If that didn't work, trying vexpress-a15 (what we've been using)..."
    echo "The issue is likely OMAP5430-specific instructions"
    echo "that need custom QEMU support or patching."
fi

