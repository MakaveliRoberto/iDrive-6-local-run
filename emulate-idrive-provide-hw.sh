#!/bin/bash

# Provide fake hardware via QEMU device tree or custom devices
# Make QEMU report hardware that QNX expects

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎭 Provide Fake Hardware to QNX"
echo "=========================================="
echo ""
echo "Strategy: Make QEMU provide hardware QNX checks for"
echo ""

# Try with device tree (if we can create one)
# QNX might read hardware info from device tree

echo "Method 1: Enhanced virt machine with all devices..."
qemu-system-arm \
    -M virt,accel=tcg \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -device virtio-net-device,netdev=net0 \
    -netdev user,id=net0 \
    -device virtio-rng \
    -device virtio-balloon \
    -device virtio-serial \
    -device virtio-gpu-pci \
    -device virtio-input \
    -chardev stdio,id=serial0 \
    -device virtconsole,chardev=serial0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors 2>&1 | head -200 &
PID1=$!
sleep 30
kill $PID1 2>/dev/null || true
wait $PID1 2>/dev/null || true

echo ""
echo "Method 2: Try with QEMU monitor to inject hardware responses..."
echo "This would require QEMU monitor commands to set register values"
echo ""

echo "Method 3: Create custom QEMU device (advanced - requires QEMU source)"
echo ""

