# 🎯 START HERE - Windows PC Setup

**Quick start guide to patch iDrive 6 kernel on Windows**

## ⚡ Fastest Way (3 Steps)

### 1. Get Files

**From Mac (Recommended):**
- Copy `boot1.ifs.patched` and other files from Mac to USB
- Copy to Windows: `C:\Users\YourName\Documents\iDrive-6-local-run\`

**OR From GitHub:**
```powershell
git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
cd iDrive-6-local-run
git lfs pull
```

### 2. Update QNX Path

Open `run-idrive-patch-windows.bat` in Notepad.

Find:
```batch
set QNX_PATH=E:\qnx800
```

Change to your QNX path (e.g., `C:\qnx710` or `C:\qnx800`)

### 3. Run Script

**Double-click:** `run-idrive-patch-windows.bat`

**OR Command Prompt:**
```cmd
run-idrive-patch-windows.bat
```

**OR PowerShell:**
```powershell
.\run-idrive-patch-windows.ps1
```

## ✅ That's It!

The script will:
- ✅ Check everything
- ✅ Create backup
- ✅ Patch kernel automatically
- ✅ Show you what to do next

## 📚 Need More Help?

- **Quick Start**: `README_WINDOWS_EXECUTABLE.md`
- **Full Manual**: `MANUAL_KERNEL_PATCHING_WINDOWS.md`
- **Troubleshooting**: See script output or full manual

## 🎉 Success!

After running, you'll have:
- ✅ Patched kernel ready to test
- ✅ Backup safe
- ✅ Ready for QEMU

**Next**: Test with QEMU!

---

**Questions?** Check `README_WINDOWS_EXECUTABLE.md` for detailed instructions.

