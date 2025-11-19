#!/bin/bash

# Fake OMAP5430 CPU ID and hardware registers
# Try to make QEMU report itself as OMAP5430

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎭 Fake OMAP5430 Hardware"
echo "=========================================="
echo ""
echo "OMAP5430 Specifications:"
echo "  • CPU: ARM Cortex-A15 dual-core @ 1.5GHz"
echo "  • CPU ID (MIDR): 0x412fc0f1"
echo "  • Architecture: ARMv7-A"
echo "  • Features: NEON, VFPv4"
echo ""

# OMAP5430 MIDR: 0x412fc0f1
# ARM (0x41) | Variant (0x2) | Architecture (0xf) | PartNum (0xc0f) | Revision (0x1)

echo "Attempting to configure QEMU as OMAP5430..."
echo ""

qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8101-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors 2>&1

echo ""
echo "If you saw any boot messages above, the CPU ID trick worked!"
echo ""

