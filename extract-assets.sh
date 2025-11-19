#!/bin/bash

# Script to extract all viewable assets from iDrive 6 system dump
# This makes it easier to explore and potentially build a demo viewer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR/nbtevo-system-dump"
EXTRACT_DIR="$SCRIPT_DIR/extracted-assets"

echo "=========================================="
echo "iDrive 6 Asset Extractor"
echo "=========================================="
echo ""

if [ ! -d "$DUMP_DIR" ]; then
    echo "Error: nbtevo-system-dump directory not found!"
    exit 1
fi

# Create extraction directory
mkdir -p "$EXTRACT_DIR"
cd "$EXTRACT_DIR"

echo "Extracting viewable assets..."

# Extract images
echo "  [1/6] Extracting images (PNG, JPG)..."
find "$DUMP_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \) \
    -exec sh -c 'mkdir -p "$1/$(dirname "${2#$3/}")" && cp "$2" "$1/${2#$3/}"' _ "$EXTRACT_DIR/images" {} "$DUMP_DIR" \; 2>/dev/null

# Extract web files
echo "  [2/6] Extracting web files (HTML, JS, CSS)..."
find "$DUMP_DIR" -type f \( -name "*.html" -o -name "*.htm" -o -name "*.js" -o -name "*.css" \) \
    -exec sh -c 'mkdir -p "$1/$(dirname "${2#$3/}")" && cp "$2" "$1/${2#$3/}"' _ "$EXTRACT_DIR/web" {} "$DUMP_DIR" \; 2>/dev/null

# Extract XML configuration
echo "  [3/6] Extracting XML configuration files..."
find "$DUMP_DIR" -type f -name "*.xml" \
    -exec sh -c 'mkdir -p "$1/$(dirname "${2#$3/}")" && cp "$2" "$1/${2#$3/}"' _ "$EXTRACT_DIR/xml" {} "$DUMP_DIR" \; 2>/dev/null

# Extract text/script files
echo "  [4/6] Extracting scripts and text files..."
find "$DUMP_DIR" -type f \( -name "*.sh" -o -name "*.ksh" -o -name "*.txt" -o -name "*.cfg" -o -name "*.conf" \) \
    -exec sh -c 'mkdir -p "$1/$(dirname "${2#$3/}")" && cp "$2" "$1/${2#$3/}"' _ "$EXTRACT_DIR/scripts" {} "$DUMP_DIR" \; 2>/dev/null

# Extract boot images
echo "  [5/6] Copying boot images..."
mkdir -p "$EXTRACT_DIR/boot"
cp "$DUMP_DIR/sda2/"*.ifs "$EXTRACT_DIR/boot/" 2>/dev/null
cp "$DUMP_DIR/sda2/"*.bin "$EXTRACT_DIR/boot/" 2>/dev/null

# Create index
echo "  [6/6] Creating index..."
cat > "$EXTRACT_DIR/INDEX.md" << 'EOF'
# Extracted iDrive 6 Assets

This directory contains all viewable/extractable assets from the iDrive 6 system dump.

## Structure

- `images/` - All PNG, JPG, GIF images
- `web/` - HTML, JavaScript, CSS files
- `xml/` - XML configuration and data files
- `scripts/` - Shell scripts and configuration files
- `boot/` - Boot images (IFS format)

## Statistics

EOF

IMG_COUNT=$(find "$EXTRACT_DIR/images" -type f 2>/dev/null | wc -l | tr -d ' ')
WEB_COUNT=$(find "$EXTRACT_DIR/web" -type f 2>/dev/null | wc -l | tr -d ' ')
XML_COUNT=$(find "$EXTRACT_DIR/xml" -type f 2>/dev/null | wc -l | tr -d ' ')
SCRIPT_COUNT=$(find "$EXTRACT_DIR/scripts" -type f 2>/dev/null | wc -l | tr -d ' ')

cat >> "$EXTRACT_DIR/INDEX.md" << EOF
- Images: $IMG_COUNT files
- Web files: $WEB_COUNT files
- XML files: $XML_COUNT files
- Scripts: $SCRIPT_COUNT files

## Next Steps

1. Browse the `images/` directory for HMI assets
2. Check `web/` for interface code
3. Study `xml/` for configuration
4. Use assets to build a demo viewer

EOF

echo ""
echo "✓ Extraction complete!"
echo ""
echo "Assets extracted to: $EXTRACT_DIR"
echo ""
echo "Summary:"
echo "  • Images: $IMG_COUNT files"
echo "  • Web files: $WEB_COUNT files"
echo "  • XML files: $XML_COUNT files"
echo "  • Scripts: $SCRIPT_COUNT files"
echo ""
echo "See INDEX.md for details"

