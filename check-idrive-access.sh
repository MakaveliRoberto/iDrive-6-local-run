#!/bin/bash

# Check if iDrive is accessible and what services are running

echo "=========================================="
echo "🔍 Checking iDrive 6 Access"
echo "=========================================="
echo ""

# Check if QEMU is running
if ! pgrep -f qemu-system-arm >/dev/null; then
    echo "❌ iDrive is not running"
    echo "Start it with: ./emulate-idrive-final-best.sh"
    exit 1
fi

echo "✅ iDrive QEMU process is running"
echo ""

# Check network ports
echo "Checking network ports..."
PORTS=(8022 8095 8100 8101 8102)
for port in "${PORTS[@]}"; do
    if lsof -ti:$port >/dev/null 2>&1; then
        echo "  ✅ Port $port: LISTENING"
        case $port in
            8022) echo "      → SSH access available" ;;
            8095|8100|8101|8102) echo "      → HTTP access available" ;;
        esac
    else
        echo "  ❌ Port $port: Not listening"
    fi
done

echo ""
echo "=========================================="
echo "💡 Access Options:"
echo "=========================================="
echo ""
echo "1. Web Interface (if lighttpd started):"
echo "   Try: http://localhost:8095"
echo "   Or: http://localhost:8100"
echo ""
echo "2. SSH (if sshd started):"
echo "   Try: ssh -p 8022 root@localhost"
echo ""
echo "3. Console Output:"
echo "   The system is running but not showing console output"
echo "   This is normal - QNX may not output until fully booted"
echo ""
echo "=========================================="
echo ""
echo "The system IS running - it's just not showing output yet."
echo "This is expected for embedded systems."
echo ""

