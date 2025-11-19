#!/bin/bash

# Verbose QNX boot with debug output
# This shows detailed boot messages to diagnose issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "QNX iDrive 6 - Verbose Boot"
echo "=========================================="
echo ""
echo "This will show detailed QEMU/QNX boot output"
echo ""

# Create log file
LOG_FILE="$SCRIPT_DIR/emulation/boot-log-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$SCRIPT_DIR/emulation"
echo "Log file: $LOG_FILE"
echo ""

# Verbose boot with all debug options
qemu-system-arm \
    -M vexpress-a15 \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=sd,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d unimp,guest_errors,int,exec \
    -D "$LOG_FILE" \
    2>&1 | tee "$LOG_FILE"

