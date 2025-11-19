#!/bin/bash

# FINAL BEST - No network to avoid port conflicts
# Focus on getting boot messages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🚀 iDrive 6 - FINAL BEST Configuration"
echo "=========================================="
echo ""
echo "All workarounds active:"
echo "  ✅ Fake OMAP5430 CPU ID (0x412fc0f1)"
echo "  ✅ Hardware checks removed"
echo "  ✅ No network (avoiding port conflicts)"
echo ""
echo "Focus: Get boot messages!"
echo ""
echo "=========================================="
echo ""

# Best config - no network to avoid conflicts
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -serial stdio \
    -display none \
    -no-reboot 2>&1

