#!/bin/bash

# Capture ALL output - maybe boot messages are going somewhere else

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"
LOG_DIR="$SCRIPT_DIR/emulation"
LOG_FILE="$LOG_DIR/full-capture-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"

echo "=========================================="
echo "📹 QNX iDrive 6 - Full Capture"
echo "=========================================="
echo ""
echo "Capturing ALL output to: $LOG_FILE"
echo "Running for 3 minutes..."
echo ""

# Capture everything - stdout, stderr, serial, everything
{
    qemu-system-arm \
        -M virt \
        -cpu cortex-a15 \
        -m 2048 \
        -smp 2 \
        -kernel "$BOOT_IMAGE" \
        -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
        -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8100-:80 \
        -device virtio-net-device,netdev=net0 \
        -serial stdio \
        -monitor telnet:localhost:4445,server,nowait \
        -display none \
        -no-reboot \
        -d guest_errors,unimp 2>&1
} | tee "$LOG_FILE" &
QEMU_PID=$!

# Wait 3 minutes
for i in {1..180}; do
    if ! ps -p $QEMU_PID >/dev/null 2>&1; then
        echo ""
        echo "QEMU ended at $i seconds"
        break
    fi
    sleep 1
    if [ $((i % 30)) -eq 0 ]; then
        echo "[$i seconds] Still running..."
    fi
done

if ps -p $QEMU_PID >/dev/null 2>&1; then
    echo ""
    echo "✅ Still running after 3 minutes!"
    kill $QEMU_PID 2>/dev/null || true
    wait $QEMU_PID 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo "Analysis:"
echo "=========================================="
echo ""
echo "Main log: $LOG_FILE"
echo "Serial2 log: $LOG_DIR/serial2.log"
echo ""
echo "Checking for any messages..."
echo ""

if [ -f "$LOG_FILE" ]; then
    echo "Main log size: $(wc -l < "$LOG_FILE") lines"
    grep -v "Trace\|Linking TBs" "$LOG_FILE" | tail -20
fi

if [ -f "$LOG_DIR/serial2.log" ]; then
    echo ""
    echo "Serial2 log size: $(wc -l < "$LOG_DIR/serial2.log") lines"
    tail -20 "$LOG_DIR/serial2.log"
fi

echo ""
echo "=========================================="

