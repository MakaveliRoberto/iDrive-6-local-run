#!/bin/bash

# Clean boot - minimal debug, capture serial output

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🚀 QNX iDrive 6 - CLEAN BOOT"
echo "=========================================="
echo ""
echo "Booting with minimal debug output..."
echo "Serial console output only (no QEMU traces)"
echo ""
echo "Press Ctrl+A then X to quit"
echo ""

# Clean boot - no debug flags, just serial output
qemu-system-arm \
    -M virt \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -monitor none 2>&1

