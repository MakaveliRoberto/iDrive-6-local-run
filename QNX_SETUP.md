# QNX Momentics Setup Guide

## Your License Information

- **License Type**: Named User
- **License Key**: `2A71-H1RS-JJ7U-7KBL-5ST9`
- **Serial Number**: `911285-09973098`
- **Ship Date**: 18-Nov-2025

## Step 1: Download QNX Momentics IDE

1. Go to: https://www.qnx.com/developers/
2. Sign in with your QNX account
3. Download **QNX Software Development Platform (SDP)**
   - Version 7.1 or 7.2 (recommended)
   - Choose your OS: macOS, Linux, or Windows

## Step 2: Install QNX Momentics

### macOS:
```bash
# Download the .dmg file
# Mount and run the installer
# Follow the installation wizard
```

### Linux:
```bash
# Download the .run file
chmod +x qnx*.run
./qnx*.run
```

## Step 3: Activate License

After installation:

1. Open QNX Momentics IDE
2. Go to: **Help → License Management**
3. Enter your license key: `2A71-H1RS-JJ7U-7KBL-5ST9`
4. Enter serial number: `911285-09973098`
5. Activate license

## Step 4: Set Up QNX Environment

After installation, source the QNX environment:

```bash
# Find your QNX installation (usually in /opt/qnx or ~/qnx)
# Then source the environment:

# For QNX 7.1:
source /opt/qnx710/qnxsdp-env.sh

# For QNX 7.2:
source /opt/qnx720/qnxsdp-env.sh

# Or if installed in home directory:
source ~/qnx710/qnxsdp-env.sh
```

## Step 5: Verify Installation

```bash
# Check QNX tools are available
which qcc
which mkqnx6fs
which qnx-ifsload

# Check QNX version
qnxversion
```

## What This Enables

With QNX Momentics, you can now:

1. **Properly analyze IFS images**:
   ```bash
   qnx-ifsload -v nbtevo-system-dump/sda2/boot1.ifs
   ```

2. **Create QNX6 filesystems**:
   ```bash
   mkqnx6fs -b 512 -l idrive-fs nbtevo-system-dump/sda0
   ```

3. **Use QNX Simulator** (better than QEMU):
   - Built-in QNX virtual machine
   - Better hardware emulation
   - Native QNX environment

4. **Cross-compile** for ARM if needed

5. **Debug** QNX applications

## Next Steps

Once QNX Momentics is installed, run:
```bash
./setup-qnx-tools.sh
```

This will:
- Detect your QNX installation
- Set up environment variables
- Create helper scripts
- Test QNX tools with the iDrive dump

