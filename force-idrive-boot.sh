#!/bin/bash

# Force iDrive to boot fully - try everything to get it running

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🚀 FORCE iDrive 6 FULL BOOT"
echo "=========================================="
echo ""
echo "This will try EVERYTHING to get iDrive running!"
echo ""

# Try with maximum hardware support and verbose output
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -device virtio-net-device,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -device virtio-rng \
    -device virtio-balloon \
    -device virtio-serial \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors,unimp,int,exec 2>&1 | tee emulation/force-boot-$(date +%Y%m%d-%H%M%S).log

