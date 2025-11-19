#!/bin/bash

# Comprehensive viewer server that serves both extracted assets and system dump
# This provides the best way to explore the iDrive 6 system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
EXTRACTED_DIR="$SCRIPT_DIR/extracted-assets"
TEMP_SERVE_DIR=$(mktemp -d)
trap "rm -rf $TEMP_SERVE_DIR" EXIT

PORT="${1:-8080}"

echo "=========================================="
echo "BMW iDrive 6 Comprehensive Viewer"
echo "=========================================="
echo ""

# Check if assets are extracted
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "⚠️  Extracted assets not found. Running extraction..."
    "$SCRIPT_DIR/extract-assets.sh"
fi

echo "Setting up comprehensive viewer..."

# Copy extracted assets viewer
if [ -d "$EXTRACTED_DIR" ]; then
    ln -sf "$EXTRACTED_DIR" "$TEMP_SERVE_DIR/extracted-assets" 2>/dev/null
    echo "✓ Linked extracted assets"
fi

# Main htdocs from sda32
if [ -d "$DUMP_DIR/sda32/opt/car/data/htdocs" ]; then
    ln -sf "$DUMP_DIR/sda32/opt/car/data/htdocs"/* "$TEMP_SERVE_DIR/" 2>/dev/null
    echo "✓ Linked main htdocs"
fi

# Browser content
if [ -d "$DUMP_DIR/sda0/opt/conn/data/browser" ]; then
    mkdir -p "$TEMP_SERVE_DIR/browser"
    ln -sf "$DUMP_DIR/sda0/opt/conn/data/browser"/* "$TEMP_SERVE_DIR/browser/" 2>/dev/null
    echo "✓ Linked browser content"
fi

# HMI assets
if [ -d "$DUMP_DIR/sda0/opt/hmi/ID5/data/ro/bmwm/id6l/assetDB" ]; then
    mkdir -p "$TEMP_SERVE_DIR/hmi-assets"
    ln -sf "$DUMP_DIR/sda0/opt/hmi/ID5/data/ro/bmwm/id6l/assetDB" "$TEMP_SERVE_DIR/hmi-assets/" 2>/dev/null
    echo "✓ Linked HMI assets"
fi

# Create main index
cat > "$TEMP_SERVE_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BMW iDrive 6 System Explorer</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #e0e0e0;
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        header {
            text-align: center;
            margin-bottom: 40px;
            padding: 30px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            background: linear-gradient(45deg, #ff6b6b, #4ecdc4);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .card {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 10px;
            padding: 25px;
            border: 1px solid rgba(255, 255, 255, 0.1);
            transition: all 0.3s;
        }
        .card:hover {
            transform: translateY(-5px);
            border-color: #4ecdc4;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
        }
        .card h3 {
            color: #4ecdc4;
            margin-bottom: 10px;
            font-size: 1.3em;
        }
        .card p {
            color: #b0b0b0;
            margin-bottom: 15px;
            line-height: 1.6;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: #4ecdc4;
            color: #1a1a2e;
            text-decoration: none;
            border-radius: 5px;
            font-weight: bold;
            transition: background 0.2s;
        }
        .btn:hover { background: #45b8af; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚗 BMW iDrive 6 System Explorer</h1>
            <p style="color: #b0b0b0; margin-top: 10px;">NBT EVO ID6 (Software 18-03)</p>
        </header>

        <div class="cards">
            <div class="card">
                <h3>📦 Extracted Assets</h3>
                <p>Browse 24,000+ extracted images, web files, XML configs, and scripts organized for easy exploration.</p>
                <a href="extracted-assets/viewer.html" class="btn">View Assets →</a>
            </div>

            <div class="card">
                <h3>🌐 Web Interfaces</h3>
                <p>Access Journaline and browser interfaces (limited functionality without backend services).</p>
                <a href="journaline.html" class="btn">Journaline →</a>
                <a href="browser/" class="btn" style="margin-left: 10px;">Browser →</a>
            </div>

            <div class="card">
                <h3>🖼️ HMI Assets</h3>
                <p>Explore HMI interface assets and images from the main iDrive applications.</p>
                <a href="hmi-assets/" class="btn">View HMI →</a>
            </div>

            <div class="card">
                <h3>📚 Documentation</h3>
                <p>Read guides on how to run the system, understand the architecture, and explore the dump.</p>
                <a href="../HOW_TO_RUN.md" class="btn">How to Run →</a>
                <a href="../UNDERSTANDING_IDRIVE.md" class="btn" style="margin-left: 10px;">Architecture →</a>
            </div>
        </div>
    </div>
</body>
</html>
EOF

echo ""
echo "✓ Created main index page"
echo ""
echo "Serving from: $TEMP_SERVE_DIR"
echo "Port: $PORT"
echo ""
echo "Access the viewer at:"
echo "  http://localhost:$PORT/"
echo "  http://localhost:$PORT/extracted-assets/viewer.html"
echo "  http://localhost:$PORT/journaline.html"
echo "  http://localhost:$PORT/browser/"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=========================================="
echo ""

cd "$TEMP_SERVE_DIR"
if command -v python3 &> /dev/null; then
    python3 -m http.server "$PORT"
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer "$PORT"
elif command -v node &> /dev/null; then
    npx -y http-server -p "$PORT"
else
    echo "Error: Neither Python nor Node.js found."
    exit 1
fi

