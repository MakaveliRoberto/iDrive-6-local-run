#!/bin/bash
# Launch QNX iDrive system in QEMU
# This is experimental and may not work without proper QNX runtime

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"

if [ ! -f "$DUMP_DIR/sda2/boot1.ifs" ]; then
    echo "Error: Boot images not found!"
    exit 1
fi

echo "=========================================="
echo "QNX iDrive 6 Emulation"
echo "=========================================="
echo ""
echo "WARNING: This is experimental."
echo "The system may not boot properly without:"
echo "  • Full OMAP5430 emulation"
echo "  • QNX runtime libraries"
echo "  • Proper hardware emulation"
echo ""
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

echo ""
echo "Starting QEMU ARM emulation..."
echo ""

# Attempt to boot with ARM Cortex-A15 emulation
# Note: OMAP5430 may not be fully emulated
qemu-system-arm \
  -M vexpress-a15 \
  -cpu cortex-a15 \
  -m 2048 \
  -kernel "$DUMP_DIR/sda2/boot1.ifs" \
  -drive file="$DUMP_DIR/sda2/boot1.ifs",if=sd,format=raw \
  -netdev user,id=net0,hostfwd=tcp::8022-:22 \
  -device virtio-net-device,netdev=net0 \
  -serial stdio \
  -nographic

# Alternative with graphics (uncomment if needed):
# qemu-system-arm \
#   -M vexpress-a15 \
#   -cpu cortex-a15 \
#   -m 2048 \
#   -kernel "$DUMP_DIR/sda2/boot1.ifs" \
#   -drive file="$DUMP_DIR/sda2/boot1.ifs",if=sd,format=raw \
#   -netdev user,id=net0 \
#   -device virtio-net-device,netdev=net0 \
#   -vga std \
#   -display gtk

