#!/bin/bash

# BEST configuration - combines all workarounds:
# 1. Fake OMAP5430 CPU ID
# 2. Hardware checks removed from scripts
# 3. Optimal QEMU configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🚀 iDrive 6 - BEST Configuration"
echo "=========================================="
echo ""
echo "Combining all workarounds:"
echo "  ✅ Fake OMAP5430 CPU ID (0x412fc0f1)"
echo "  ✅ Hardware checks removed from scripts"
echo "  ✅ Optimized QEMU settings"
echo ""
echo "This is our best shot at getting boot messages!"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "=========================================="
echo ""

# Best configuration with all workarounds
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8102-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot 2>&1

