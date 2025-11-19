@echo off
REM ============================================
REM iDrive 6 Complete Kernel Patching Tool
REM ============================================
REM This is an ALL-IN-ONE script with everything included
REM Just update QNX_PATH below and run!

setlocal enabledelayedexpansion

REM ============================================
REM CONFIGURATION - UPDATE THIS!
REM ============================================
set QNX_PATH=E:\qnx800
REM Change above to your QNX installation path
REM Common: C:\qnx710, C:\qnx800, E:\qnx800

REM ============================================
REM MAIN SCRIPT STARTS HERE
REM ============================================

echo.
echo ============================================
echo iDrive 6 Complete Kernel Patching Tool
echo ============================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"
cd ..

REM Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Not running as Administrator
    echo [INFO] Some operations may require admin rights
    echo.
)

REM ============================================
REM Step 1: Check QNX Installation
REM ============================================
echo [Step 1/7] Checking QNX installation...
set QNX_ENV=%QNX_PATH%\qnxsdp-env.bat

if not exist "%QNX_ENV%" (
    echo [ERROR] QNX not found at: %QNX_PATH%
    echo.
    echo Please update QNX_PATH in this script (line 12)
    echo Default locations:
    echo   C:\qnx710
    echo   C:\qnx800
    echo   E:\qnx800
    echo.
    pause
    exit /b 1
)

echo [OK] QNX found at: %QNX_PATH%
call "%QNX_ENV%" >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Failed to set up QNX environment
    echo [INFO] Continuing anyway...
) else (
    echo [OK] QNX environment ready
)
echo.

REM ============================================
REM Step 2: Check Kernel Files
REM ============================================
echo [Step 2/7] Checking kernel files...
set KERNEL_FILE=nbtevo-system-dump\sda2\boot1.ifs.patched

if not exist "%KERNEL_FILE%" (
    echo [ERROR] %KERNEL_FILE% not found!
    echo.
    echo Please make sure you are in the repository directory:
    echo   C:\Users\YourName\Documents\iDrive-6-local-run
    echo.
    echo Current directory: %CD%
    echo.
    pause
    exit /b 1
)

REM Check file size (should be ~1.5 MB, not ~100 bytes)
for %%F in ("%KERNEL_FILE%") do set SIZE=%%~zF
if %SIZE% LSS 1000000 (
    echo [ERROR] %KERNEL_FILE% is too small (%SIZE% bytes)
    echo [ERROR] This might be a Git LFS pointer file!
    echo.
    echo Please run: git lfs pull
    echo Or copy actual files from Mac
    echo.
    pause
    exit /b 1
)

set /a SIZE_MB=%SIZE% / 1048576
echo [OK] Kernel file found and valid (%SIZE_MB% MB)
echo.

REM ============================================
REM Step 3: Create Backup
REM ============================================
echo [Step 3/7] Creating backup...
set BACKUP_FILE=nbtevo-system-dump\sda2\boot1.ifs.patched.backup2

if not exist "%BACKUP_FILE%" (
    copy "%KERNEL_FILE%" "%BACKUP_FILE%" >nul
    echo [OK] Backup created: %BACKUP_FILE%
) else (
    echo [OK] Backup already exists
)
echo.

REM ============================================
REM Step 4: Check Python
REM ============================================
echo [Step 4/7] Checking Python...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Python not found in PATH
    echo [INFO] Will use embedded patching method instead
    set USE_PYTHON=0
) else (
    python --version
    echo [OK] Python found
    set USE_PYTHON=1
)
echo.

REM ============================================
REM Step 5: Patch Kernel
REM ============================================
echo [Step 5/7] Patching kernel...
echo.

if "%USE_PYTHON%"=="1" (
    if exist "patch-kernel-aggressive.py" (
        echo [INFO] Running Python patching script...
        python patch-kernel-aggressive.py
        if %errorLevel% neq 0 (
            echo [ERROR] Python patching failed
            echo [INFO] Trying embedded patching method...
            goto :EMBEDDED_PATCH
        ) else (
            echo [OK] Python patching complete!
            goto :PATCH_DONE
        )
    ) else (
        echo [WARNING] patch-kernel-aggressive.py not found
        echo [INFO] Using embedded patching method...
        goto :EMBEDDED_PATCH
    )
) else (
    echo [INFO] Using embedded patching method (no Python)...
    goto :EMBEDDED_PATCH
)

:EMBEDDED_PATCH
echo [INFO] Running embedded binary patcher...
echo [INFO] This patches BNE instructions to BEQ (inverts conditions)

