# 🚗 BMW iDrive 6 QNX System Emulation

**Complete emulation and patching tools for BMW iDrive 6 QNX system**

## 🚀 Quick Start (Windows)

### Super Easy - One File Solution

1. **Go to `windows-tools/` folder**
2. **Open `IDRIVE6-EASY.bat`** in Notepad
3. **Update ONE line** (line 12): `set QNX_PATH=E:\qnx800` → your QNX path
4. **Double-click `IDRIVE6-EASY.bat`**
5. **Done!** It patches and runs automatically

**That's it!** Everything is in one file.

📁 **See:** `windows-tools/README-EASY.md` for details

---

## 📁 Repository Structure

```
iDrive-6-local-run/
├── README.md                          ← You are here
├── windows-tools/                     ← Windows tools (START HERE!)
│   ├── IDRIVE6-EASY.bat              ← ⭐ MAIN FILE - Use this!
│   ├── README-EASY.md                ← Quick guide
│   └── ...                           ← Other tools
├── nbtevo-system-dump/               ← System dump (15 GB)
│   └── sda2/
│       ├── boot1.ifs.patched         ← Patched kernel
│       └── boot1.ifs.backup          ← Original backup
├── emulation/                        ← QEMU files
├── patch-kernel-aggressive.py        ← Python patching script
└── ...                               ← Documentation
```

---

## 🪟 For Windows Users

**Go to:** `windows-tools/` folder

**Main file:** `IDRIVE6-EASY.bat` - Everything in one file!

**Guides:**
- `README-EASY.md` - Super simple guide
- `README.md` - Complete overview
- `MANUAL_KERNEL_PATCHING_WINDOWS.md` - Detailed manual

---

## 🍎 For Mac Users

**Current Status:**
- ✅ Kernel patching complete (10 CPUID checks bypassed)
- ✅ System runs in QEMU
- ⚠️ Stuck on hardware wait loops (needs QNX IDE for deeper patching)

**Files:**
- `nbtevo-system-dump/sda2/boot1.ifs.patched` - Patched kernel
- `patch-kernel-aggressive.py` - Aggressive patching script
- `run-patched-kernel.sh` - Run with QEMU

**See:** `DIAGNOSTIC_REPORT.md` for current status

---

## 📋 Requirements

### Windows:
- ✅ QNX Momentics IDE (update path in script)
- ✅ QEMU (for testing)
- ✅ Python 3 (optional, for patching)
- ✅ Kernel files (~1.5 MB each, not pointer files)

### Mac:
- ✅ QEMU
- ✅ Python 3
- ✅ Kernel files

---

## 🔧 What This Does

1. **Patches QNX kernel** to bypass hardware checks
   - CPUID validation checks
   - Hardware wait loops
   - Device register checks

2. **Runs in QEMU** emulator
   - ARM Cortex-A15 emulation
   - Network forwarding (SSH: 8022, HTTP: 8103)
   - Serial console output

3. **Makes iDrive 6 boot** without real hardware

---

## 📚 Documentation

### Windows:
- **`windows-tools/README-EASY.md`** - Quick start guide
- **`windows-tools/MANUAL_KERNEL_PATCHING_WINDOWS.md`** - Complete manual
- **`windows-tools/QUICK_PATCH_REFERENCE.md`** - Quick reference

### General:
- **`DIAGNOSTIC_REPORT.md`** - System diagnostic report
- **`SESSION_SUMMARY.md`** - Complete session summary
- **`WINDOWS_QNX_SETUP.md`** - QNX setup guide

---

## 🎯 Current Status

### ✅ What Works:
- Kernel executes (high CPU usage)
- CPUID checks bypassed (10 patches)
- System runs stably
- Network ports listening

### ⚠️ What Needs Work:
- System stuck on hardware wait loops
- No serial output (stuck before console init)
- Services not starting (waiting for hardware)

### 🔧 Solution:
- Use QNX Momentics IDE to analyze and patch remaining hardware checks
- Or use aggressive patching script (`patch-kernel-aggressive.py`)

---

## 🚀 Getting Started

### Windows (Recommended):
```powershell
# 1. Clone repository
git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
cd iDrive-6-local-run

# 2. Get LFS files (if needed)
git lfs pull

# 3. Go to tools folder
cd windows-tools

# 4. Open IDRIVE6-EASY.bat, update QNX path, double-click!
```

### Mac:
```bash
# 1. Clone repository
git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
cd iDrive-6-local-run

# 2. Run patching
python3 patch-kernel-aggressive.py

# 3. Run QEMU
./run-patched-kernel.sh
```

---

## 📝 License & Credits

- **System:** BMW iDrive 6 QNX Neutrino RTOS
- **Emulation:** QEMU
- **Patching:** Custom scripts

**Note:** This is for educational/research purposes. Ensure you have proper authorization to work with this system.

---

## 🆘 Need Help?

1. **Windows:** Check `windows-tools/README-EASY.md`
2. **Mac:** Check `DIAGNOSTIC_REPORT.md`
3. **General:** Check `SESSION_SUMMARY.md`

---

## 📦 Files Overview

| File | Purpose |
|------|---------|
| `windows-tools/IDRIVE6-EASY.bat` | ⭐ Main Windows tool (one file, everything inside) |
| `patch-kernel-aggressive.py` | Aggressive kernel patching script |
| `nbtevo-system-dump/sda2/boot1.ifs.patched` | Patched kernel (ready to use) |
| `DIAGNOSTIC_REPORT.md` | System diagnostic report |

---

**🎉 Ready to go?** → Go to `windows-tools/` and run `IDRIVE6-EASY.bat`!
