#!/bin/bash

# Alternative QNX emulation approaches
# Trying different QEMU configurations to boot the system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "QNX iDrive 6 Emulation - Alternative Methods"
echo "=========================================="
echo ""

if [ ! -f "$BOOT_IMAGE" ]; then
    echo "❌ Boot image not found!"
    exit 1
fi

echo "Select boot method:"
echo "  1) VersatilePB (better ARM boot support)"
echo "  2) Highbank (alternative ARM platform)"
echo "  3) virt (generic ARM virtual machine)"
echo "  4) vexpress-a15 with initrd approach"
echo "  5) Try as raw image (no kernel flag)"
echo ""
read -p "Choice [1-5]: " CHOICE

echo ""
echo "Starting QEMU with method $CHOICE..."
echo ""

case $CHOICE in
    1)
        # VersatilePB - often better for ARM booting
        echo "Method 1: VersatilePB platform"
        qemu-system-arm \
            -M versatilepb \
            -cpu cortex-a15 \
            -m 2048 \
            -kernel "$BOOT_IMAGE" \
            -drive file="$DISK_IMAGE",if=sd,format=raw \
            -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
            -device virtio-net-device,netdev=net0 \
            -serial stdio \
            -display none \
            -no-reboot \
            -d unimp,guest_errors
        ;;
    2)
        # Highbank platform
        echo "Method 2: Highbank platform"
        qemu-system-arm \
            -M highbank \
            -cpu cortex-a15 \
            -m 2048 \
            -kernel "$BOOT_IMAGE" \
            -drive file="$DISK_IMAGE",if=sd,format=raw \
            -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
            -device virtio-net-device,netdev=net0 \
            -serial stdio \
            -display none \
            -no-reboot \
            -d unimp,guest_errors
        ;;
    3)
        # virt - generic ARM virtual machine
        echo "Method 3: virt machine (generic ARM)"
        qemu-system-arm \
            -M virt \
            -cpu cortex-a15 \
            -m 2048 \
            -smp 2 \
            -kernel "$BOOT_IMAGE" \
            -drive file="$DISK_IMAGE",if=sd,format=raw \
            -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
            -device virtio-net-device,netdev=net0 \
            -serial stdio \
            -display none \
            -no-reboot \
            -d unimp,guest_errors
        ;;
    4)
        # Try as initrd instead of kernel
        echo "Method 4: vexpress-a15 with initrd approach"
        qemu-system-arm \
            -M vexpress-a15 \
            -cpu cortex-a15 \
            -m 2048 \
            -smp 2 \
            -initrd "$BOOT_IMAGE" \
            -drive file="$DISK_IMAGE",if=sd,format=raw \
            -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
            -device virtio-net-device,netdev=net0 \
            -serial stdio \
            -display none \
            -no-reboot \
            -d unimp,guest_errors
        ;;
    5)
        # Try booting from disk directly (no kernel flag)
        echo "Method 5: Boot from disk (raw image)"
        qemu-system-arm \
            -M vexpress-a15 \
            -cpu cortex-a15 \
            -m 2048 \
            -smp 2 \
            -drive file="$BOOT_IMAGE",if=sd,format=raw,boot=on \
            -drive file="$DISK_IMAGE",if=sd,format=raw \
            -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
            -device virtio-net-device,netdev=net0 \
            -serial stdio \
            -display none \
            -no-reboot \
            -d unimp,guest_errors
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

