@echo off
REM ============================================
REM iDrive 6 QEMU Runner - Complete Script
REM ============================================
REM This runs QEMU with the patched kernel
REM All configuration is in this file

setlocal enabledelayedexpansion

REM ============================================
REM CONFIGURATION
REM ============================================
set KERNEL_FILE=nbtevo-system-dump\sda2\boot1.ifs.patched
set DISK_IMAGE=emulation\idrive-disk.img
set QEMU_EXE=qemu-system-arm.exe

REM Network ports
set SSH_PORT=8022
set HTTP_PORT=8103

REM QEMU settings
set MACHINE=virt
set CPU=cortex-a15,midr=0x412fc0f1
set MEMORY=2048
set CORES=2

REM ============================================
REM MAIN SCRIPT
REM ============================================

echo.
echo ============================================
echo iDrive 6 QEMU Runner
echo ============================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"
cd ..

REM Check if QEMU is installed
where %QEMU_EXE% >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] %QEMU_EXE% not found in PATH
    echo.
    echo Please install QEMU:
    echo   1. Download from: https://www.qemu.org/download/#windows
    echo   2. Or use: choco install qemu
    echo   3. Add QEMU to PATH
    echo.
    pause
    exit /b 1
)

echo [OK] QEMU found
echo.

REM Check kernel file
if not exist "%KERNEL_FILE%" (
    echo [ERROR] Kernel file not found: %KERNEL_FILE%
    echo.
    echo Please make sure you are in the repository directory
    echo Current directory: %CD%
    echo.
    pause
    exit /b 1
)

REM Check file size
for %%F in ("%KERNEL_FILE%") do set SIZE=%%~zF
if %SIZE% LSS 1000000 (
    echo [ERROR] Kernel file is too small (%SIZE% bytes)
    echo [ERROR] This might be a Git LFS pointer file!
    echo.
    echo Please run: git lfs pull
    echo Or copy actual files from Mac
    echo.
    pause
    exit /b 1
)

echo [OK] Kernel file found and valid
echo.

REM Check disk image
if not exist "%DISK_IMAGE%" (
    echo [WARNING] Disk image not found: %DISK_IMAGE%
    echo [INFO] Will run without disk (kernel only)
    set USE_DISK=0
) else (
    echo [OK] Disk image found
    set USE_DISK=1
)
echo.

REM Kill any existing QEMU processes
echo [INFO] Checking for existing QEMU processes...
tasklist /FI "IMAGENAME eq %QEMU_EXE%" 2>NUL | find /I /N "%QEMU_EXE%">NUL
if "%ERRORLEVEL%"=="0" (
    echo [INFO] Stopping existing QEMU processes...
    taskkill /F /IM %QEMU_EXE% >nul 2>&1
    timeout /t 2 >nul
)
echo.

REM Build QEMU command
echo [INFO] Starting QEMU...
echo [INFO] Kernel: %KERNEL_FILE%
if "%USE_DISK%"=="1" (
    echo [INFO] Disk: %DISK_IMAGE%
)
echo [INFO] SSH port: %SSH_PORT%
echo [INFO] HTTP port: %HTTP_PORT%
echo.
echo ============================================
echo QEMU Output ^(Ctrl+C to stop^)
echo ============================================
echo.

REM Build command
set QEMU_CMD=%QEMU_EXE% -M %MACHINE% -cpu %CPU% -m %MEMORY% -smp %CORES% -kernel "%KERNEL_FILE%"

if "%USE_DISK%"=="1" (
    set QEMU_CMD=!QEMU_CMD! -drive file="%DISK_IMAGE%",if=virtio,format=raw,cache=writeback
)

set QEMU_CMD=!QEMU_CMD! -netdev user,id=net0,hostfwd=tcp::%SSH_PORT%-:22,hostfwd=tcp::%HTTP_PORT%-:80
set QEMU_CMD=!QEMU_CMD! -device virtio-net-device,netdev=net0
set QEMU_CMD=!QEMU_CMD! -serial stdio -display none -no-reboot

REM Optional: Add monitor
set /p USE_MONITOR="Enable QEMU monitor? (y/n): "
if /i "%USE_MONITOR%"=="y" (
    set QEMU_CMD=!QEMU_CMD! -monitor telnet:localhost:4445,server,nowait
    echo [INFO] Monitor available at: telnet localhost 4445
    echo.
)

REM Run QEMU
%QEMU_CMD%

echo.
echo ============================================
echo QEMU stopped
echo ============================================
echo.
pause

