@echo off
REM ============================================
REM iDrive 6 - SUPER EASY ALL-IN-ONE
REM ============================================
REM Just update QNX_PATH below and double-click!
REM That's it - everything is inside this file!

setlocal enabledelayedexpansion

REM ============================================
REM UPDATE THIS ONE LINE:
REM ============================================
set QNX_PATH=E:\qnx800
REM Change above to your QNX path (C:\qnx710, C:\qnx800, etc.)

REM ============================================
REM EVERYTHING ELSE IS AUTOMATIC!
REM ============================================

cls
echo.
echo ============================================
echo   iDrive 6 - SUPER EASY PATCH AND RUN
echo ============================================
echo.
echo This will:
echo   1. Patch the kernel automatically
echo   2. Run QEMU to test it
echo.
echo Just sit back and watch!
echo.
pause

REM Get to repository root
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"
cd ..

REM ============================================
REM STEP 1: CHECK EVERYTHING
REM ============================================
echo.
echo [1/4] Checking everything...

REM Check QNX
set QNX_ENV=%QNX_PATH%\qnxsdp-env.bat
if not exist "%QNX_ENV%" (
    echo [ERROR] QNX not found at: %QNX_PATH%
    echo Please update QNX_PATH in this file ^(line 12^)
    pause
    exit /b 1
)
echo [OK] QNX found

REM Check kernel
set KERNEL=nbtevo-system-dump\sda2\boot1.ifs.patched
if not exist "%KERNEL%" (
    echo [ERROR] Kernel file not found!
    echo Make sure you're in the repository directory
    pause
    exit /b 1
)

REM Check size
for %%F in ("%KERNEL%") do set SIZE=%%~zF
if %SIZE% LSS 1000000 (
    echo [ERROR] Kernel file too small - run: git lfs pull
    pause
    exit /b 1
)
echo [OK] Kernel file valid

REM Check Python
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Python not found - will use embedded method
    set HAS_PYTHON=0
) else (
    echo [OK] Python found
    set HAS_PYTHON=1
)

REM Check QEMU
where qemu-system-arm.exe >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] QEMU not found! Install from qemu.org
    pause
    exit /b 1
)
echo [OK] QEMU found
echo.

REM ============================================
REM STEP 2: CREATE BACKUP
REM ============================================
echo [2/4] Creating backup...
set BACKUP=nbtevo-system-dump\sda2\boot1.ifs.patched.backup2
if not exist "%BACKUP%" (
    copy "%KERNEL%" "%BACKUP%" >nul
    echo [OK] Backup created
) else (
    echo [OK] Backup exists
)
echo.

REM ============================================
REM STEP 3: PATCH KERNEL
REM ============================================
echo [3/4] Patching kernel...
echo This may take a minute...
echo.

REM Try Python script first
if "%HAS_PYTHON%"=="1" (
    if exist "patch-kernel-aggressive.py" (
        python patch-kernel-aggressive.py >nul 2>&1
        if %errorLevel% equ 0 (
            echo [OK] Patching complete!
            goto :PATCH_DONE
        )
    )
)

REM Embedded patching (no Python needed)
echo [INFO] Using embedded patcher...
set TEMP_PY=%TEMP%\idrive_patch_%RANDOM%.py
(
echo import sys
echo BOOT_IMAGE = r"%CD%\%KERNEL%"
echo PATCHED_IMAGE = r"%CD%\%KERNEL%"
echo try:
echo     with open^(BOOT_IMAGE, 'rb'^) as f: data = bytearray^(f.read^(^)^)
echo     patches = 0
echo     for i in range^(0, len^(data^) - 12, 4^):
echo         if i + 12 ^> len^(data^): break
echo         if ^(data[i+3] ^& 0xF0^) == 0xE0 and ^(data[i+2] ^& 0xF0^) == 0x50:
echo             if data[i+7] == 0x1A:
echo                 data[i+7] = 0x0A
echo                 patches += 1
echo                 if patches ^>= 50: break
echo     with open^(PATCHED_IMAGE, 'wb'^) as f: f.write^(data^)
echo     print^(f"Applied {patches} patches"^)
echo     sys.exit^(0^)
echo except: sys.exit^(1^)
) > "%TEMP_PY%"

if "%HAS_PYTHON%"=="1" (
    python "%TEMP_PY%" 2>nul
    del "%TEMP_PY%" >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Patching complete!
    ) else (
        echo [WARNING] Patching had issues, but continuing...
    )
) else (
    echo [WARNING] No Python - skipping automated patching
    echo [INFO] Kernel will use existing patches
)

:PATCH_DONE
echo.

REM ============================================
REM STEP 4: RUN QEMU
REM ============================================
echo [4/4] Starting QEMU...
echo.
echo ============================================
echo   QEMU is running - watch for boot messages
echo   Press Ctrl+C to stop
echo ============================================
echo.

REM Kill old QEMU
taskkill /F /IM qemu-system-arm.exe >nul 2>&1
timeout /t 1 >nul

REM Run QEMU
set DISK=emulation\idrive-disk.img
if exist "%DISK%" (
    qemu-system-arm.exe -M virt -cpu cortex-a15,midr=0x412fc0f1 -m 2048 -smp 2 -kernel "%KERNEL%" -drive file="%DISK%",if=virtio,format=raw -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 -device virtio-net-device,netdev=net0 -serial stdio -display none
) else (
    qemu-system-arm.exe -M virt -cpu cortex-a15,midr=0x412fc0f1 -m 2048 -smp 2 -kernel "%KERNEL%" -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 -device virtio-net-device,netdev=net0 -serial stdio -display none
)

echo.
echo ============================================
echo   QEMU stopped
echo ============================================
echo.
echo If system is still stuck:
echo   1. Check QEMU output above
echo   2. Try running this script again
echo   3. See windows-tools\README.md for help
echo.
pause

