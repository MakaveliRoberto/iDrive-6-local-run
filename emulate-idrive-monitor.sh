#!/bin/bash

# Use QEMU monitor to inspect system state and potentially bypass checks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🔍 QNX iDrive 6 - Monitor Mode"
echo "=========================================="
echo ""
echo "Starting QEMU with monitor for inspection..."
echo "Connect to monitor: telnet localhost 4444"
echo ""

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
    -monitor telnet:localhost:4444,server,nowait \
    -display none \
    -no-reboot 2>&1

