# Windows + QNX Setup Guide

Complete guide for setting up and running iDrive 6 on Windows with QNX Momentics IDE.

## Step 1: Clone Repository on Windows

### Option A: Using Git for Windows

1. **Install Git for Windows**
   - Download: https://git-scm.com/download/win
   - Install with default options
   - Make sure to install Git LFS during installation

2. **Install Git LFS** (if not included)
   ```powershell
   git lfs install
   ```

3. **Clone the repository**
   ```powershell
   cd C:\Users\YourName\Documents
   git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
   cd iDrive-6-local-run
   ```

4. **Verify files downloaded**
   ```powershell
   git lfs pull
   dir
   ```

### Option B: Using GitHub Desktop

1. Download GitHub Desktop: https://desktop.github.com/
2. Sign in to GitHub
3. Clone repository: File → Clone Repository → Select `iDrive-6-local-run`
4. Wait for all files to download (including LFS files)

## Step 2: Install QNX Momentics IDE

1. **Download QNX Momentics**
   - Go to: https://www.qnx.com/developers/
   - Download QNX Software Development Platform (SDP)
   - You have a license: Named User License
   - Key: 2A71-H1RS-JJ7U-7KBL-5ST9
   - Serial: 911285-09973098

2. **Install QNX Momentics**
   - Run installer
   - Install to default location (usually `C:\qnx710` or `C:\Program Files\QNX Software Systems`)
   - Complete installation

3. **Set up QNX Environment**
   - Open Command Prompt or PowerShell
   - Navigate to QNX installation directory
   - Run environment setup:
     ```powershell
     cd C:\qnx710
     .\qnxsdp-env.bat
     ```
   - Or add to PATH:
     ```powershell
     $env:PATH += ";C:\qnx710\host\win64\x86_64\usr\bin"
     ```

4. **Verify QNX Installation**
   ```powershell
   qnx-ifsload --version
   arm-unknown-nto-qnx7.1.0-objdump --version
   ```

## Step 3: Analyze and Patch Kernel

### Extract IFS Image

```powershell
cd C:\Users\YourName\Documents\iDrive-6-local-run
qnx-ifsload -v nbtevo-system-dump\sda2\boot1.ifs.patched
```

### Disassemble Kernel

```powershell
# Disassemble the patched kernel
arm-unknown-nto-qnx7.1.0-objdump -d nbtevo-system-dump\sda2\boot1.ifs.patched > kernel-disassembly.txt

# Or use QNX IDE's built-in disassembler
```

### Find Hardware Checks

1. **Open QNX Momentics IDE**
2. **Import Project**
   - File → Import → Existing Projects into Workspace
   - Select the repository directory
3. **Analyze Binary**
   - Use QNX IDE's binary analysis tools
   - Search for hardware check patterns:
     - `get_omap5430_info`
     - `Unsupported CPUID`
     - FPGA register checks
     - GPIO device checks

### Patch Hardware Checks

1. **Identify Check Locations**
   - Find CPUID validation code
   - Find FPGA/GPIO check code
   - Find device register checks

2. **Patch Instructions**
   - Use QNX tools to modify binary
   - Or use hex editor with QNX knowledge
   - Change BNE → BEQ (invert conditions)
   - NOP out wait loops
   - Patch error returns → success

3. **Rebuild IFS Image**
   ```powershell
   qnx-ifs -v -o boot1.ifs.fully-patched [patched files]
   ```

## Step 4: Run iDrive 6

### Option A: Using QEMU on Windows

1. **Install QEMU for Windows**
   - Download: https://www.qemu.org/download/#windows
   - Or use: `choco install qemu` (if you have Chocolatey)

2. **Run with QEMU**
   ```powershell
   qemu-system-arm.exe `
     -M virt `
     -cpu cortex-a15,midr=0x412fc0f1 `
     -m 2048 `
     -smp 2 `
     -kernel nbtevo-system-dump\sda2\boot1.ifs.fully-patched `
     -drive file=emulation\idrive-disk.img,if=virtio,format=raw `
     -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 `
     -device virtio-net-device,netdev=net0 `
     -serial stdio `
     -display none
   ```

### Option B: Using QNX Simulator

1. **Start QNX Simulator**
   ```powershell
   qnx-simulator
   ```

2. **Load iDrive System**
   - Use QNX IDE to deploy to simulator
   - Or manually load the IFS image

### Option C: Using QNX IDE

1. **Create QNX Project**
   - File → New → QNX Project
   - Select ARM architecture
   - Import existing files

2. **Build and Deploy**
   - Build project
   - Deploy to target (simulator or hardware)

## Step 5: Access iDrive 6

Once running:

- **HTTP Interface**: http://localhost:8103
- **SSH Access**: `ssh root@localhost -p 8022`
- **QNX Shell**: Through QNX IDE terminal

## Troubleshooting

### Git LFS Issues

If LFS files don't download:
```powershell
git lfs install
git lfs pull
```

### QNX Tools Not Found

Add to PATH:
```powershell
$env:PATH += ";C:\qnx710\host\win64\x86_64\usr\bin"
```

### QEMU Not Found

Install via:
- Chocolatey: `choco install qemu`
- Or download from: https://www.qemu.org/download/#windows

### Large File Issues

If files are missing:
```powershell
git lfs fetch --all
git lfs checkout
```

## Quick Start Script for Windows

Create `run-idrive-windows.ps1`:

```powershell
# Run iDrive 6 on Windows
$BOOT_IMAGE = "nbtevo-system-dump\sda2\boot1.ifs.patched"
$DISK_IMAGE = "emulation\idrive-disk.img"

qemu-system-arm.exe `
    -M virt `
    -cpu cortex-a15,midr=0x412fc0f1 `
    -m 2048 `
    -smp 2 `
    -kernel $BOOT_IMAGE `
    -drive file=$DISK_IMAGE,if=virtio,format=raw `
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 `
    -device virtio-net-device,netdev=net0 `
    -serial stdio `
    -display none
```

Run with:
```powershell
.\run-idrive-windows.ps1
```

## Next Steps

1. ✅ Clone repository on Windows
2. ✅ Install QNX Momentics IDE
3. ✅ Analyze kernel with QNX tools
4. ✅ Patch remaining hardware checks
5. ✅ Run iDrive 6 system

## Resources

- QNX Documentation: https://www.qnx.com/developers/docs/
- QNX Momentics IDE Guide: See `QNX_IDE_SETUP.md`
- Kernel Patching: See `PATCHING_STATUS.md`
- Repository: https://github.com/MakaveliRoberto/iDrive-6-local-run

