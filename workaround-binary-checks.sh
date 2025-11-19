#!/bin/bash

# Work around binary hardware checks using multiple techniques
# 1. Binary patching
# 2. QEMU CPU ID manipulation  
# 3. Device tree overlays
# 4. Runtime patching via QEMU monitor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
DISK_IMAGE="$SCRIPT_DIR/emulation/idrive-disk.img"

echo "=========================================="
echo "🎭 Binary Check Workarounds"
echo "=========================================="
echo ""
echo "Trying multiple techniques to bypass binary checks..."
echo ""

# Technique 1: Try different CPU IDs that might match OMAP5430
echo "Technique 1: CPU ID manipulation..."
echo "OMAP5430 CPU ID: 0x412fc0f1 (Cortex-A15 r2p1)"
echo ""

# OMAP5430 uses Cortex-A15 with specific MIDR
# MIDR format: Implementer(8) | Variant(4) | Architecture(4) | PartNum(12) | Revision(4)
# OMAP5430: ARM (0x41) | A15 (0xc0f) | r2p1 (0x2)
OMAP_CPUID="0x412fc0f1"

qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=$OMAP_CPUID \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8100-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors 2>&1 | head -100 &
PID1=$!
sleep 25
kill $PID1 2>/dev/null || true
wait $PID1 2>/dev/null || true

echo ""
echo "Technique 2: Try with device properties..."
# QEMU virt machine might allow setting device properties
echo "Trying with additional CPU features..."

qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=$OMAP_CPUID,pmu=on \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=virtio,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8100-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors 2>&1 | head -100 &
PID2=$!
sleep 25
kill $PID2 2>/dev/null || true
wait $PID2 2>/dev/null || true

echo ""
echo "Technique 3: Try vexpress-a15 (closer to real hardware)..."
qemu-system-arm \
    -M vexpress-a15 \
    -cpu cortex-a15 \
    -m 2048 \
    -smp 2 \
    -kernel "$BOOT_IMAGE" \
    -drive file="$DISK_IMAGE",if=sd,format=raw,cache=writeback \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8100-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot \
    -d guest_errors 2>&1 | head -100

echo ""
echo "=========================================="
echo "If any of these showed boot messages, that's progress!"
echo "=========================================="

