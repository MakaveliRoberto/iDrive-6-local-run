#!/bin/bash

# Create a proper QNX6 filesystem disk image
# This attempts to create a bootable QNX disk from the dump

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
EMU_DIR="$SCRIPT_DIR/emulation"
DISK_IMAGE="$EMU_DIR/idrive-qnx6.img"

echo "=========================================="
echo "Creating QNX6 Filesystem Disk Image"
echo "=========================================="
echo ""

mkdir -p "$EMU_DIR"

# Check if we have mkqnx6fs (from QNX)
if command -v mkqnx6fs &> /dev/null; then
    echo "✓ Found QNX mkqnx6fs tool"
    
    echo "Creating QNX6 filesystem image (2GB)..."
    # Create a 2GB QNX6 filesystem
    mkqnx6fs -q "$DISK_IMAGE" 2097152 2>/dev/null || {
        echo "Creating raw image..."
        dd if=/dev/zero of="$DISK_IMAGE" bs=1M count=2048 2>/dev/null
        mkqnx6fs -q "$DISK_IMAGE"
    }
    
    echo "Mounting QNX6 filesystem..."
    # Try to mount and copy files
    # This requires QNX tools and may not work on macOS/Linux
    echo "⚠️  Note: Copying files requires QNX mount tools"
    
elif command -v qemu-img &> /dev/null; then
    echo "⚠️  QNX tools not found. Creating raw disk image..."
    echo "   (You'll need QNX tools to create proper QNX6 filesystem)"
    
    echo "Creating 4GB raw disk image..."
    qemu-img create -f raw "$DISK_IMAGE" 4G 2>/dev/null || \
    truncate -s 4G "$DISK_IMAGE"
    
    echo ""
    echo "To create proper QNX6 filesystem:"
    echo "1. Install QNX Momentics"
    echo "2. Use mkqnx6fs to format this image"
    echo "3. Mount and copy files from the dump"
    
else
    echo "❌ No disk creation tools found"
    exit 1
fi

echo ""
echo "✓ Disk image created: $DISK_IMAGE"
echo "   Size: $(du -h "$DISK_IMAGE" | cut -f1)"

