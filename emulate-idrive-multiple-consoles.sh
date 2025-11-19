#!/bin/bash

# Try multiple console outputs simultaneously

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "📺 Multiple Console Output Test"
echo "=========================================="
echo ""
echo "Trying to capture output from multiple sources..."
echo ""

# Try with multiple serial ports
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -chardev stdio,id=console0 \
    -serial chardev:console0 \
    -chardev file,path=console1.log,id=console1 \
    -serial chardev:console1 \
    -display none \
    -no-reboot 2>&1 | tee console0.log &
PID=$!

echo "Running for 2 minutes..."
echo "Output going to:"
echo "  • stdout (console0.log)"
echo "  • console1.log"
echo ""

for i in {1..120}; do
    if ! ps -p $PID >/dev/null 2>&1; then
        echo "Ended at $i seconds"
        break
    fi
    sleep 1
    if [ $((i % 20)) -eq 0 ]; then
        echo "[$i sec] Running..."
        if [ -f console1.log ]; then
            SIZE=$(wc -c < console1.log 2>/dev/null || echo 0)
            if [ "$SIZE" -gt 0 ]; then
                echo "  ✅ console1.log has $SIZE bytes!"
                tail -5 console1.log
            fi
        fi
    fi
done

if ps -p $PID >/dev/null 2>&1; then
    echo ""
    echo "Still running - checking logs..."
    kill $PID 2>/dev/null || true
    wait $PID 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo "Log Analysis:"
echo "=========================================="
if [ -f console0.log ]; then
    echo "console0.log: $(wc -l < console0.log) lines"
    tail -20 console0.log
fi
if [ -f console1.log ]; then
    echo ""
    echo "console1.log: $(wc -l < console1.log) lines"
    tail -20 console1.log
fi
echo "=========================================="