REM Create temporary Python script with embedded code
set TEMP_PY=%TEMP%\idrive_patch_%RANDOM%.py
(
echo import sys
echo import os
echo.
echo BOOT_IMAGE = r"%CD%\%KERNEL_FILE%"
echo BACKUP_IMAGE = r"%CD%\nbtevo-system-dump\sda2\boot1.ifs.backup"
echo PATCHED_IMAGE = r"%CD%\%KERNEL_FILE%"
echo.
echo def patch_kernel^(data^):
echo     patches = []
echo     applied = 0
echo     # Find CMP + BNE patterns and patch them
echo     for i in range^(0, len^(data^) - 12, 4^):
echo         if i + 12 ^> len^(data^):
echo             break
echo         inst1 = data[i:i+4]
echo         inst2 = data[i+4:i+8]
echo         if len^(inst1^) != 4 or len^(inst2^) != 4:
echo             continue
echo         # CMP instruction = 0xE35xxxxx
echo         if ^(inst1[3] ^& 0xF0^) == 0xE0 and ^(inst1[2] ^& 0xF0^) == 0x50:
echo             # BNE instruction = 0x1A
echo             if inst2[3] == 0x1A:
echo                 patches.append^(i+4^)
echo                 applied += 1
echo                 if applied ^>= 50:  # Limit patches
echo                     break
echo     # Apply patches
echo     for offset in patches:
echo         if offset + 4 ^<= len^(data^):
echo             inst = data[offset:offset+4]
echo             if len^(inst^) == 4 and inst[3] == 0x1A:
echo                 new_inst = bytes^([inst[0], inst[1], inst[2], 0x0A]^)
echo                 data = data[:offset] + new_inst + data[offset+4:]
echo     return data, len^(patches^)
echo.
echo try:
echo     with open^(BOOT_IMAGE, 'rb'^) as f:
echo         data = bytearray^(f.read^(^)^)
echo     print^(f"Loaded: {len^(data^)} bytes"^)
echo     data, patch_count = patch_kernel^(data^)
echo     print^(f"Found {patch_count} patches"^)
echo     with open^(PATCHED_IMAGE, 'wb'^) as f:
echo         f.write^(data^)
echo     print^(f"Applied {patch_count} patches"^)
echo     print^(f"Patched image saved: {PATCHED_IMAGE}"^)
echo     sys.exit^(0^)
echo except Exception as e:
echo     print^(f"Error: {e}"^)
echo     sys.exit^(1^)
) > "%TEMP_PY%"

REM Try to run embedded Python code
if "%USE_PYTHON%"=="1" (
    python "%TEMP_PY%"
    set PATCH_RESULT=%errorLevel%
    del "%TEMP_PY%" >nul 2>&1
    if %PATCH_RESULT% equ 0 (
        echo [OK] Embedded patching complete!
        goto :PATCH_DONE
    )
)

REM If Python failed, try hex editor method (manual instructions)
echo [WARNING] Automated patching not available
echo [INFO] You can patch manually using:
echo   1. Hex editor ^(HxD^)
echo   2. QNX tools ^(objdump + hex editor^)
echo.
echo See windows-tools\MANUAL_KERNEL_PATCHING_WINDOWS.md for details
goto :PATCH_DONE

:PATCH_DONE
echo.

REM ============================================
REM Step 6: Disassemble Kernel (Optional)
REM ============================================
echo [Step 6/7] Disassembling kernel ^(optional^)...
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
    echo [INFO] Found: %OBJDUMP%
    echo [INFO] This will create %DISASM_FILE% ^(may be large, 10-50 MB^)...
    set /p DISASM="Create disassembly? (y/n): "
    if /i "%DISASM%"=="y" (
        echo [INFO] Disassembling... ^(this may take a few minutes^)
        %OBJDUMP% -d "%KERNEL_FILE%" > "%DISASM_FILE%"
        if %errorLevel% equ 0 (
            for %%F in ("%DISASM_FILE%") do set DISASM_SIZE=%%~zF
            set /a DISASM_SIZE_MB=!DISASM_SIZE! / 1048576
            echo [OK] Disassembly saved to %DISASM_FILE% ^(!DISASM_SIZE_MB! MB^)
        ) else (
            echo [WARNING] Disassembly failed
        )
    ) else (
        echo [INFO] Skipping disassembly
    )
) else (
    echo [WARNING] QNX objdump not found
    echo [INFO] Skipping disassembly
    echo [INFO] To disassemble manually:
    echo   arm-unknown-nto-qnx8.0.0-objdump -d boot1.ifs.patched ^> kernel-disassembly.txt
)
echo.

REM ============================================
REM Step 7: Summary
REM ============================================
echo [Step 7/7] Summary
echo.
echo ============================================
echo Summary
echo ============================================
echo.
echo Patched kernel: %KERNEL_FILE%
echo Backup:         %BACKUP_FILE%
if exist "%DISASM_FILE%" (
    echo Disassembly:   %DISASM_FILE%
)
echo.
echo ============================================
echo Next Steps
echo ============================================
echo.
echo 1. Test with QEMU:
echo    qemu-system-arm.exe -M virt -cpu cortex-a15,midr=0x412fc0f1 -m 2048 -smp 2 -kernel %KERNEL_FILE% -drive file=emulation\idrive-disk.img,if=virtio,format=raw -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 -device virtio-net-device,netdev=net0 -serial stdio -display none
echo.
echo 2. If still stuck, check QEMU monitor:
echo    Add: -monitor telnet:localhost:4445,server,nowait
echo    Then: telnet localhost 4445
echo    Command: info registers
echo.
echo 3. Patch more locations if needed:
echo    See windows-tools\MANUAL_KERNEL_PATCHING_WINDOWS.md
echo.
echo ============================================
echo Done!
echo ============================================
echo.
pause

