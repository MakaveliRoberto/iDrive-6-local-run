#!/bin/bash

# Attempt to use QNX loader approach
# The IFS might need to be loaded by a QNX bootloader, not directly as kernel

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🔧 QNX iDrive 6 - BOOTLOADER APPROACH"
echo "=========================================="
echo ""
echo "Trying to boot with QNX-specific configurations..."
echo ""

# Try different boot approaches that QNX might expect

# Method 1: Try with device tree (if available)
if [ -f "$DUMP_DIR/boot/arm-cortexA15_bios_packet.bin" ] || [ -f "$DUMP_DIR/sda2/arm-cortexA15_bios_packet.bin" ]; then
    DTB_FILE=$(find "$DUMP_DIR" -name "*bios_packet.bin" | head -1)
    echo "Found BIOS/boot packet: $DTB_FILE"
    echo "Trying with device tree approach..."
    echo ""
    
    qemu-system-arm \
        -M virt \
        -cpu cortex-a15 \
        -m 2048 \
        -smp 2 \
        -kernel "$BOOT_IMAGE" \
        -dtb "$DTB_FILE" 2>/dev/null \
        -drive file="$DISK_IMAGE",if=virtio,format=raw \
        -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
        -device virtio-net-device,netdev=net0 \
        -serial stdio \
        -display none \
        -no-reboot
else
    echo "No device tree found, trying standard boot..."
    echo ""
    
    # Try as initrd instead of kernel
    echo "Method 1: Loading as initrd..."
    qemu-system-arm \
        -M virt \
        -cpu cortex-a15 \
        -m 2048 \
        -smp 2 \
        -initrd "$BOOT_IMAGE" \
        -drive file="$DISK_IMAGE",if=virtio,format=raw \
        -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
        -device virtio-net-device,netdev=net0 \
        -serial stdio \
        -display none \
        -no-reboot \
        -d unimp,guest_errors 2>&1 | head -100
    
    echo ""
    echo "If that didn't work, trying as raw disk boot..."
    sleep 2
    
    # Method 2: Try booting from disk with BIOS
    qemu-system-arm \
        -M virt \
        -cpu cortex-a15 \
        -m 2048 \
        -smp 2 \
        -drive file="$BOOT_IMAGE",if=virtio,format=raw,index=0,media=disk \
        -drive file="$DISK_IMAGE",if=virtio,format=raw,index=1 \
        -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8091-:80 \
        -device virtio-net-device,netdev=net0 \
        -serial stdio \
        -display none \
        -boot order=dc \
        -no-reboot \
        -d unimp,guest_errors 2>&1
fi

