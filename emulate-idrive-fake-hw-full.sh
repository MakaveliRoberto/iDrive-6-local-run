#!/bin/bash

# Full fake hardware setup - provide all devices QNX might expect

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎭 Full Fake Hardware Setup"
echo "=========================================="
echo ""
echo "Providing maximum hardware to QNX:"
echo "  • Fake OMAP5430 CPU ID"
echo "  • Multiple virtio devices"
echo "  • RNG, Balloon, Serial, etc."
echo "  • All devices QNX might check for"
echo ""

# Maximum hardware - give QNX everything it might want
qemu-system-arm \
    -M virt \
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
    -device virtio-blk-device,drive=drive0 \
    -drive id=drive0,file="$DISK_IMAGE",if=none,format=raw \
    -chardev stdio,id=serial0 \
    -device virtconsole,chardev=serial0 \
    -serial stdio \
    -display none \
    -no-reboot 2>&1

