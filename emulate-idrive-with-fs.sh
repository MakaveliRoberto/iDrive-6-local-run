#!/bin/bash

# Try to boot with filesystem access - maybe we can get it to mount

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🚀 iDrive 6 - With Filesystem Access"
echo "=========================================="
echo ""
echo "Trying to provide filesystem access..."
echo ""

# Try with 9p virtfs to share host filesystem
# This might allow QNX to access the filesystem

qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -fsdev local,id=fsdev0,path="$DUMP_DIR/sda0",security_model=none \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare \
    -device virtio-net-device,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -serial stdio \
    -display none \
    -no-reboot 2>&1

