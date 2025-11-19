# 🚀 SUPER EASY - One File Solution

## `IDRIVE6-EASY.bat` - That's It!

**One file. One line to change. Double-click. Done.**

## How to Use (3 Steps)

### 1. Open the file
Open `IDRIVE6-EASY.bat` in Notepad

### 2. Update ONE line
Find this line (line 12):
```batch
set QNX_PATH=E:\qnx800
```

Change to your QNX path:
- `C:\qnx710`
- `C:\qnx800`
- `E:\qnx800`
- Or wherever you installed QNX

### 3. Double-click and run!
That's it! The script will:
- ✅ Check everything
- ✅ Create backup
- ✅ Patch kernel
- ✅ Run QEMU
- ✅ Show you the boot

## What It Does

1. **Checks** - QNX, kernel file, Python, QEMU
2. **Backs up** - Creates backup automatically
3. **Patches** - Patches kernel (embedded code, no external files)
4. **Runs** - Starts QEMU with patched kernel

## Requirements

- ✅ QNX installed (update path in script)
- ✅ Kernel file present (`boot1.ifs.patched` - must be ~1.5 MB)
- ✅ QEMU installed (for running)

## That's It!

**No other files needed. No complicated setup. Just one .bat file!**

---

**Need help?** Check `README.md` in this folder.

