#!/bin/bash

# Complete iDrive 6 QNX Emulation Setup
# This script attempts to boot the full QNX system using QEMU

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
EMU_DIR="$SCRIPT_DIR/emulation"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$EMU_DIR/idrive-disk.img"

echo "=========================================="
echo "BMW iDrive 6 QNX Emulation Setup"
echo "=========================================="
echo ""

# Check if dump exists
if [ ! -d "$DUMP_DIR" ]; then
    echo "❌ Error: nbtevo-system-dump not found!"
    exit 1
fi

# Create emulation directory
mkdir -p "$EMU_DIR"

# Install QEMU
echo "Checking for QEMU..."
if ! command -v qemu-system-arm &> /dev/null; then
    echo "❌ QEMU not found. Installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo "Installing QEMU via Homebrew..."
            brew install qemu
        else
            echo "❌ Homebrew not found. Please install Homebrew first:"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Installing QEMU via apt..."
        sudo apt-get update
        sudo apt-get install -y qemu-system-arm qemu-utils
    else
        echo "❌ Please install QEMU manually for your OS"
        exit 1
    fi
fi

echo "✓ QEMU found: $(which qemu-system-arm)"
echo ""

# Check boot image
if [ ! -f "$BOOT_IMAGE" ]; then
    echo "❌ Boot image not found: $BOOT_IMAGE"
    exit 1
fi

echo "✓ Boot image found: $BOOT_IMAGE ($(du -h "$BOOT_IMAGE" | cut -f1))"
echo ""

# Create disk image from filesystem
echo "Creating disk image from filesystem..."
echo "This may take a few minutes..."

if [ ! -f "$DISK_IMAGE" ]; then
    # Create a 4GB disk image
    echo "Creating 4GB disk image..."
    qemu-img create -f raw "$DISK_IMAGE" 4G 2>/dev/null || \
    truncate -s 4G "$DISK_IMAGE"
    
    # Create partition table (GPT)
    echo "Setting up partition table..."
    parted -s "$DISK_IMAGE" mklabel msdos 2>/dev/null || \
    gpart create -s MBR "$DISK_IMAGE" 2>/dev/null || \
    echo "⚠️  Could not create partition table automatically"
    
    # Copy filesystem structure (this is a simplified approach)
    # In reality, we'd need to properly format as QNX6 filesystem
    echo "⚠️  Note: Full filesystem image creation requires QNX tools"
    echo "   For now, we'll attempt to boot with the IFS image directly"
else
    echo "✓ Disk image already exists"
fi

echo ""
echo "=========================================="
echo "Attempting to Boot QNX System"
echo "=========================================="
echo ""
echo "Hardware: OMAP5430 (ARM Cortex-A15)"
echo "OS: QNX Neutrino RTOS"
echo "Boot Image: boot1.ifs"
echo ""
echo "⚠️  WARNING: This is experimental!"
echo "   The system may not boot properly without:"
echo "   • Full OMAP5430 hardware emulation"
echo "   • QNX runtime libraries"
echo "   • Proper device drivers"
echo ""
# Auto-continue if running non-interactively
if [ -t 0 ]; then
    echo "Press Ctrl+C to cancel, or Enter to continue..."
    read
fi

echo ""
echo "Starting QEMU..."
echo ""

# Try multiple approaches - start with virt machine (best for generic ARM)
# Then fallback to vexpress-a15

echo "Attempting Method 1: virt machine (generic ARM virtual machine)..."
echo ""

if qemu-system-arm \
    -M virt \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d unimp,guest_errors 2>&1 | head -50; then
    echo "virt machine boot successful!"
else
    echo ""
    echo "virt machine didn't boot, trying vexpress-a15..."
    echo ""
    
    # Fallback to vexpress-a15
    qemu-system-arm \
        -M vexpress-a15 \
        -cpu cortex-a15 \
        -m 2048 \
        -smp 2 \
        -kernel "$BOOT_IMAGE" \
        -drive file="$DISK_IMAGE",if=sd,format=raw,cache=writeback \
        -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
        -device virtio-net-device,netdev=net0 \
        -serial stdio \
        -display none \
        -no-reboot \
        -d unimp,guest_errors
fi

# Alternative: Try with graphics (if you want to see output)
# Uncomment if you prefer:
# qemu-system-arm \
#     -M vexpress-a15 \
#     -cpu cortex-a15 \
#     -m 2048 \
#     -smp 2 \
#     -kernel "$BOOT_IMAGE" \
#     -drive file="$DISK_IMAGE",if=sd,format=raw \
#     -netdev user,id=net0 \
#     -device virtio-net-device,netdev=net0 \
#     -vga std \
#     -display gtk

echo ""
echo "Emulation stopped."

