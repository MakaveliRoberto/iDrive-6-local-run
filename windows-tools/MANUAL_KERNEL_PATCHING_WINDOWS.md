# Manual Kernel Patching Guide for Windows + QNX IDE

**Complete step-by-step guide to analyze and patch the iDrive 6 kernel on Windows**

## ⚠️ IMPORTANT: Git LFS Setup First!

**The kernel files are stored in Git LFS (Large File Storage). You MUST download them first!**

### Step 0: Download Actual Files (CRITICAL!)

After cloning the repository, the files you see are just **pointer files** (text files with metadata). You need to download the actual binary files:

```powershell
# Navigate to repository
cd C:\Users\YourName\Documents\iDrive-6-local-run

# Install Git LFS (if not already installed)
git lfs install

# Download all LFS files (this is CRITICAL!)
git lfs pull

# Verify files are downloaded (should show actual file sizes, not small text files)
dir nbtevo-system-dump\sda2\boot1.ifs*
```

**Expected file sizes:**
- `boot1.ifs.patched` should be **~1.5 MB** (1,610,796 bytes)
- `boot1.ifs.backup` should be **~1.5 MB** (1,610,796 bytes)
- If they're only **~100 bytes**, they're still pointer files - run `git lfs pull` again!

### Troubleshooting Git LFS

If files are still small after `git lfs pull`:

```powershell
# Force fetch all LFS files
git lfs fetch --all
git lfs checkout

# Or re-clone with LFS
git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
cd iDrive-6-local-run
git lfs pull
```

---

## 📍 Where to Find Everything

### Repository Location
After cloning from GitHub:
```
C:\Users\YourName\Documents\iDrive-6-local-run\
```

### Key Files You Need
```
iDrive-6-local-run\
├── nbtevo-system-dump\
│   └── sda2\
│       ├── boot1.ifs.patched      ← Current patched kernel (10 CPUID checks bypassed)
│       ├── boot1.ifs.backup       ← Original unpatched kernel
│       └── boot1.ifs              ← Also original
├── patch-kernel-aggressive.py     ← Python script (for reference)
└── WINDOWS_QNX_SETUP.md           ← Setup instructions
```

### QNX Installation Location
- Default: `C:\qnx710\` or `C:\qnx800\`
- Your installation: `E:\qnx800\` (as you mentioned)

---

## Step 1: Set Up QNX Environment

### Open PowerShell or Command Prompt

1. **Open PowerShell as Administrator** (or regular if admin not needed)

2. **Navigate to QNX installation:**
   ```powershell
   cd E:\qnx800
   ```

3. **Set up QNX environment:**
   ```powershell
   .\qnxsdp-env.bat
   ```
   This sets up all QNX tools in your PATH.

4. **Verify QNX tools are available:**
   ```powershell
   qnx-ifsload --version
   arm-unknown-nto-qnx8.0.0-objdump --version
   ```
   **Note**: The tool name might be `arm-unknown-nto-qnx7.1.0-objdump` or `arm-unknown-nto-qnx8.0.0-objdump` depending on your QNX version. Check what's available:
   ```powershell
   dir E:\qnx800\host\win64\x86_64\usr\bin\arm-unknown-nto-*
   ```

---

## Step 2: Navigate to Project Directory

```powershell
cd C:\Users\YourName\Documents\iDrive-6-local-run
```

(Replace `YourName` with your Windows username)

---

## Step 3: Extract IFS Image (Optional - to see contents)

The IFS (Image File System) is a QNX format. You can extract it to see what's inside:

```powershell
# Make sure QNX environment is set
cd E:\qnx800
.\qnxsdp-env.bat

# Go back to project
cd C:\Users\YourName\Documents\iDrive-6-local-run

# Extract the patched kernel
qnx-ifsload -v nbtevo-system-dump\sda2\boot1.ifs.patched
```

This will extract files to a directory. **Note**: This is optional - you mainly need to disassemble the binary.

---

## Step 4: Disassemble the Kernel

This is the **most important step** - you need to see the assembly code to find hardware checks.

### Method A: Using Command Line (Recommended)

```powershell
# Set QNX environment first
cd E:\qnx800
.\qnxsdp-env.bat

# Go to project
cd C:\Users\YourName\Documents\iDrive-6-local-run

