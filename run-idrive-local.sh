#!/bin/bash

# Script to run iDrive 6 web interface locally
# This serves the static HTML/JS/CSS files from the system dump

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
HTDOCS_DIR="$DUMP_DIR/sda32/opt/car/data/htdocs"

# Check if the htdocs directory exists
if [ ! -d "$HTDOCS_DIR" ]; then
    echo "Error: htdocs directory not found at $HTDOCS_DIR"
    echo "Please ensure the nbtevo-system-dump repository is cloned."
    exit 1
fi

# Port to serve on (default: 8080)
PORT="${1:-8080}"

echo "=========================================="
echo "BMW iDrive 6 Local Web Interface Server"
echo "=========================================="
echo ""
echo "Serving files from: $HTDOCS_DIR"
echo "Port: $PORT"
echo ""
echo "Access the interface at:"
echo "  http://localhost:$PORT/"
echo "  http://localhost:$PORT/journaline.html"
echo "  http://localhost:$PORT/journaline7.html"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=========================================="
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    cd "$HTDOCS_DIR"
    python3 -m http.server "$PORT"
elif command -v python &> /dev/null; then
    cd "$HTDOCS_DIR"
    python -m SimpleHTTPServer "$PORT"
elif command -v node &> /dev/null; then
    # Fallback to Node.js if Python is not available
    cd "$HTDOCS_DIR"
    npx -y http-server -p "$PORT"
else
    echo "Error: Neither Python nor Node.js found. Please install one of them."
    exit 1
fi

