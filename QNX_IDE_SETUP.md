# QNX Momentics IDE Setup Guide

This guide explains how to use QNX Momentics IDE to properly analyze and patch the iDrive 6 kernel.

## Prerequisites

1. **QNX Momentics IDE** (you have a license)
   - Download from: https://www.qnx.com/developers/
   - License: Named User License
   - Key: 2A71-H1RS-JJ7U-7KBL-5ST9
   - Serial: 911285-09973098

2. **Installation**
   - Install QNX Momentics IDE
   - Source the environment:
     ```bash
     source /opt/qnx710/qnxsdp-env.sh
     # (or wherever QNX is installed)
     ```

## Current Kernel Status

### Files Available

- **Original Kernel**: `nbtevo-system-dump/sda2/boot1.ifs.backup`
- **Patched Kernel**: `nbtevo-system-dump/sda2/boot1.ifs.patched`
  - 10 CPUID checks already bypassed
  - Status: Runs but stuck on hardware initialization

### What's Already Patched

✅ **CPUID Checks** (10 locations):
- 0x68c, 0x6cc, 0x938, 0x978, 0xdb4, 0xdf0, 0xe48, 0xf9c, 0x10f0, 0x1248
- Changed: BNE → BEQ (invert condition)

### What Still Needs Patching

❌ **FPGA Register Checks**
- `/dev/sysregs/FPGA_VERSION`
- FPGA initialization waits

❌ **GPIO Device Checks**
- GPIO5 and other GPIO devices
- Hardware index checks

❌ **Device Register Checks**
- OMAP-specific hardware registers
- Device initialization timeouts

## Using QNX IDE to Patch

### Step 1: Extract IFS Image

```bash
# Navigate to project directory
cd /path/to/iDrive-6-local-run

# Extract the IFS image
qnx-ifsload -v nbtevo-system-dump/sda2/boot1.ifs.patched

# Or extract original
qnx-ifsload -v nbtevo-system-dump/sda2/boot1.ifs.backup
```

### Step 2: Disassemble Kernel

```bash
# Use QNX disassembler
arm-unknown-nto-qnx7.1.0-objdump -d boot1.ifs.patched > kernel-disassembly.txt

# Or use QNX IDE's built-in disassembler
```

### Step 3: Find Hardware Checks

Search for:
- `get_omap5430_info` function
- FPGA register reads
- GPIO device checks
- `/dev/sysregs` references
- Wait/poll loops
- Error returns

### Step 4: Patch Hardware Checks

1. **Identify check locations** in disassembly
2. **Patch instructions**:
   - Change BNE → BEQ (invert condition)
   - Change error returns → success returns
   - NOP out wait loops
3. **Rebuild IFS image**

### Step 5: Rebuild IFS Image

```bash
# Use QNX tools to rebuild
qnx-ifs -v -o boot1.ifs.patched-new [patched files]
```

## Patching Scripts Available

The repository includes Python scripts for binary patching:

- `patch-kernel-final.py` - Basic CPUID patching (already applied)
- `patch-kernel-selective-v2.py` - Selective patching
- `patch-kernel-comprehensive.py` - Comprehensive (too aggressive)

**Note**: These scripts are limited without proper disassembly. QNX IDE provides better tools.

## Testing Patched Kernel

```bash
# Use the run script
./run-patched-kernel.sh

# Or manually:
qemu-system-arm \
    -M virt \
    -cpu cortex-a15,midr=0x412fc0f1 \
    -m 2048 \
    -smp 2 \
    -kernel nbtevo-system-dump/sda2/boot1.ifs.patched \
    -drive file=emulation/idrive-disk.img,if=virtio,format=raw,cache=writeback \
    -fsdev local,id=fsdev0,path=nbtevo-system-dump/sda0,security_model=none \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare \
    -netdev user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8103-:80 \
    -device virtio-net-device,netdev=net0 \
    -serial stdio \
    -display none \
    -no-reboot
```

## Expected Results

After proper patching with QNX IDE:
- ✅ Kernel bypasses all hardware checks
- ✅ Initializes without waiting for hardware
- ✅ Mounts filesystems
- ✅ Starts init process
- ✅ Launches NBTCarHU (iDrive application)
- ✅ HTTP server accessible on port 8103

## Resources

- QNX Momentics Documentation: https://www.qnx.com/developers/docs/
- QNX IFS Format: https://www.qnx.com/developers/docs/7.1/#com.qnx.doc.ifs/topic/about.html
- ARM Disassembly: ARM Architecture Reference Manual

## Troubleshooting

If kernel doesn't boot:
1. Check QEMU logs for errors
2. Verify IFS image is valid
3. Ensure patches don't break critical code paths
4. Test incrementally (patch a few checks at a time)

