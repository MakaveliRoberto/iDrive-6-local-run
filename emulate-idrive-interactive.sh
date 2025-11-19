#!/bin/bash

# Interactive boot with QEMU monitor - we can inject commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎮 Interactive iDrive Boot"
echo "=========================================="
echo ""
echo "Starting with QEMU monitor..."
echo "You can connect to monitor: telnet localhost:4447"
echo ""
echo "Monitor commands you can try:"
echo "  info registers - See CPU state"
echo "  info qtree - See device tree"
echo "  x/10i \$pc - Disassemble current code"
echo "  cont - Continue execution"
echo ""

qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -device virtio-net-device,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8095-:80 \
    -serial stdio \
    -monitor telnet:localhost:4447,server,nowait \
    -display none \
    -no-reboot 2>&1

