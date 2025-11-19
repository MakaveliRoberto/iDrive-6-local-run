# iDrive 6 QNX Emulation Guide

## Overview

This guide explains how to emulate the full BMW iDrive 6 QNX system. The system runs on:
- **Hardware**: OMAP5430 (ARM Cortex-A15 dual-core)
- **OS**: QNX Neutrino RTOS 6.x
- **RAM**: 2GB
- **Storage**: NAND Flash (multiple partitions)

## Quick Start

```bash
./emulate-idrive.sh
```

This will:
1. Install QEMU if needed
2. Create disk image
3. Attempt to boot the QNX system

## Prerequisites

### Required

1. **QEMU** (ARM emulation)
   ```bash
   # macOS
   brew install qemu
   
   # Linux
   sudo apt-get install qemu-system-arm qemu-utils
   ```

### Optional (For Full Functionality)

2. **QNX Momentics IDE**
   - Download from: https://www.qnx.com/developers/
   - Required for proper QNX6 filesystem creation
   - Provides QNX tools (mkqnx6fs, etc.)

## System Architecture

### Hardware Emulation

The iDrive system uses **OMAP5430**, which includes:
- ARM Cortex-A15 CPU (dual-core)
- PowerVR SGX544 GPU
- Multiple GPIO, I2C, SPI interfaces
- USB controllers
- Display controllers

**QEMU Limitation**: Standard QEMU doesn't fully emulate OMAP5430. We use `vexpress-a15` as a substitute (same CPU, different peripherals).

### Boot Process

1. **Bootloader** loads `boot1.ifs` or `boot2.ifs`
2. **QNX Kernel** initializes
3. **init** process starts
4. **Filesystem** mounts from `/fs/sda0` (root filesystem)
5. **Services** start (NBTCarHU, etc.)

### Filesystem Layout

```
/fs/sda0  - Main application partition (QNX6)
/fs/sda1  - Persistent data (QNX6)
/fs/sda2  - Boot partition (FAT16)
/fs/sda31 - BOLO1 partition (backup)
/fs/sda32 - BOLO2 partition (backup)
/boot     - Early boot components
```

## Emulation Options

### Option 1: Basic Boot (Current)

Uses QEMU to boot the IFS image directly:

```bash
./emulate-idrive.sh
```

**Pros**: Quick, no QNX tools needed  
**Cons**: No filesystem, limited functionality

### Option 2: Full Emulation (Requires QNX Tools)

1. **Create QNX6 Disk**:
   ```bash
   ./create-qnx-disk.sh
   ```

2. **Copy Filesystem** (requires QNX mount):
   ```bash
   # On Linux with QNX tools:
   mkqnx6fs -q idrive-qnx6.img 2097152
   mount -t qnx6 idrive-qnx6.img /mnt/qnx
   cp -r nbtevo-system-dump/sda0/* /mnt/qnx/
   umount /mnt/qnx
   ```

3. **Boot with Disk**:
   ```bash
   qemu-system-arm -M vexpress-a15 -cpu cortex-a15 -m 2048 \
     -kernel boot1.ifs \
     -drive file=idrive-qnx6.img,if=sd,format=raw \
     -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
     -serial stdio -nographic
   ```

### Option 3: Docker-based (Advanced)

Create a Docker container with QEMU and QNX:

```dockerfile
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y qemu-system-arm
# Add QNX runtime (if licensed)
COPY nbtevo-system-dump /opt/idrive
```

**Note**: QNX licensing typically doesn't allow redistribution.

## Known Issues

### 1. Hardware Emulation

- **OMAP5430 not fully emulated** - QEMU doesn't have complete OMAP5 support
- **GPU emulation** - PowerVR SGX not emulated
- **Device drivers** - Many hardware-specific drivers won't work

### 2. Boot Issues

- **IFS format** - QNX IFS images may not boot directly in QEMU without proper setup
- **Device tree** - May need custom device tree for vexpress-a15
- **Memory layout** - Bootloader expects specific memory layout

### 3. Runtime Issues

- **Missing drivers** - Hardware-specific drivers won't find hardware
- **Services** - Many services expect real hardware
- **Graphics** - Display won't work without GPU emulation

## Debugging

### Enable QEMU Monitor

The script includes `-monitor stdio` for QEMU commands:

```
(qemu) info registers
(qemu) info mem
(qemu) quit
```

### Serial Output

All output goes to serial console. Check for:
- Boot messages
- Kernel initialization
- Service startup
- Error messages

### Common Errors

1. **"Could not load kernel"**
   - IFS format issue
   - Try different QEMU version
   - Check boot image validity

2. **"No filesystem found"**
   - Need to mount disk image
   - Check partition table
   - Verify QNX6 filesystem

3. **"Device not found"**
   - Hardware not emulated
   - Driver issue
   - Expected on first boot

## Alternative: Extract and Convert

Since full emulation is challenging, consider:

1. **Extract Assets**:
   ```bash
   ./extract-assets.sh
   ```

2. **Build Web Viewer**:
   - Use extracted images
   - Recreate interface layout
   - Simulate functionality

3. **Study Architecture**:
   - Reverse engineer .pba format
   - Understand application structure
   - Document findings

## Resources

- **QNX Documentation**: https://www.qnx.com/developers/docs/
- **QEMU ARM Emulation**: https://www.qemu.org/docs/master/system/target-arm.html
- **OMAP5430 Datasheet**: TI documentation (if available)
- **QNX Momentics**: https://www.qnx.com/developers/

## Next Steps

1. Try basic boot: `./emulate-idrive.sh`
2. If it boots, try to access via serial console
3. If services start, try network access (port 8022 SSH, 8080 HTTP)
4. For full emulation, install QNX Momentics and create proper disk

## Conclusion

Full emulation is **challenging** due to:
- Hardware emulation limitations
- QNX licensing requirements  
- Proprietary formats
- Hardware dependencies

**Realistic approach**: Use for reverse engineering and research, not full functional emulation.

