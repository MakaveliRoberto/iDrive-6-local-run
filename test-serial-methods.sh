#!/bin/bash

# Test different serial output methods systematically

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🔍 Testing Serial Output Methods"
echo "=========================================="
echo ""

# Method 1: Standard stdio
echo "Method 1: Standard stdio serial..."
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -serial stdio \
    -display none \
    -no-reboot 2>&1 | head -50 &
PID1=$!
sleep 20
kill $PID1 2>/dev/null || true
wait $PID1 2>/dev/null || true

echo ""
echo "Method 2: Chardev stdio..."
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -chardev stdio,id=serial0 \
    -serial chardev:serial0 \
    -display none \
    -no-reboot 2>&1 | head -50 &
PID2=$!
sleep 20
kill $PID2 2>/dev/null || true
wait $PID2 2>/dev/null || true

echo ""
echo "Method 3: File output + stdio..."
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -serial stdio \
    -serial file:serial-test.log \
    -display none \
    -no-reboot 2>&1 | head -50 &
PID3=$!
sleep 20
if [ -f serial-test.log ]; then
    echo "File output found:"
    cat serial-test.log
    rm -f serial-test.log
fi
kill $PID3 2>/dev/null || true
wait $PID3 2>/dev/null || true

echo ""
echo "Method 4: Telnet serial..."
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -serial telnet:localhost:4446,server,nowait \
    -display none \
    -no-reboot 2>&1 | head -50 &
PID4=$!
sleep 5
echo "Serial available on: telnet localhost 4446"
sleep 15
kill $PID4 2>/dev/null || true
wait $PID4 2>/dev/null || true

echo ""
echo "Method 5: Try vexpress-a15 (different hardware)..."
qemu-system-arm \
    -M vexpress-a15 \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=sd,format=raw,cache=writeback \
    -serial stdio \
    -display none \
    -no-reboot 2>&1 | head -50

echo ""
echo "=========================================="
echo "Testing complete!"
echo "=========================================="

