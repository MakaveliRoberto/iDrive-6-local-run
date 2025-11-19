#!/bin/bash

# Debug where the kernel is stuck using QEMU gdb stub

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🔍 Debug Kernel - Find Where It's Stuck"
echo "=========================================="
echo ""
echo "Starting with GDB stub on port 1234"
echo "You can connect with: gdb-multiarch (or arm gdb)"
echo "  (gdb) target remote localhost:1234"
echo "  (gdb) continue"
echo "  (gdb) info registers"
echo ""

qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -device virtio-net-device,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -serial stdio \
    -display none \
    -no-reboot \
    -s -S \
    -d guest_errors,unimp 2>&1 | head -200

echo ""
echo "GDB stub running on port 1234"
echo "Connect with GDB to inspect kernel state"

