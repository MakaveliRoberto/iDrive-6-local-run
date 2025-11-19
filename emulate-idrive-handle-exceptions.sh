#!/bin/bash

# Handle undefined instructions - try to continue execution
# Some QNX code may use OMAP-specific instructions that virt doesn't support

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🔧 QNX iDrive 6 - Exception Handling"
echo "=========================================="
echo ""
echo "Attempting to handle undefined instructions..."
echo "The system may hit OMAP-specific code paths"
echo ""

# Try with different exception handling
# -singlestep might help us see where it fails
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
    -d guest_errors,unimp 2>&1 | grep -v "Trace\|Linking TBs" | head -200

