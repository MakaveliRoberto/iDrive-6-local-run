#!/bin/bash

# Analyze the boot binary to find hardware check locations
# Using QNX tools to extract and examine the IFS image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT_IMAGE="$DUMP_DIR/sda2/boot1.ifs"
EXTRACT_DIR="$SCRIPT_DIR/emulation/boot-extracted"

echo "=========================================="
echo "🔍 QNX Boot Binary Analysis"
echo "=========================================="
echo ""

# Check for QNX tools
if ! command -v qnx-ifsload >/dev/null 2>&1; then
    echo "❌ QNX tools not found!"
    echo ""
    echo "Please ensure QNX Momentics is installed and:"
    echo "  source /opt/qnx710/qnxsdp-env.sh"
    echo "  (or wherever QNX is installed)"
    echo ""
    exit 1
fi

echo "✅ QNX tools found!"
echo ""

# Create extraction directory
mkdir -p "$EXTRACT_DIR"

echo "Extracting IFS image contents..."
echo ""

# Extract IFS image
if qnx-ifsload -v "$BOOT_IMAGE" 2>&1 | tee "$EXTRACT_DIR/ifs-info.txt"; then
    echo ""
    echo "✅ IFS image analyzed"
else
    echo ""
    echo "⚠️  qnx-ifsload may need different syntax"
    echo "Trying alternative extraction..."
fi

echo ""
echo "Searching for hardware check patterns in binary..."
echo ""

# Search for hardware check strings
echo "=== OMAP5430 References ===" > "$EXTRACT_DIR/hardware-checks.txt"
strings "$BOOT_IMAGE" | grep -i "omap\|5430\|get_omap" >> "$EXTRACT_DIR/hardware-checks.txt"

echo "" >> "$EXTRACT_DIR/hardware-checks.txt"
echo "=== CPUID Checks ===" >> "$EXTRACT_DIR/hardware-checks.txt"
strings "$BOOT_IMAGE" | grep -i "cpuid\|unsupported.*cpu" >> "$EXTRACT_DIR/hardware-checks.txt"

echo "" >> "$EXTRACT_DIR/hardware-checks.txt"
echo "=== Hardware Index/Revision ===" >> "$EXTRACT_DIR/hardware-checks.txt"
strings "$BOOT_IMAGE" | grep -i "hardware.*index\|hw.*idx\|revision" >> "$EXTRACT_DIR/hardware-checks.txt"

echo "" >> "$EXTRACT_DIR/hardware-checks.txt"
echo "=== Error/Check Messages ===" >> "$EXTRACT_DIR/hardware-checks.txt"
strings "$BOOT_IMAGE" | grep -iE "error|check|verify|fail|unsupported" >> "$EXTRACT_DIR/hardware-checks.txt"

cat "$EXTRACT_DIR/hardware-checks.txt"

echo ""
echo "=========================================="
echo "Analysis complete!"
echo "Results saved to: $EXTRACT_DIR/"
echo "=========================================="

