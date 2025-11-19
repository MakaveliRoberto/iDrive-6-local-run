#!/bin/bash

# Patch hardware checks in the binary kernel
# This attempts to find and modify ARM instructions that check hardware

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT_IMAGE="$SCRIPT_DIR/nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE="$SCRIPT_DIR/nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE="$SCRIPT_DIR/nbtevo-system-dump/sda2/boot1.ifs.patched"

echo "=========================================="
echo "🔧 Patching Hardware Checks in Binary"
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

# Copy for patching
cp "$BOOT_IMAGE" "$PATCHED_IMAGE"
echo "✅ Created patching target: $PATCHED_IMAGE"
echo ""

echo "Strategy: Find and patch ARM instructions"
echo ""

# Method 1: Find error return patterns and change to success
echo "Method 1: Looking for error return patterns..."
# ARM functions often return 0 for success, non-zero for error
# We can try to find error returns and change them to success (0)

# Method 2: Find conditional branches that jump to error handlers
echo "Method 2: Looking for conditional branch patterns..."
# BNE (Branch if Not Equal) to error handlers
# We can try to change BNE to BEQ or NOP

# Method 3: Find hardware check function calls and NOP them out
echo "Method 3: Looking for function call patterns..."
# BL (Branch with Link) instructions call functions
# We can try to NOP out calls to hardware check functions

echo ""
echo "⚠️  Binary Patching is Complex"
echo ""
echo "We need to:"
echo "  1. Disassemble the binary (objdump or similar)"
echo "  2. Find exact instruction addresses"
echo "  3. Identify hardware check code"
echo "  4. Replace with NOPs or success returns"
echo "  5. Recalculate checksums if needed"
echo ""

# Try to use objdump if available
if command -v objdump >/dev/null 2>&1 || command -v arm-none-eabi-objdump >/dev/null 2>&1; then
    OBJDUMP_CMD=$(command -v arm-none-eabi-objdump 2>/dev/null || command -v objdump 2>/dev/null)
    echo "✅ Found objdump: $OBJDUMP_CMD"
    echo ""
    echo "Disassembling boot image (first 1000 bytes)..."
    $OBJDUMP_CMD -D -b binary -m arm "$BOOT_IMAGE" 2>/dev/null | head -100 || echo "objdump failed or wrong format"
else
    echo "❌ objdump not found"
    echo "   Install: brew install binutils (for arm-none-eabi-objdump)"
fi

echo ""
echo "Let's try a different approach - search and replace specific patterns..."

