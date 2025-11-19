# Quick Start - Windows with QNX 8.0 (E:\qnx800)

## Setup Steps

### 1. Clone Repository
```powershell
git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
cd iDrive-6-local-run
git lfs pull
```

### 2. Set QNX Environment
```powershell
cd E:\qnx800
.\qnxsdp-env.bat
```

### 3. Analyze Kernel
```powershell
# Navigate to project
cd [path-to-repo]

# Extract IFS image
qnx-ifsload -v nbtevo-system-dump\sda2\boot1.ifs.patched

# Disassemble kernel
arm-unknown-nto-qnx8.0.0-objdump -d nbtevo-system-dump\sda2\boot1.ifs.patched > kernel-disassembly.txt
```

### 4. Use QNX IDE
- Open QNX Momentics IDE
- File → Import → Existing Projects
- Select repository directory
- Analyze `boot1.ifs.patched`
- Patch hardware checks
- Rebuild IFS image

## Important Paths

- **QNX Installation**: `E:\qnx800`
- **Environment Script**: `E:\qnx800\qnxsdp-env.bat`
- **QNX Tools**: `E:\qnx800\host\win64\x86_64\usr\bin`
- **Kernel File**: `nbtevo-system-dump\sda2\boot1.ifs.patched`

## Quick Commands

```powershell
# Set environment (run in each new terminal)
cd E:\qnx800
.\qnxsdp-env.bat

# Verify QNX tools
qnx-ifsload --version
arm-unknown-nto-qnx8.0.0-objdump --version
```

See `WINDOWS_QNX_SETUP.md` for complete guide.

