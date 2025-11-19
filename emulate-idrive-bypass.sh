#!/bin/bash

# Try to bypass hardware checks using QEMU features
# Attempt different CPU IDs and machine configurations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎭 QNX iDrive 6 - Hardware Bypass Attempt"
echo "=========================================="
echo ""
echo "Trying to trick the kernel into thinking it's on OMAP5430..."
echo ""

# Method 1: Try with CPU ID override (if QEMU supports it)
echo "Method 1: CPU ID manipulation..."
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors 2>&1 | head -100 &
PID1=$!
sleep 20
kill $PID1 2>/dev/null || true
wait $PID1 2>/dev/null || true

echo ""
echo "Method 2: Try with device tree (if we can create one)..."
# Note: Would need a device tree blob for OMAP5430
echo "Skipping - would need DTB file"
echo ""

echo "Method 3: Try with different machine that's closer to OMAP..."
qemu-system-arm \
    -M vexpress-a15 \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=sd,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors 2>&1 | head -100

