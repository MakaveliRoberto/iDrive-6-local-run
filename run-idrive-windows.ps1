# PowerShell script to run iDrive 6 on Windows
# Requires QEMU for Windows

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BootImage = Join-Path $ScriptDir "nbtevo-system-dump\sda2\boot1.ifs.patched"
$DiskImage = Join-Path $ScriptDir "emulation\idrive-disk.img"

Write-Host "=========================================="
Write-Host "🚀 Running iDrive 6 on Windows"
Write-Host "=========================================="
Write-Host ""

# Check if QEMU is installed
if (-not (Get-Command qemu-system-arm.exe -ErrorAction SilentlyContinue)) {
    Write-Host "❌ QEMU not found!"
    Write-Host ""
    Write-Host "Install QEMU:"
    Write-Host "  • Download: https://www.qemu.org/download/#windows"
    Write-Host "  • Or: choco install qemu"
    Write-Host ""
    exit 1
}

# Check if boot image exists
if (-not (Test-Path $BootImage)) {
    Write-Host "❌ Boot image not found: $BootImage"
    Write-Host ""
    Write-Host "Make sure you've cloned the repository and pulled LFS files:"
    Write-Host "  git lfs pull"
    Write-Host ""
    exit 1
}

Write-Host "✅ QEMU found"
Write-Host "✅ Boot image found"
Write-Host ""
Write-Host "Starting iDrive 6..."
Write-Host ""
Write-Host "Access at: http://localhost:8103"
Write-Host ""

# Run QEMU
qemu-system-arm.exe `
    -M virt `
    -cpu cortex-a15,midr=0x412fc0f1 `
    -m 2048 `
    -smp 2 `
    -kernel $BootImage `
    -drive file=$DiskImage,if=virtio,format=raw `
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 `
    -device virtio-net-device,netdev=net0 `
    -serial stdio `
    -display none

Write-Host ""
Write-Host "iDrive 6 stopped"
Write-Host ""

