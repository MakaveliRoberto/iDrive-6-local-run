#!/bin/bash

# Try to force boot output with different console configurations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🔍 iDrive 6 - Force Boot Output"
echo "=========================================="
echo ""
echo "Trying multiple methods to get boot messages..."
echo ""

# Method 1: Try with early console
echo "Method 1: Early console + append parameters..."
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -append "console=ttyAMA0,115200 earlyprintk=serial,ttyAMA0,115200" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -chardev stdio,id=serial0 \
    -serial chardev:serial0 \
    -display none \
    -no-reboot 2>&1 | head -200 &
PID1=$!
sleep 30
kill $PID1 2>/dev/null || true
wait $PID1 2>/dev/null || true

echo ""
echo "Method 2: Multiple serial ports..."
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -serial stdio \
    -serial file:serial-output.log \
    -display none \
    -no-reboot 2>&1 | head -200 &
PID2=$!
sleep 30
if [ -f serial-output.log ]; then
    echo "Serial output log:"
    cat serial-output.log
    rm -f serial-output.log
fi
kill $PID2 2>/dev/null || true
wait $PID2 2>/dev/null || true

echo ""
echo "Method 3: Try vexpress-a15 (different hardware model)..."
qemu-system-arm \
    -M vexpress-a15 \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=sd,format=raw,cache=writeback \
    -serial stdio \
    -display none \
    -no-reboot 2>&1 | head -200

echo ""
echo "=========================================="
echo "If any method showed boot messages, that's the one to use!"
echo "=========================================="

