#!/bin/bash

# FINAL ATTEMPT - Using all available boot components
# This tries multiple approaches including BIOS packet

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
BIOS_PACKET="$DUMP_DIR/sda2/arm-cortexA15_bios_packet.bin"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎯 QNX iDrive 6 - FINAL BOOT ATTEMPT"
echo "=========================================="
echo ""
echo "Using all available boot components:"
echo "  • Boot Image: boot1.ifs (QNX IFS)"
echo "  • BIOS Packet: arm-cortexA15_bios_packet.bin"
echo "  • Machine: virt (generic ARM)"
echo "  • CPU: Cortex-A15"
echo ""
echo "Starting boot with verbose output..."
echo ""
echo "=========================================="
echo ""

# Try with BIOS packet - maybe it's needed for hardware initialization
qemu-system-arm \
    -M virt \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -device loader,file="$BIOS_PACKET",addr=0x0 \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d unimp,guest_errors,int,exec 2>&1

