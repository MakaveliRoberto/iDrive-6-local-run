#!/bin/bash
# Quick test script to try all methods

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"

echo "Testing different QEMU configurations..."
echo ""

# Test 1: VersatilePB
echo "Test 1: VersatilePB (5 sec)..."
timeout 5 qemu-system-arm -M versatilepb -cpu cortex-a15 -m 2048 -kernel "$BOOT_IMAGE" -serial stdio -display none -nographic 2>&1 | head -20 || echo "Test 1 done"
echo ""

# Test 2: virt machine  
echo "Test 2: virt machine (5 sec)..."
timeout 5 qemu-system-arm -M virt -cpu cortex-a15 -m 2048 -kernel "$BOOT_IMAGE" -serial stdio -display none -nographic 2>&1 | head -20 || echo "Test 2 done"
echo ""

echo "Quick tests completed"