# Disassemble the patched kernel
# Replace qnx8.0.0 with your version (qnx7.1.0 or qnx8.0.0)
arm-unknown-nto-qnx8.0.0-objdump -d nbtevo-system-dump\sda2\boot1.ifs.patched > kernel-disassembly.txt

# This creates a text file with all assembly code
```

### Method B: Using QNX Momentics IDE

1. **Open QNX Momentics IDE**

2. **File → Import → Existing Projects into Workspace**
   - Browse to: `C:\Users\YourName\Documents\iDrive-6-local-run`
   - Select the project
   - Click Finish

3. **Open Binary in IDE:**
   - Right-click `nbtevo-system-dump\sda2\boot1.ifs.patched`
   - Open With → Binary Editor or Disassembler
   - QNX IDE will show the disassembly

---

## Step 5: Find Hardware Wait Loops

### What to Look For

The system is stuck at PC address `0x8749a5ac` (from diagnostics). You need to find:

1. **Wait/Poll Loops:**
   ```
   Pattern:
   loop_start:
     LDR  r0, [address]      ; Load register value
     CMP  r0, #expected       ; Compare with expected
     BNE  loop_start          ; Branch back if not equal (WAIT LOOP!)
   ```

2. **Hardware Register Reads:**
   ```
   Pattern:
     MRC  p15, 0, r0, c0, c0, 0  ; Read CPU ID
     CMP  r0, #expected
     BNE  error_handler          ; Branch to error if wrong
   ```

3. **Device Register Checks:**
   ```
   Pattern:
     LDR  r0, =0x48000000     ; Load device register address
     LDR  r1, [r0]            ; Read register
     CMP  r1, #0              ; Check if zero
     BEQ  wait_loop            ; Wait if zero
   ```

### Search in Disassembly

Open `kernel-disassembly.txt` in a text editor (Notepad++, VS Code, etc.) and search for:

1. **Search for address `0x8749a5ac`:**
   ```
   Find: 8749a5ac
   ```
   This is where the system is currently stuck!

2. **Search for wait loop patterns:**
   ```
   Find: BNE.*-0x
   ```
   This finds backward branches (loops)

3. **Search for hardware strings:**
   ```
   Find: sysregs
   Find: FPGA
   Find: GPIO
   Find: omap5430
   ```

4. **Look around the stuck address:**
   - Go to address `0x8749a5ac` in the disassembly
   - Look at the code before and after
   - Find the loop that's causing the wait

---

## Step 6: Identify Patches Needed

### Example: Finding a Wait Loop

When you find code like this:
```assembly
8749a5a0:  e59f0010    ldr  r0, [pc, #16]   ; Load address
8749a5a4:  e5901000    ldr  r1, [r0]        ; Read register
8749a5a8:  e3510000    cmp  r1, #0          ; Compare with 0
8749a5ac:  1afffffb    bne  8749a5a0        ; Branch back if not equal (WAIT LOOP!)
```

**This is a wait loop!** The `BNE` (Branch if Not Equal) at `8749a5ac` branches back to `8749a5a0`, creating an infinite loop.

### What to Patch

1. **Change BNE to BEQ** (invert condition - makes it skip the wait):
   - `BNE` = `1A` (hex)
   - `BEQ` = `0A` (hex)
   - Change byte at offset to make it always skip the loop

2. **Or NOP the branch** (make it always continue):
   - `NOP` = `00 00 A0 E1` (ARM NOP instruction)
   - Replace the branch instruction with NOP

---

## Step 7: Patch the Binary

### Method A: Using Hex Editor (Manual)

1. **Open `boot1.ifs.patched` in a hex editor:**
   - HxD (free): https://mh-nexus.de/en/hxd/
   - Or any hex editor

2. **Find the instruction to patch:**
   - The address in disassembly is **relative to the start of the binary**
   - If disassembly shows `8749a5ac`, you need to find where this maps in the file
   - Look for the instruction bytes: `1A FF FB` (BNE instruction)

3. **Patch the instruction:**
   - Find: `1A` (BNE opcode)
   - Change to: `0A` (BEQ opcode)
   - Or change to: `00 00 A0 E1` (NOP)

4. **Save the file**

### Method B: Using Python Script (Automated)

The repository has `patch-kernel-aggressive.py` that does this automatically. You can run it on Windows:

```powershell
# Make sure Python 3 is installed
python --version

# Run the aggressive patching script
python patch-kernel-aggressive.py
```

This will:
- Find wait loops
- Find device register checks
- Patch BNE → BEQ automatically
- Save to `boot1.ifs.patched` (backup first!)

**⚠️ WARNING**: Make a backup first!
```powershell
copy nbtevo-system-dump\sda2\boot1.ifs.patched nbtevo-system-dump\sda2\boot1.ifs.patched.backup2
```

### Method C: Using QNX Tools (Advanced)

If you extract the IFS and modify individual files, you'd need to rebuild:

```powershell
# After modifying files
qnx-ifs -v -o boot1.ifs.fully-patched [list of files]
```

But this is complex - **Method A or B is easier**.

---

## Step 8: Test the Patched Kernel

### Run with QEMU

1. **Install QEMU for Windows** (if not already):
   - Download: https://www.qemu.org/download/#windows
   - Or: `choco install qemu` (if you have Chocolatey)

2. **Run the patched kernel:**
   ```powershell
   cd C:\Users\YourName\Documents\iDrive-6-local-run
   
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

3. **Watch for output:**
   - You should see QNX boot messages
   - If still stuck, you need more patches

---

## Step 9: Finding More Patches

If the system is still stuck after patching:

1. **Check QEMU monitor** (if you add `-monitor telnet:localhost:4445,server,nowait`):
   ```powershell
   telnet localhost 4445
   (qemu) info registers
   ```
   Get the new PC address where it's stuck

2. **Disassemble again** and find that address

3. **Patch that location** too

4. **Repeat** until system boots

---

## Quick Reference: ARM Instruction Encoding

| Instruction | Hex Opcode | What It Does |
|------------|------------|--------------|
| `BNE` (Branch if Not Equal) | `1A` | Branches if condition not met |
| `BEQ` (Branch if Equal) | `0A` | Branches if condition met |
| `NOP` (No Operation) | `00 00 A0 E1` | Does nothing, continues |
| `CMP` (Compare) | `E3 5x xx xx` | Compares two values |
| `LDR` (Load Register) | `E5 9x xx xx` | Loads from memory |

### Common Patterns to Patch

1. **Wait Loop:**
   ```
   Find:  CMP + BNE (backward branch)
   Patch: Change BNE to BEQ (or NOP)
   ```

2. **Error Check:**
   ```
   Find:  CMP + BNE (forward branch to error)
   Patch: Change BNE to BEQ (skip error)
   ```

3. **Device Check:**
   ```
   Find:  LDR [register] + CMP + BNE
   Patch: Change BNE to BEQ (skip check)
   ```

---

## Troubleshooting

### QNX Tools Not Found

```powershell
# Add to PATH manually
$env:PATH += ";E:\qnx800\host\win64\x86_64\usr\bin"
```

### Can't Find Address in Hex Editor

The disassembly address might be a **virtual address**, not file offset. Try:
1. Search for the instruction bytes instead
2. Use a disassembler that shows file offsets
3. Or use QNX IDE's binary editor (shows both)

### Kernel Still Stuck

1. Check if you patched the right location
2. Try patching multiple locations (there might be several wait loops)
3. Use `patch-kernel-aggressive.py` to patch many at once
4. Check QEMU monitor for new stuck address

### File Corrupted After Patching

Restore from backup:
```powershell
copy nbtevo-system-dump\sda2\boot1.ifs.backup nbtevo-system-dump\sda2\boot1.ifs.patched
```

---

## Summary Checklist

- [ ] Set up QNX environment (`.\qnxsdp-env.bat`)
- [ ] Navigate to project directory
- [ ] Disassemble kernel (`arm-unknown-nto-qnx8.0.0-objdump -d`)
- [ ] Find stuck address (`0x8749a5ac` or new one from QEMU monitor)
- [ ] Identify wait loops in disassembly
- [ ] Make backup of patched kernel
- [ ] Patch BNE → BEQ (or NOP) using hex editor or Python script
- [ ] Test with QEMU
- [ ] Repeat if still stuck

---

## Files You'll Create

- `kernel-disassembly.txt` - Full disassembly (large file, ~10-50 MB)
- `boot1.ifs.patched.backup2` - Backup before aggressive patching
- `boot1.ifs.fully-patched` - Final patched kernel (if you rebuild IFS)

---

## Need Help?

1. Check `DIAGNOSTIC_REPORT.md` for current status
2. Check `WINDOWS_QNX_SETUP.md` for setup details
3. Use QEMU monitor to get exact stuck address
4. Search disassembly for that address

**Good luck!** 🚀

