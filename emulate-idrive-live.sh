#!/bin/bash

# Live boot with visible output - see what's actually happening!

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🚀 QNX iDrive 6 - LIVE BOOT"
echo "=========================================="
echo ""
echo "This will show live boot output!"
echo "Watch for QNX kernel messages..."
echo ""
echo "Starting in 2 seconds..."
sleep 2
echo ""
echo "=========================================="
echo ""

# Boot with virt machine, visible output, no head limit
qemu-system-arm \
    -M virt \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d unimp,guest_errors,int,exec 2>&1

