#!/bin/bash

# Run iDrive for as long as it takes - maybe it will eventually boot

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "⏳ iDrive 6 - Run Until It Boots"
echo "=========================================="
echo ""
echo "Running for as long as it takes..."
echo "The kernel is executing - maybe it needs time to break through hardware checks"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "=========================================="
echo ""

LOG_FILE="$SCRIPT_DIR/emulation/forever-boot-$(date +%Y%m%d-%H%M%S).log"

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
    -display none \
    -no-reboot 2>&1 | tee "$LOG_FILE" &
QEMU_PID=$!

echo "QEMU started (PID: $QEMU_PID)"
echo "Log file: $LOG_FILE"
echo ""
echo "Monitoring for boot messages..."
echo ""

# Monitor for a very long time
for i in {1..3600}; do
    if ! ps -p $QEMU_PID >/dev/null 2>&1; then
        echo ""
        echo "QEMU ended at $i seconds"
        break
    fi
    
    # Check every minute for boot messages
    if [ $((i % 60)) -eq 0 ]; then
        MIN=$((i/60))
        echo "[$MIN min] Still running..."
        
        # Check log for any new messages
        if [ -f "$LOG_FILE" ]; then
            NEW_LINES=$(tail -10 "$LOG_FILE" 2>/dev/null | grep -v "Trace\|Linking\|qemu" | wc -l)
            if [ "$NEW_LINES" -gt 0 ]; then
                echo "  ⚠️  Found potential boot messages!"
                tail -10 "$LOG_FILE" | grep -v "Trace\|Linking" | tail -5
            fi
        fi
        
        # Check if network ports opened (services started)
        if lsof -ti:8095 >/dev/null 2>&1 || lsof -ti:8022 >/dev/null 2>&1; then
            echo "  🎉 SERVICES STARTED! Ports are listening!"
            echo "  Check http://localhost:8095"
        fi
    fi
    
    sleep 1
done

if ps -p $QEMU_PID >/dev/null 2>&1; then
    echo ""
    echo "Still running after 1 hour!"
    echo "Check log: $LOG_FILE"
    echo "Keeping it running..."
    echo "To stop: kill $QEMU_PID"
fi

