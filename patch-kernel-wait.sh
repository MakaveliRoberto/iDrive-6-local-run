#!/bin/bash

# Attempt to patch kernel to wait/poll instead of failing
# This uses binary patching to modify hardware check behavior

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
BACKUP_IMAGE="$DUMP_DIR/sda2/boot1.ifs.backup"
PATCHED_IMAGE="$DUMP_DIR/sda2/boot1.ifs.patched"

echo "=========================================="
echo "🔧 Patch Kernel to Wait for Hardware"
echo "=========================================="
echo ""

if [ ! -f "$BOOT_IMAGE" ]; then
    echo "❌ Boot image not found"
    exit 1
fi

# Backup
if [ ! -f "$BACKUP_IMAGE" ]; then
    cp "$BOOT_IMAGE" "$BACKUP_IMAGE"
    echo "✅ Backup created"
fi

echo "Analyzing kernel for hardware check patterns..."
echo ""

# Look for patterns that might be hardware checks
echo "Searching for error/exit patterns..."
strings "$BOOT_IMAGE" | grep -iE "error|fail|exit|abort|panic" | head -20

echo ""
echo "Searching for wait/poll patterns..."
strings "$BOOT_IMAGE" | grep -iE "wait|poll|sleep|delay|retry" | head -20

echo ""
echo "⚠️  Binary Patching Strategy:"
echo ""
echo "To make kernel wait instead of failing, we need to:"
echo "  1. Find hardware check code (CMP instructions)"
echo "  2. Find error/exit branches (BNE/BEQ to error handlers)"
echo "  3. Replace with wait loops or success paths"
echo ""
echo "This requires:"
echo "  • Disassembling the binary"
echo "  • Finding exact instruction addresses"
echo "  • Patching ARM instructions"
echo ""
echo "Let's try a different approach - use QEMU to provide the hardware!"
echo ""

