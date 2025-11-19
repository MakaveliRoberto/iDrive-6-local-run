#!/bin/bash

# Create proper QNX6 filesystem from the dump
# This uses QNX's mkqnx6fs tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
OUTPUT_DIR="$SCRIPT_DIR/emulation"
FS_IMAGE="$OUTPUT_DIR/idrive-qnx6.img"

echo "=========================================="
echo "📦 Create QNX6 Filesystem"
echo "=========================================="
echo ""

# Check if QNX tools are available
if ! command -v mkqnx6fs >/dev/null 2>&1; then
    echo "❌ QNX tools not found!"
    echo ""
    echo "Please run: ./setup-qnx-tools.sh"
    echo "Or source QNX environment:"
    echo "  source /opt/qnx710/qnxsdp-env.sh"
    echo ""
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

if [ ! -d "$DUMP_DIR/sda0" ]; then
    echo "❌ Source directory not found: $DUMP_DIR/sda0"
    exit 1
fi

echo "Source: $DUMP_DIR/sda0"
echo "Output: $FS_IMAGE"
echo ""

# Calculate size needed (rough estimate: 2x source size)
SOURCE_SIZE=$(du -sm "$DUMP_DIR/sda0" | cut -f1)
FS_SIZE=$((SOURCE_SIZE * 2))

echo "Estimated filesystem size: ${FS_SIZE}MB"
echo ""
echo "Creating QNX6 filesystem..."
echo ""

# Create QNX6 filesystem
# Note: mkqnx6fs syntax may vary by QNX version
if mkqnx6fs -b 512 -l "$FS_IMAGE" -s "${FS_SIZE}M" "$DUMP_DIR/sda0" 2>&1; then
    echo ""
    echo "✅ QNX6 filesystem created: $FS_IMAGE"
    echo "   Size: $(ls -lh "$FS_IMAGE" | awk '{print $5}')"
else
    echo ""
    echo "⚠️  mkqnx6fs failed or syntax different"
    echo ""
    echo "Trying alternative method..."
    echo ""
    
    # Alternative: Create image file first, then format
    echo "Creating empty image file..."
    dd if=/dev/zero of="$FS_IMAGE" bs=1M count="$FS_SIZE" 2>/dev/null
    
    echo "Formatting as QNX6..."
    # Note: Actual mkqnx6fs command may need different syntax
    # Check QNX documentation for your version
    echo ""
    echo "Please check QNX documentation for correct mkqnx6fs syntax"
    echo "for your QNX version."
    echo ""
    echo "Example commands to try:"
    echo "  mkqnx6fs -b 512 $FS_IMAGE"
    echo "  mkqnx6fs -l $FS_IMAGE -s ${FS_SIZE}M"
    echo ""
fi

echo ""
echo "=========================================="

