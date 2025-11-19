# 🚀 iDrive 6 Kernel Patching - Windows Executable Guide

**Simple step-by-step guide to run kernel patching on Windows**

## 📥 What You Need

1. **Repository files** (from Mac or GitHub)
2. **QNX Momentics IDE** installed (e.g., `E:\qnx800`)
3. **Python 3** (optional, for automated patching)
4. **QEMU** (for testing)

## 🎯 Quick Start (3 Steps)

### Step 1: Get Files

**Option A: From Mac (Recommended)**
- Copy files from Mac to USB drive
- Copy to Windows: `C:\Users\YourName\Documents\iDrive-6-local-run\`

**Option B: From GitHub**
```powershell
git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
cd iDrive-6-local-run
git lfs pull
```

### Step 2: Update QNX Path

**Open the script file:**
- `run-idrive-patch-windows.bat` (for Command Prompt)
- OR `run-idrive-patch-windows.ps1` (for PowerShell)

**Find this line:**
```batch
set QNX_PATH=E:\qnx800
```
or
```powershell
$QNX_PATH = "E:\qnx800"
```

**Change to your QNX installation path:**
- `C:\qnx710`
- `C:\qnx800`
- `E:\qnx800`
- Or wherever you installed QNX

### Step 3: Run the Script

**Option A: Double-click (Easiest)**
1. Double-click `run-idrive-patch-windows.bat`
2. Follow the prompts
3. Done!

**Option B: Command Prompt**
```cmd
cd C:\Users\YourName\Documents\iDrive-6-local-run
run-idrive-patch-windows.bat
```

**Option C: PowerShell**
```powershell
cd C:\Users\YourName\Documents\iDrive-6-local-run
.\run-idrive-patch-windows.ps1
```

## 📋 What the Script Does

1. ✅ Checks QNX installation
2. ✅ Verifies kernel files exist and are valid
3. ✅ Creates backup of patched kernel
4. ✅ Runs aggressive patching (if Python available)
5. ✅ Optionally disassembles kernel
6. ✅ Shows summary and next steps

## 🔧 Requirements

### Required:
- ✅ QNX Momentics IDE installed
- ✅ Kernel files (`boot1.ifs.patched` - must be ~1.5 MB, not ~100 bytes)

### Optional:
- Python 3 (for automated patching)
- QEMU (for testing)

## ⚠️ Troubleshooting

### "QNX not found"
- Update `QNX_PATH` in the script to your QNX installation
- Common paths: `C:\qnx710`, `C:\qnx800`, `E:\qnx800`

### "boot1.ifs.patched not found"
- Make sure you're in the repository directory
- Check: `dir nbtevo-system-dump\sda2\boot1.ifs*`

### "File too small"
- File is a Git LFS pointer (not actual binary)
- Run: `git lfs pull`
- Or copy actual files from Mac

### "Python not found"
- Install Python from python.org
- Or patch manually using hex editor (see `MANUAL_KERNEL_PATCHING_WINDOWS.md`)

### "objdump not found"
- Make sure QNX environment is set up correctly
- Check: `arm-unknown-nto-qnx8.0.0-objdump --version`

## 📁 Files Created

After running:
- `boot1.ifs.patched.backup2` - Backup before aggressive patching
- `kernel-disassembly.txt` - Full disassembly (if you chose to create it)
- Updated `boot1.ifs.patched` - Aggressively patched kernel

## 🧪 Testing

After patching, test with QEMU:

```powershell
.\run-idrive-windows.ps1
```

Or manually:
```powershell
qemu-system-arm.exe `
  -M virt `
  -cpu cortex-a15,midr=0x412fc0f1 `
  -m 2048 `
  -smp 2 `
  -kernel nbtevo-system-dump\sda2\boot1.ifs.patched `
  -drive file=emulation\idrive-disk.img,if=virtio,format=raw `
  -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 `
  -device virtio-net-device,netdev=net0 `
  -serial stdio `
  -display none
```

## 📚 More Information

- **Full Manual**: `MANUAL_KERNEL_PATCHING_WINDOWS.md`
- **Quick Reference**: `QUICK_PATCH_REFERENCE.md`
- **Git LFS Setup**: `GIT_LFS_SETUP_WINDOWS.md`
- **Transfer from Mac**: `TRANSFER_FILES_TO_WINDOWS.md`

## ✅ Checklist

Before running:
- [ ] QNX installed and path updated in script
- [ ] Kernel files present and valid (~1.5 MB each)
- [ ] Python installed (optional, for automated patching)
- [ ] Script file in repository directory

After running:
- [ ] Backup created
- [ ] Patching completed
- [ ] Disassembly created (optional)
- [ ] Ready to test with QEMU

## 🎉 Success!

If everything worked:
1. ✅ Kernel is patched
2. ✅ Backup is safe
3. ✅ Ready to test

**Next**: Run QEMU and see if system boots!

---

**Need help?** Check the troubleshooting section or see the full manual guides.

