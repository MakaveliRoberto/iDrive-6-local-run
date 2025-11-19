# 🪟 Windows Tools for iDrive 6 Kernel Patching

**All Windows-specific tools and guides are in this folder**

## 🚀 Quick Start

1. **Read:** `START_HERE_WINDOWS.md` (quick start guide)
2. **Update QNX path** in `run-idrive-patch-windows.bat`
3. **Double-click:** `run-idrive-patch-windows.bat`
4. **Done!**

## 📁 Files in This Folder

### 🎯 Executable Scripts (Run These!)

- **`run-idrive-patch-windows.bat`** ⭐ - Main patching script (double-click to run)
- **`run-idrive-patch-windows.ps1`** - PowerShell version (same functionality)
- **`run-idrive-windows.ps1`** - Run QEMU with patched kernel

### 📚 Guides

- **`START_HERE_WINDOWS.md`** ⭐ - **READ THIS FIRST!** Quick 3-step guide
- **`README_WINDOWS_EXECUTABLE.md`** - Complete guide for the scripts
- **`MANUAL_KERNEL_PATCHING_WINDOWS.md`** - Full manual (detailed instructions)
- **`QUICK_PATCH_REFERENCE.md`** - Quick reference card
- **`GIT_LFS_SETUP_WINDOWS.md`** - Git LFS setup guide
- **`TRANSFER_FILES_TO_WINDOWS.md`** - Transfer files from Mac

## 🎯 Which File Should I Use?

### I want to patch the kernel quickly:
→ **`START_HERE_WINDOWS.md`** → **`run-idrive-patch-windows.bat`**

### I want detailed instructions:
→ **`README_WINDOWS_EXECUTABLE.md`** or **`MANUAL_KERNEL_PATCHING_WINDOWS.md`**

### I need to set up Git LFS:
→ **`GIT_LFS_SETUP_WINDOWS.md`**

### I'm transferring files from Mac:
→ **`TRANSFER_FILES_TO_WINDOWS.md`**

## ⚙️ Setup (One Time)

1. **Install QNX Momentics IDE**
   - Download from: https://www.qnx.com/developers/
   - License: 2A71-H1RS-JJ7U-7KBL-5ST9

2. **Update QNX Path in Script**
   - Open `run-idrive-patch-windows.bat`
   - Find: `set QNX_PATH=E:\qnx800`
   - Change to your QNX path

3. **Get Kernel Files**
   - From Mac: Copy to USB, then to Windows
   - From GitHub: `git lfs pull`

## 🚀 Usage

### Option 1: Double-Click (Easiest)
1. Double-click `run-idrive-patch-windows.bat`
2. Follow prompts
3. Done!

### Option 2: Command Prompt
```cmd
cd windows-tools
run-idrive-patch-windows.bat
```

### Option 3: PowerShell
```powershell
cd windows-tools
.\run-idrive-patch-windows.ps1
```

## 📋 What the Scripts Do

### `run-idrive-patch-windows.bat` / `.ps1`
- ✅ Checks QNX installation
- ✅ Verifies kernel files
- ✅ Creates backup
- ✅ Runs aggressive patching
- ✅ Optionally disassembles kernel
- ✅ Shows summary

### `run-idrive-windows.ps1`
- ✅ Runs QEMU with patched kernel
- ✅ Sets up network forwarding
- ✅ Shows boot output

## 🔧 Requirements

### Required:
- QNX Momentics IDE installed
- Kernel files (`boot1.ifs.patched` - must be ~1.5 MB)

### Optional:
- Python 3 (for automated patching)
- QEMU (for testing)

## 📂 Folder Structure

```
windows-tools/
├── README.md                          ← You are here
├── START_HERE_WINDOWS.md              ← Quick start
├── run-idrive-patch-windows.bat      ← Main script ⭐
├── run-idrive-patch-windows.ps1      ← PowerShell version
├── run-idrive-windows.ps1            ← QEMU runner
├── README_WINDOWS_EXECUTABLE.md      ← Full guide
├── MANUAL_KERNEL_PATCHING_WINDOWS.md  ← Detailed manual
├── QUICK_PATCH_REFERENCE.md          ← Quick reference
├── GIT_LFS_SETUP_WINDOWS.md          ← Git LFS guide
└── TRANSFER_FILES_TO_WINDOWS.md      ← Transfer guide
```

## ⚠️ Troubleshooting

### Script not found
- Make sure you're in the `windows-tools` folder
- Or use full path: `C:\path\to\iDrive-6-local-run\windows-tools\run-idrive-patch-windows.bat`

### QNX not found
- Update `QNX_PATH` in the script
- Common paths: `C:\qnx710`, `C:\qnx800`, `E:\qnx800`

### Files not found
- Make sure you're in the repository root when running
- Or copy scripts to repository root

## 🎉 Success!

After running the patching script:
- ✅ Kernel is patched
- ✅ Backup is safe
- ✅ Ready to test with QEMU

**Next**: Run `run-idrive-windows.ps1` to test!

---

**Need help?** Check the guides or see the main repository README.

