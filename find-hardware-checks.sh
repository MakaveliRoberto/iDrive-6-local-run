#!/bin/bash

# Find hardware check patterns in the binary kernel

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT_IMAGE="$SCRIPT_DIR/nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE="$SCRIPT_DIR/nbtevo-system-dump/sda2/boot1.ifs.backup"

echo "=========================================="
echo "🔍 Finding Hardware Checks in Binary"
echo "=========================================="
echo ""

if [ ! -f "$BOOT_IMAGE" ]; then
    echo "❌ Boot image not found"
    exit 1
fi

# Create backup
if [ ! -f "$BACKUP_IMAGE" ]; then
    cp "$BOOT_IMAGE" "$BACKUP_IMAGE"
    echo "✅ Backup created: $BACKUP_IMAGE"
fi

echo "Analyzing boot image..."
FILE_SIZE=$(stat -f%z "$BOOT_IMAGE" 2>/dev/null || stat -c%s "$BOOT_IMAGE" 2>/dev/null)
echo "Size: $FILE_SIZE bytes"
echo ""

echo "=== Hardware Check Strings ==="
strings "$BOOT_IMAGE" | grep -iE "omap|5430|hardware|check|verify|unsupported|cpuid" > /tmp/hw_checks.txt
cat /tmp/hw_checks.txt | head -50

echo ""
echo "=== Function Names ==="
strings "$BOOT_IMAGE" | grep -E "get_omap|check_hw|verify_platform|init_hardware" > /tmp/hw_functions.txt
cat /tmp/hw_functions.txt

echo ""
echo "=== Error Messages ==="
strings "$BOOT_IMAGE" | grep -iE "error|fail|unsupported|not.*found" | head -30

echo ""
echo "=========================================="
echo "Now searching for binary patterns..."
echo "=========================================="
echo ""

# Look for ARM instruction patterns that might be checks
# Common patterns:
# - CMP (compare) followed by conditional branch
# - Error return values (non-zero)
# - Hardware register reads

echo "Searching for ARM compare instructions (CMP patterns)..."
# CMP instruction in ARM: often 0xE1A0... or 0xE350...
hexdump -C "$BOOT_IMAGE" | grep -E "e1 a0|e3 50|e3 40" | head -10

echo ""
echo "Looking for 'get_omap5430_info' function location..."
# Find the string location
STR_OFFSET=$(strings -t x "$BOOT_IMAGE" | grep -i "get_omap5430_info" | head -1 | awk '{print $1}')
if [ -n "$STR_OFFSET" ]; then
    echo "Found 'get_omap5430_info' at offset: 0x$STR_OFFSET"
    echo "Examining surrounding bytes..."
    # Convert hex offset to decimal for dd
    DEC_OFFSET=$((0x$STR_OFFSET))
    dd if="$BOOT_IMAGE" bs=1 skip=$((DEC_OFFSET - 100)) count=200 2>/dev/null | hexdump -C | head -10
fi

echo ""
echo "=========================================="
echo "Analysis complete!"
echo "=========================================="

