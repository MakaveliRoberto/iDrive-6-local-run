#!/bin/bash

# Analyze QNX IFS boot images using QNX tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
BOOT1="$DUMP_DIR/sda2/boot1.ifs"
BOOT2="$DUMP_DIR/sda2/boot2.ifs"

echo "=========================================="
echo "🔍 QNX IFS Image Analysis"
echo "=========================================="
echo ""

# Check if QNX tools are available
if ! command -v qnx-ifsload >/dev/null 2>&1; then
    echo "❌ QNX tools not found!"
    echo ""
    echo "Please run: ./setup-qnx-tools.sh"
    echo "Or source QNX environment:"
    echo "  source /opt/qnx710/qnxsdp-env.sh"
    echo ""
    exit 1
fi

echo "Analyzing boot images..."
echo ""

if [ -f "$BOOT1" ]; then
    echo "📦 boot1.ifs:"
    echo "   Size: $(ls -lh "$BOOT1" | awk '{print $5}')"
    echo ""
    echo "   Contents:"
    qnx-ifsload -v "$BOOT1" 2>&1 | head -50
    echo ""
else
    echo "❌ boot1.ifs not found at: $BOOT1"
fi

if [ -f "$BOOT2" ]; then
    echo "📦 boot2.ifs:"
    echo "   Size: $(ls -lh "$BOOT2" | awk '{print $5}')"
    echo ""
    echo "   Contents:"
    qnx-ifsload -v "$BOOT2" 2>&1 | head -50
    echo ""
else
    echo "⚠️  boot2.ifs not found (this is OK)"
fi

echo ""
echo "=========================================="
echo "Analysis complete!"
echo "=========================================="

