#!/bin/bash

# Setup script for QNX Momentics tools
# This configures QNX environment and creates helper scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"

echo "=========================================="
echo "🔧 QNX Momentics Setup"
echo "=========================================="
echo ""

# Find QNX installation
QNX_PATHS=(
    "/opt/qnx710"
    "/opt/qnx720"
    "/opt/qnx700"
    "$HOME/qnx710"
    "$HOME/qnx720"
    "$HOME/qnx700"
    "/usr/local/qnx710"
    "/usr/local/qnx720"
)

QNX_INSTALL=""

for path in "${QNX_PATHS[@]}"; do
    if [ -d "$path" ] && [ -f "$path/qnxsdp-env.sh" ]; then
        QNX_INSTALL="$path"
        echo "✅ Found QNX installation at: $QNX_INSTALL"
        break
    fi
done

if [ -z "$QNX_INSTALL" ]; then
    echo "❌ QNX Momentics not found!"
    echo ""
    echo "Please install QNX Momentics IDE first:"
    echo "  1. Download from: https://www.qnx.com/developers/"
    echo "  2. Install following QNX_SETUP.md guide"
    echo "  3. Run this script again"
    echo ""
    exit 1
fi

echo ""
echo "Setting up QNX environment..."
echo ""

# Source QNX environment
if [ -f "$QNX_INSTALL/qnxsdp-env.sh" ]; then
    source "$QNX_INSTALL/qnxsdp-env.sh"
    echo "✅ QNX environment loaded"
else
    echo "❌ Could not find qnxsdp-env.sh"
    exit 1
fi

# Verify QNX tools
echo ""
echo "Checking QNX tools..."
echo ""

TOOLS_OK=true

for tool in qcc mkqnx6fs qnx-ifsload; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✅ $tool: $(which $tool)"
    else
        echo "  ❌ $tool: not found"
        TOOLS_OK=false
    fi
done

if [ "$TOOLS_OK" = false ]; then
    echo ""
    echo "⚠️  Some QNX tools are missing"
    echo "   Make sure QNX Momentics is fully installed"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ QNX Tools Setup Complete!"
echo "=========================================="
echo ""
echo "QNX Installation: $QNX_INSTALL"
echo "QNX Version: $(qnxversion 2>/dev/null || echo 'unknown')"
echo ""
echo "Available commands:"
echo "  • analyze-ifs.sh - Analyze boot IFS images"
echo "  • create-qnx-fs.sh - Create QNX6 filesystem"
echo "  • run-qnx-simulator.sh - Run QNX simulator"
echo ""
echo "To use QNX tools in this shell, run:"
echo "  source $QNX_INSTALL/qnxsdp-env.sh"
echo ""
echo "Or add to your ~/.zshrc or ~/.bashrc:"
echo "  source $QNX_INSTALL/qnxsdp-env.sh"
echo ""

