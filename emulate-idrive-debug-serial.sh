#!/bin/bash

# Debug serial output with maximum verbosity

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🔍 Debug Serial Output"
echo "=========================================="
echo ""
echo "Running with maximum debug output..."
echo "Watch for ANY messages..."
echo ""
echo "=========================================="
echo ""

# Maximum debug - capture everything
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -serial stdio \
    -monitor stdio \
    -display none \
    -no-reboot \
    -d guest_errors,unimp,int,exec 2>&1 | tee emulation/debug-serial-$(date +%Y%m%d-%H%M%S).log

