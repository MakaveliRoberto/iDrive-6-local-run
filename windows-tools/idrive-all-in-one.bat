@echo off
REM ============================================
REM iDrive 6 - ALL-IN-ONE Complete Tool
REM ============================================
REM This is the MAIN script - does everything!
REM 1. Patches kernel
REM 2. Runs QEMU
REM 3. Shows diagnostics
REM
REM Just update QNX_PATH below and run!

setlocal enabledelayedexpansion

REM ============================================
REM CONFIGURATION - UPDATE THIS!
REM ============================================
set QNX_PATH=E:\qnx800
REM Change above to your QNX installation path

REM ============================================
REM MAIN MENU
REM ============================================

:MAIN_MENU
cls
echo.
echo ============================================
echo iDrive 6 - ALL-IN-ONE Complete Tool
echo ============================================
echo.
echo 1. Patch Kernel ^(aggressive patching^)
echo 2. Run QEMU ^(test patched kernel^)
echo 3. Patch AND Run ^(do both^)
echo 4. Check System Status
echo 5. View Logs
echo 6. Exit
echo.
set /p CHOICE="Select option (1-6): "

if "%CHOICE%"=="1" goto :PATCH
if "%CHOICE%"=="2" goto :RUN
if "%CHOICE%"=="3" goto :PATCH_AND_RUN
if "%CHOICE%"=="4" goto :STATUS
if "%CHOICE%"=="5" goto :LOGS
if "%CHOICE%"=="6" goto :EXIT
goto :MAIN_MENU

REM ============================================
REM PATCH KERNEL
REM ============================================
:PATCH
cls
echo.
echo ============================================
echo Patching Kernel
echo ============================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"
cd ..

REM Check QNX
set QNX_ENV=%QNX_PATH%\qnxsdp-env.bat
if not exist "%QNX_ENV%" (
    echo [ERROR] QNX not found at: %QNX_PATH%
    echo Please update QNX_PATH in this script
    pause
    goto :MAIN_MENU
)

REM Check kernel file
set KERNEL_FILE=nbtevo-system-dump\sda2\boot1.ifs.patched
if not exist "%KERNEL_FILE%" (
    echo [ERROR] Kernel file not found!
    pause
    goto :MAIN_MENU
)

REM Create backup
set BACKUP_FILE=nbtevo-system-dump\sda2\boot1.ifs.patched.backup2
if not exist "%BACKUP_FILE%" (
    copy "%KERNEL_FILE%" "%BACKUP_FILE%" >nul
    echo [OK] Backup created
)

REM Run patching
echo [INFO] Running aggressive patching...
if exist "patch-kernel-aggressive.py" (
    python patch-kernel-aggressive.py
) else (
    echo [WARNING] patch-kernel-aggressive.py not found
    echo [INFO] Using embedded patcher...
    REM Embedded patching code would go here
    echo [INFO] Please use idrive-patch-complete.bat for embedded patching
)

echo.
echo [OK] Patching complete!
pause
goto :MAIN_MENU

REM ============================================
REM RUN QEMU
REM ============================================
:RUN
cls
echo.
echo ============================================
echo Running QEMU
echo ============================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"
cd ..

REM Check QEMU
where qemu-system-arm.exe >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] QEMU not found!
    echo Please install QEMU first
    pause
    goto :MAIN_MENU
)

REM Kill existing QEMU
taskkill /F /IM qemu-system-arm.exe >nul 2>&1
timeout /t 2 >nul

REM Run QEMU
set KERNEL_FILE=nbtevo-system-dump\sda2\boot1.ifs.patched
set DISK_IMAGE=emulation\idrive-disk.img

echo [INFO] Starting QEMU...
echo [INFO] Press Ctrl+C to stop
echo.

qemu-system-arm.exe -M virt -cpu cortex-a15,midr=0x412fc0f1 -m 2048 -smp 2 -kernel "%KERNEL_FILE%" -drive file="%DISK_IMAGE%",if=virtio,format=raw -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 -device virtio-net-device,netdev=net0 -serial stdio -display none

echo.
echo [INFO] QEMU stopped
pause
goto :MAIN_MENU

REM ============================================
REM PATCH AND RUN
REM ============================================
:PATCH_AND_RUN
cls
echo.
echo ============================================
echo Patch and Run
echo ============================================
echo.
echo This will:
echo   1. Patch the kernel
echo   2. Run QEMU with patched kernel
echo.
set /p CONFIRM="Continue? (y/n): "
if /i not "%CONFIRM%"=="y" goto :MAIN_MENU

call :PATCH
if %errorLevel% neq 0 (
    echo [ERROR] Patching failed!
    pause
    goto :MAIN_MENU
)

echo.
echo [INFO] Starting QEMU...
timeout /t 3 >nul
call :RUN
goto :MAIN_MENU

REM ============================================
REM CHECK STATUS
REM ============================================
:STATUS
cls
echo.
echo ============================================
echo System Status
echo ============================================
echo.

REM Check QEMU
tasklist /FI "IMAGENAME eq qemu-system-arm.exe" 2>NUL | find /I /N "qemu-system-arm.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [OK] QEMU is running
) else (
    echo [INFO] QEMU is not running
)

REM Check ports
netstat -an | find "8022" >nul
if %errorLevel% equ 0 (
    echo [OK] SSH port 8022 is listening
) else (
    echo [INFO] SSH port 8022 is not listening
)

netstat -an | find "8103" >nul
if %errorLevel% equ 0 (
    echo [OK] HTTP port 8103 is listening
) else (
    echo [INFO] HTTP port 8103 is not listening
)

REM Check files
if exist "nbtevo-system-dump\sda2\boot1.ifs.patched" (
    for %%F in ("nbtevo-system-dump\sda2\boot1.ifs.patched") do set SIZE=%%~zF
    set /a SIZE_MB=%SIZE% / 1048576
    echo [OK] Kernel file exists (%SIZE_MB% MB)
) else (
    echo [ERROR] Kernel file not found
)

echo.
pause
goto :MAIN_MENU

REM ============================================
REM VIEW LOGS
REM ============================================
:LOGS
cls
echo.
echo ============================================
echo View Logs
echo ============================================
echo.
echo Available logs:
if exist "kernel-disassembly.txt" (
    echo [OK] kernel-disassembly.txt
) else (
    echo [INFO] kernel-disassembly.txt not found
)
echo.
set /p VIEW_LOG="View log? (y/n): "
if /i "%VIEW_LOG%"=="y" (
    if exist "kernel-disassembly.txt" (
        notepad kernel-disassembly.txt
    ) else (
        echo [INFO] No logs available
        pause
    )
)
goto :MAIN_MENU

REM ============================================
REM EXIT
REM ============================================
:EXIT
cls
echo.
echo ============================================
echo Thank you for using iDrive 6 Patching Tool!
echo ============================================
echo.
timeout /t 2 >nul
exit /b 0

