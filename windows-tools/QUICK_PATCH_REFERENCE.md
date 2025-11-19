# Quick Patch Reference Card

**Fast reference for patching iDrive 6 kernel on Windows**

## ⚠️ FIRST: Download Git LFS Files!

```powershell
cd C:\Users\YourName\Documents\iDrive-6-local-run
git lfs install
git lfs pull
# Verify: dir nbtevo-system-dump\sda2\boot1.ifs* (should be ~1.5 MB each)
```

## 🚀 Quick Start (5 Steps)

### 1. Set Up QNX
```powershell
cd E:\qnx800
.\qnxsdp-env.bat
```

### 2. Disassemble Kernel
```powershell
cd C:\Users\YourName\Documents\iDrive-6-local-run
arm-unknown-nto-qnx8.0.0-objdump -d nbtevo-system-dump\sda2\boot1.ifs.patched > kernel-disassembly.txt
```

### 3. Find Stuck Address
- Open `kernel-disassembly.txt`
- Search for: `8749a5ac` (or new address from QEMU monitor)
- Look for wait loops (BNE branching backward)

### 4. Patch Binary
**Option A - Hex Editor:**
- Open `boot1.ifs.patched` in HxD
- Find instruction: `1A` (BNE)
- Change to: `0A` (BEQ) or `00 00 A0 E1` (NOP)

**Option B - Python Script:**
```powershell
python patch-kernel-aggressive.py
```

### 5. Test
```powershell
qemu-system-arm.exe -M virt -cpu cortex-a15,midr=0x412fc0f1 -m 2048 -smp 2 -kernel nbtevo-system-dump\sda2\boot1.ifs.patched -drive file=emulation\idrive-disk.img,if=virtio,format=raw -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 -device virtio-net-device,netdev=net0 -serial stdio -display none
```

---

## 📍 File Locations

| File | Location |
|------|----------|
| Patched Kernel | `nbtevo-system-dump\sda2\boot1.ifs.patched` |
| Original Backup | `nbtevo-system-dump\sda2\boot1.ifs.backup` |
| Disassembly | `kernel-disassembly.txt` (after running objdump) |
| QNX Tools | `E:\qnx800\host\win64\x86_64\usr\bin\` |

---

## 🔧 ARM Instruction Reference

| Instruction | Hex | Patch To |
|------------|-----|----------|
| `BNE` (wait loop) | `1A` | `0A` (BEQ) or `00 00 A0 E1` (NOP) |
| `BEQ` (success) | `0A` | Keep (already correct) |
| `CMP` (compare) | `E3 5x` | Keep (needed for logic) |

---

## 🔍 What to Look For

### Wait Loop Pattern:
```assembly
loop:
  LDR  r0, [address]    ; Load
  CMP  r0, #value       ; Compare
  BNE  loop             ; ← PATCH THIS! (1A → 0A)
```

### Error Check Pattern:
```assembly
  CMP  r0, #expected
  BNE  error_handler     ; ← PATCH THIS! (1A → 0A)
```

---

## ⚠️ Important Notes

1. **Always backup first:**
   ```powershell
   copy nbtevo-system-dump\sda2\boot1.ifs.patched boot1.ifs.patched.backup2
   ```

2. **Check QEMU monitor for stuck address:**
   ```powershell
   # Add to QEMU: -monitor telnet:localhost:4445,server,nowait
   telnet localhost 4445
   (qemu) info registers
   # Look for R15 (PC) value
   ```

3. **If still stuck:**
   - Get new PC address from QEMU monitor
   - Search for it in disassembly
   - Patch that location too

---

## 📚 Full Guide

See `MANUAL_KERNEL_PATCHING_WINDOWS.md` for complete step-by-step instructions.

