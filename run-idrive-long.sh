#!/bin/bash

# Run iDrive emulation for extended period to capture boot messages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/emulation/boot-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$SCRIPT_DIR/emulation"

echo "=========================================="
echo "🚀 iDrive 6 - Extended Boot Test"
echo "=========================================="
echo ""
echo "Running for 2 minutes to capture boot messages..."
echo "Log file: $LOG_FILE"
echo ""
echo "Press Ctrl+C to stop early"
echo ""
echo "=========================================="
echo ""

# Run and log everything
./emulate-idrive-clean.sh 2>&1 | tee "$LOG_FILE" &
BOOT_PID=$!

# Wait 2 minutes
for i in {1..120}; do
    if ! ps -p $BOOT_PID >/dev/null 2>&1; then
        echo ""
        echo "QEMU process ended"
        break
    fi
    sleep 1
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "."
    fi
done

echo ""
echo ""

if ps -p $BOOT_PID >/dev/null 2>&1; then
    echo "✅ QEMU still running after 2 minutes!"
    echo ""
    echo "Checking log for boot messages..."
    echo ""
    grep -v "Trace\|Linking TBs" "$LOG_FILE" | tail -50
    echo ""
    echo "Full log: $LOG_FILE"
    echo ""
    echo "Killing QEMU..."
    kill $BOOT_PID 2>/dev/null || true
    wait $BOOT_PID 2>/dev/null || true
else
    echo "QEMU process ended. Check log: $LOG_FILE"
    wait $BOOT_PID 2>/dev/null || true
fi

echo ""
echo "=========================================="

