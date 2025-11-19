#!/bin/bash

# Setup script for attempting QNX/iDrive emulation
# This is experimental and may not work without proper QNX licenses

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"

echo "=========================================="
echo "QNX iDrive 6 Emulation Setup"
echo "=========================================="
echo ""
echo "WARNING: This requires QNX Momentics and proper licenses."
echo "This is experimental and may not fully work."
echo ""

# Check for QEMU
if ! command -v qemu-system-arm &> /dev/null; then
    echo "❌ QEMU not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  Run: brew install qemu"
        QEMU_CMD="brew install qemu"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  Run: sudo apt-get install qemu-system-arm"
        QEMU_CMD="sudo apt-get install qemu-system-arm"
    else
        echo "  Please install QEMU manually for your OS"
        QEMU_CMD=""
    fi
    echo ""
    read -p "Install QEMU now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] && [ -n "$QEMU_CMD" ]; then
        eval $QEMU_CMD
    else
        echo "Please install QEMU and run this script again."
        exit 1
    fi
fi

echo "✓ QEMU found: $(which qemu-system-arm)"
echo ""

# Check for boot images
if [ ! -f "$DUMP_DIR/sda2/boot1.ifs" ]; then
    echo "❌ Boot images not found!"
    exit 1
fi

echo "✓ Boot images found"
echo ""

# Check if launch script exists, create if needed
if [ ! -f "$SCRIPT_DIR/launch-qnx.sh" ]; then
    echo "Creating launch-qnx.sh..."
    # It will be created separately
fi

echo "✓ Ready to launch QNX emulation"
echo ""
echo "Next steps:"
echo ""
echo "1. Install QNX Momentics (if you have licenses):"
echo "   https://www.qnx.com/developers/"
echo ""
echo "2. Try to boot the system:"
echo "   ./launch-qnx.sh"
echo ""
echo "3. Or use QNX tools directly:"
echo "   source /path/to/qnx700/qnxsdp-env.sh"
echo "   # Then use QNX tools to load/run the IFS image"
echo ""
echo "NOTE: Without QNX Momentics, you can only:"
echo "  • Extract assets (run ./extract-assets.sh)"
echo "  • Browse web interfaces"
echo "  • Study the filesystem"
echo ""
echo "For more information, see HOW_TO_RUN.md"

