#!/bin/bash

# Script to run iDrive 6 web interface locally with ALL content
# This serves files from multiple locations to give access to all web-accessible content

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"

# Check if the dump directory exists
if [ ! -d "$DUMP_DIR" ]; then
    echo "Error: nbtevo-system-dump directory not found at $DUMP_DIR"
    echo "Please ensure the nbtevo-system-dump repository is cloned."
    exit 1
fi

# Port to serve on (default: 8080)
PORT="${1:-8080}"

# Create a temporary directory to serve from with symlinks to all web content
TEMP_SERVE_DIR=$(mktemp -d)
trap "rm -rf $TEMP_SERVE_DIR" EXIT

echo "=========================================="
echo "BMW iDrive 6 Full System Web Explorer"
echo "=========================================="
echo ""
echo "Setting up symlinks to all web-accessible content..."

# Main htdocs from sda32
if [ -d "$DUMP_DIR/sda32/opt/car/data/htdocs" ]; then
    ln -sf "$DUMP_DIR/sda32/opt/car/data/htdocs"/* "$TEMP_SERVE_DIR/" 2>/dev/null
    echo "✓ Linked main htdocs (sda32)"
fi

# Browser content from sda0
if [ -d "$DUMP_DIR/sda0/opt/conn/data/browser" ]; then
    mkdir -p "$TEMP_SERVE_DIR/browser"
    ln -sf "$DUMP_DIR/sda0/opt/conn/data/browser"/* "$TEMP_SERVE_DIR/browser/" 2>/dev/null
    echo "✓ Linked browser content (sda0)"
fi

# HMI images/assets (for browsing)
if [ -d "$DUMP_DIR/sda0/opt/hmi/ID5/data/ro/bmwm/id6l/assetDB" ]; then
    mkdir -p "$TEMP_SERVE_DIR/hmi-assets"
    # Create a symlink tree for HMI assets
    ln -sf "$DUMP_DIR/sda0/opt/hmi/ID5/data/ro/bmwm/id6l/assetDB" "$TEMP_SERVE_DIR/hmi-assets/" 2>/dev/null
    echo "✓ Linked HMI assets"
fi

# Conn HTML templates
if [ -d "$DUMP_DIR/sda0/opt/conn/html" ]; then
    ln -sf "$DUMP_DIR/sda0/opt/conn/html" "$TEMP_SERVE_DIR/conn-html" 2>/dev/null
    echo "✓ Linked connector HTML templates"
fi

echo ""
echo "Serving from: $TEMP_SERVE_DIR"
echo "Port: $PORT"
echo ""
echo "Available content:"
echo "  • Main interface: http://localhost:$PORT/"
echo "  • Journaline: http://localhost:$PORT/journaline.html"
echo "  • Browser pages: http://localhost:$PORT/browser/"
echo "  • HMI assets: http://localhost:$PORT/hmi-assets/"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=========================================="
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    cd "$TEMP_SERVE_DIR"
    python3 -m http.server "$PORT"
elif command -v python &> /dev/null; then
    cd "$TEMP_SERVE_DIR"
    python -m SimpleHTTPServer "$PORT"
elif command -v node &> /dev/null; then
    cd "$TEMP_SERVE_DIR"
    npx -y http-server -p "$PORT"
else
    echo "Error: Neither Python nor Node.js found. Please install one of them."
    exit 1
fi

