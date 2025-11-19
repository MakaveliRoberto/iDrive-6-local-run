#!/bin/bash

# Minimal boot - just kernel, no disk, see if kernel loads

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT_IMAGE="$SCRIPT_DIR/nbtevo-system-dump/sda2/boot1.ifs"

echo "=========================================="
echo "🔬 QNX iDrive 6 - MINIMAL BOOT TEST"
echo "=========================================="
echo ""
echo "Booting kernel only (no disk) to see if it loads..."
echo "This helps isolate if the issue is kernel vs filesystem"
echo ""
echo "Starting..."
echo ""

# Just boot the kernel - no disk, minimal config
qemu-system-arm \
    -M virt \
    -cpu cortex-a15 \
    -m 2048 \
    -kernel "$BOOT_IMAGE" \
    -serial stdio \
    -display none \
    -no-reboot \
    -append "console=ttyAMA0" 2>&1

