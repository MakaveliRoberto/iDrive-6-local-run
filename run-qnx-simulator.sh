#!/bin/bash

# Run QNX Simulator with iDrive system
# This uses QNX's built-in simulator (better than QEMU)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"

echo "=========================================="
echo "🚀 QNX Simulator - iDrive 6"
echo "=========================================="
echo ""

# Check if QNX tools are available
if ! command -v qnx-simulator >/dev/null 2>&1; then
    echo "❌ QNX Simulator not found!"
    echo ""
    echo "Please ensure QNX Momentics is installed and:"
    echo "  1. Run: ./setup-qnx-tools.sh"
    echo "  2. Or source QNX environment:"
    echo "     source /opt/qnx710/qnxsdp-env.sh"
    echo ""
    echo "Note: QNX Simulator may be in QNX Momentics IDE"
    echo "      (GUI application, not command line)"
    echo ""
    exit 1
fi

if [ ! -f "$BOOT_IMAGE" ]; then
    echo "❌ Boot image not found: $BOOT_IMAGE"
    exit 1
fi

echo "Starting QNX Simulator..."
echo ""
echo "Boot image: $BOOT_IMAGE"
echo ""
echo "Note: QNX Simulator may open in GUI mode"
echo "      or may require QNX Momentics IDE"
echo ""

# Try to run QNX simulator
# Note: Command may vary depending on QNX version
if command -v qnx-simulator >/dev/null 2>&1; then
    qnx-simulator -k "$BOOT_IMAGE"
elif [ -f "$QNX_HOST/usr/bin/qnx-simulator" ]; then
    "$QNX_HOST/usr/bin/qnx-simulator" -k "$BOOT_IMAGE"
else
    echo "⚠️  QNX Simulator command not found"
    echo ""
    echo "Alternative: Use QNX Momentics IDE"
    echo "  1. Open QNX Momentics IDE"
    echo "  2. Go to: File → New → QNX Project"
    echo "  3. Select: QNX Simulator"
    echo "  4. Load boot image: $BOOT_IMAGE"
    echo ""
    echo "Or continue using QEMU with:"
    echo "  ./emulate-idrive-clean.sh"
    echo ""
fi

