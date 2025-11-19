#!/bin/bash

# Try to fake hardware registers that QNX might be checking
# Create virtual devices that QNX expects

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎭 QNX iDrive 6 - Fake Hardware"
echo "=========================================="
echo ""
echo "Attempting to provide fake hardware that QNX expects..."
echo ""

# Try with more devices that might help
qemu-system-arm \
    -M virt \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -device virtio-net-device,netdev=net0 \
    -device virtio-rng \
    -device virtio-balloon \
    -device virtio-serial \
    -chardev stdio,id=serial0 \
    -device virtconsole,chardev=serial0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors,unimp 2>&1 | grep -v "Trace\|Linking TBs" | head -200

