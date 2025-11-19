# ============================================
# iDrive 6 Kernel Patching - PowerShell Script
# ============================================
# This script automates kernel patching on Windows
# Run: .\run-idrive-patch-windows.ps1

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "iDrive 6 Kernel Patching Tool" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Set QNX path (UPDATE THIS TO YOUR QNX INSTALLATION)
$QNX_PATH = "E:\qnx800"
$QNX_ENV = Join-Path $QNX_PATH "qnxsdp-env.bat"

# Check if QNX is installed
if (-not (Test-Path $QNX_ENV)) {
    Write-Host "ERROR: QNX not found at: $QNX_PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please update QNX_PATH in this script to your QNX installation" -ForegroundColor Yellow
    Write-Host "Default locations:" -ForegroundColor Yellow
    Write-Host "  C:\qnx710" -ForegroundColor Yellow
    Write-Host "  C:\qnx800" -ForegroundColor Yellow
    Write-Host "  E:\qnx800" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Get script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SCRIPT_DIR

Write-Host "Step 1: Setting up QNX environment..." -ForegroundColor Green
& cmd /c "`"$QNX_ENV`" && set" | ForEach-Object {
    if ($_ -match "^(.+?)=(.*)$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}
Write-Host "OK: QNX environment ready" -ForegroundColor Green
Write-Host ""

# Check if kernel files exist
Write-Host "Step 2: Checking kernel files..." -ForegroundColor Green
$KERNEL_FILE = "nbtevo-system-dump\sda2\boot1.ifs.patched"
if (-not (Test-Path $KERNEL_FILE)) {
    Write-Host "ERROR: boot1.ifs.patched not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please make sure you are in the repository directory:" -ForegroundColor Yellow
    Write-Host "  C:\Users\YourName\Documents\iDrive-6-local-run" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check file size (should be ~1.5 MB, not ~100 bytes)
$fileSize = (Get-Item $KERNEL_FILE).Length
if ($fileSize -lt 1000000) {
    Write-Host "WARNING: boot1.ifs.patched is too small ($fileSize bytes)" -ForegroundColor Yellow
    Write-Host "This might be a Git LFS pointer file!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please run: git lfs pull" -ForegroundColor Yellow
    Write-Host "Or copy actual files from Mac" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "OK: Kernel files found and valid ($([math]::Round($fileSize/1MB, 2)) MB)" -ForegroundColor Green
Write-Host ""

# Create backup
Write-Host "Step 3: Creating backup..." -ForegroundColor Green
$BACKUP_FILE = "nbtevo-system-dump\sda2\boot1.ifs.patched.backup2"
if (-not (Test-Path $BACKUP_FILE)) {
    Copy-Item $KERNEL_FILE $BACKUP_FILE
    Write-Host "OK: Backup created" -ForegroundColor Green
} else {
    Write-Host "OK: Backup already exists" -ForegroundColor Green
}
Write-Host ""

# Check for Python
Write-Host "Step 4: Checking Python..." -ForegroundColor Green
try {
    $pythonVersion = python --version 2>&1
    Write-Host "OK: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Python not found in PATH" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can:" -ForegroundColor Yellow
    Write-Host "  1. Install Python from python.org" -ForegroundColor Yellow
    Write-Host "  2. Or patch manually using hex editor (see MANUAL_KERNEL_PATCHING_WINDOWS.md)" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") { exit 1 }
}
Write-Host ""

# Run aggressive patching
Write-Host "Step 5: Running aggressive kernel patching..." -ForegroundColor Green
$PATCH_SCRIPT = "patch-kernel-aggressive.py"
if (Test-Path $PATCH_SCRIPT) {
    Write-Host "Running $PATCH_SCRIPT..." -ForegroundColor Cyan
    python $PATCH_SCRIPT
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Patching failed" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host ""
    Write-Host "OK: Patching complete!" -ForegroundColor Green
} else {
    Write-Host "WARNING: $PATCH_SCRIPT not found" -ForegroundColor Yellow
    Write-Host "Skipping automated patching" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can patch manually using:" -ForegroundColor Yellow
    Write-Host "  1. Hex editor (HxD)" -ForegroundColor Yellow
    Write-Host "  2. QNX tools (objdump + hex editor)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "See MANUAL_KERNEL_PATCHING_WINDOWS.md for details" -ForegroundColor Yellow
}
Write-Host ""

# Disassemble kernel (optional)
Write-Host "Step 6: Disassembling kernel (optional)..." -ForegroundColor Green
$DISASM_FILE = "kernel-disassembly.txt"

# Find objdump tool
$objdump = $null
$objdumpVersions = @("arm-unknown-nto-qnx8.0.0-objdump", "arm-unknown-nto-qnx7.1.0-objdump")
foreach ($version in $objdumpVersions) {
    if (Get-Command $version -ErrorAction SilentlyContinue) {
        $objdump = $version
        break
    }
}

if ($objdump) {
    Write-Host "Found: $objdump" -ForegroundColor Green
    Write-Host "This will create $DISASM_FILE (may be large, 10-50 MB)..." -ForegroundColor Yellow
    $disasm = Read-Host "Create disassembly? (y/n)"
    if ($disasm -eq "y") {
        Write-Host "Disassembling... (this may take a few minutes)" -ForegroundColor Cyan
        & $objdump -d $KERNEL_FILE | Out-File -FilePath $DISASM_FILE -Encoding UTF8
        if ($LASTEXITCODE -eq 0) {
            $disasmSize = (Get-Item $DISASM_FILE).Length
            Write-Host "OK: Disassembly saved to $DISASM_FILE ($([math]::Round($disasmSize/1MB, 2)) MB)" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Disassembly failed" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "WARNING: QNX objdump not found" -ForegroundColor Yellow
    Write-Host "Skipping disassembly" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To disassemble manually:" -ForegroundColor Yellow
    Write-Host "  arm-unknown-nto-qnx8.0.0-objdump -d boot1.ifs.patched > kernel-disassembly.txt" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Patched kernel: $KERNEL_FILE" -ForegroundColor Green
Write-Host "Backup:         $BACKUP_FILE" -ForegroundColor Green
if (Test-Path $DISASM_FILE) {
    Write-Host "Disassembly:   $DISASM_FILE" -ForegroundColor Green
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test with QEMU (see run-idrive-windows.ps1)" -ForegroundColor Yellow
Write-Host "  2. Check QEMU monitor if still stuck" -ForegroundColor Yellow
Write-Host "  3. Patch more locations if needed" -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"

