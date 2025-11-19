@echo off
REM ============================================
REM iDrive 6 Kernel Patching - Windows Batch Script
REM ============================================
REM This script automates kernel patching on Windows
REM Run this as Administrator for best results

echo.
echo ============================================
echo iDrive 6 Kernel Patching Tool
echo ============================================
echo.

REM Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Not running as Administrator
    echo Some operations may require admin rights
    echo.
)

REM Set QNX path (UPDATE THIS TO YOUR QNX INSTALLATION)
set QNX_PATH=E:\qnx800
set QNX_ENV=%QNX_PATH%\qnxsdp-env.bat

REM Check if QNX is installed
if not exist "%QNX_ENV%" (
    echo ERROR: QNX not found at: %QNX_PATH%
    echo.
    echo Please update QNX_PATH in this script to your QNX installation
    echo Default locations:
    echo   C:\qnx710
    echo   C:\qnx800
    echo   E:\qnx800
    echo.
    pause
    exit /b 1
)

REM Get script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo Step 1: Setting up QNX environment...
call "%QNX_ENV%"
if %errorLevel% neq 0 (
    echo ERROR: Failed to set up QNX environment
    pause
    exit /b 1
)
echo OK: QNX environment ready
echo.

REM Check if kernel files exist
echo Step 2: Checking kernel files...
if not exist "nbtevo-system-dump\sda2\boot1.ifs.patched" (
    echo ERROR: boot1.ifs.patched not found!
    echo.
    echo Please make sure you are in the repository directory:
    echo   C:\Users\YourName\Documents\iDrive-6-local-run
    echo.
    pause
    exit /b 1
)

REM Check file sizes (should be ~1.5 MB, not ~100 bytes)
for %%F in ("nbtevo-system-dump\sda2\boot1.ifs.patched") do set SIZE=%%~zF
if %SIZE% LSS 1000000 (
    echo WARNING: boot1.ifs.patched is too small (%SIZE% bytes)
    echo This might be a Git LFS pointer file!
    echo.
    echo Please run: git lfs pull
    echo Or copy actual files from Mac
    echo.
    pause
    exit /b 1
)
echo OK: Kernel files found and valid
echo.

REM Create backup
echo Step 3: Creating backup...
if not exist "nbtevo-system-dump\sda2\boot1.ifs.patched.backup2" (
    copy "nbtevo-system-dump\sda2\boot1.ifs.patched" "nbtevo-system-dump\sda2\boot1.ifs.patched.backup2" >nul
    echo OK: Backup created
) else (
    echo OK: Backup already exists
)
echo.

REM Check for Python
echo Step 4: Checking Python...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Python not found in PATH
    echo.
    echo You can:
    echo   1. Install Python from python.org
    echo   2. Or patch manually using hex editor (see MANUAL_KERNEL_PATCHING_WINDOWS.md)
    echo.
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "%CONTINUE%"=="y" exit /b 1
) else (
    python --version
    echo OK: Python found
)
echo.

REM Run aggressive patching
echo Step 5: Running aggressive kernel patching...
if exist "patch-kernel-aggressive.py" (
    echo Running patch-kernel-aggressive.py...
    python patch-kernel-aggressive.py
    if %errorLevel% neq 0 (
        echo ERROR: Patching failed
        pause
        exit /b 1
    )
    echo.
    echo OK: Patching complete!
) else (
    echo WARNING: patch-kernel-aggressive.py not found
    echo Skipping automated patching
    echo.
    echo You can patch manually using:
    echo   1. Hex editor (HxD)
    echo   2. QNX tools (objdump + hex editor)
    echo.
    echo See MANUAL_KERNEL_PATCHING_WINDOWS.md for details
)
echo.

REM Disassemble kernel (optional but recommended)
echo Step 6: Disassembling kernel (this may take a while)...
set DISASM_FILE=kernel-disassembly.txt

REM Find objdump tool
set OBJDUMP=
where arm-unknown-nto-qnx8.0.0-objdump >nul 2>&1
if %errorLevel% equ 0 (
    set OBJDUMP=arm-unknown-nto-qnx8.0.0-objdump
) else (
    where arm-unknown-nto-qnx7.1.0-objdump >nul 2>&1
    if %errorLevel% equ 0 (
        set OBJDUMP=arm-unknown-nto-qnx7.1.0-objdump
    )
)

if defined OBJDUMP (
    echo Using: %OBJDUMP%
    echo This will create kernel-disassembly.txt (may be large)...
    set /p DISASM="Create disassembly? (y/n): "
    if /i "%DISASM%"=="y" (
        %OBJDUMP% -d "nbtevo-system-dump\sda2\boot1.ifs.patched" > "%DISASM_FILE%"
        if %errorLevel% equ 0 (
            echo OK: Disassembly saved to %DISASM_FILE%
        ) else (
            echo WARNING: Disassembly failed
        )
    )
) else (
    echo WARNING: QNX objdump not found
    echo Skipping disassembly
    echo.
    echo To disassemble manually:
    echo   arm-unknown-nto-qnx8.0.0-objdump -d boot1.ifs.patched ^> kernel-disassembly.txt
)
echo.

REM Summary
echo ============================================
echo Summary
echo ============================================
echo.
echo Patched kernel: nbtevo-system-dump\sda2\boot1.ifs.patched
echo Backup:         nbtevo-system-dump\sda2\boot1.ifs.patched.backup2
if exist "%DISASM_FILE%" (
    echo Disassembly:   %DISASM_FILE%
)
echo.
echo Next steps:
echo   1. Test with QEMU (see run-idrive-windows.ps1)
echo   2. Check QEMU monitor if still stuck
echo   3. Patch more locations if needed
echo.
echo ============================================
echo Done!
echo ============================================
echo.
pause

