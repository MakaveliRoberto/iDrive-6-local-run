#!/bin/bash

# Run iDrive with the patched kernel (hardware checks bypassed)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT_IMAGE="$SCRIPT_DIR/nbtevo-system-dump/sda2/boot1.ifs.patched"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

if [ ! -f "$BOOT_IMAGE" ]; then
    echo "❌ Patched kernel not found!"
    echo ""
    echo "Run: python3 patch-kernel-final.py"
    exit 1
fi

echo "=========================================="
echo "🚀 Running iDrive with Patched Kernel"
echo "=========================================="
echo ""
echo "✅ Using patched kernel (hardware checks bypassed)"
echo ""
echo "The kernel has been patched to bypass:"
echo "  • CPUID validation checks"
echo "  • Hardware comparison branches"
echo ""
echo "This should allow the system to boot further!"
echo ""

# Kill any existing QEMU
killall qemu-system-arm 2>/dev/null
sleep 2

qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -fsdev local,id=fsdev0,path="$SCRIPT_DIR/nbtevo-system-dump/sda0",security_model=none \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors,unimp 2>&1

echo ""
echo "=========================================="
echo "Boot complete or stopped"
echo "=========================================="

