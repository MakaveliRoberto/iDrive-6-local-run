# BMW iDrive 6 Local Run

Run BMW iDrive 6 (NBT EVO ID6) system locally using QEMU emulation.

## 🚀 Quick Start

### Prerequisites

- **QEMU** (ARM emulation)
  ```bash
  # macOS
  brew install qemu
  
  # Linux
  sudo apt-get install qemu-system-arm
  ```

- **QNX Momentics IDE** (for full kernel patching)
  - Download from: https://www.qnx.com/developers/
  - License included in repository

### Basic Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
   cd iDrive-6-local-run
   ```

2. **Run the web interface** (static files)
   ```bash
   ./run-idrive-local.sh
   ```
   Access at: http://localhost:8080

3. **Run full QNX emulation** (requires patched kernel)
   ```bash
   ./run-patched-kernel.sh
   ```
   Access at: http://localhost:8103

## 📁 Project Structure

```
.
├── nbtevo-system-dump/          # Full iDrive 6 system dump
│   ├── sda0/                    # Main application partition
│   ├── sda2/                    # Boot partition
│   │   ├── boot1.ifs            # Original QNX kernel
│   │   ├── boot1.ifs.backup     # Backup of original
│   │   └── boot1.ifs.patched    # Patched kernel (CPUID checks bypassed)
│   └── ...
├── emulation/                    # QEMU emulation files
├── patch-kernel-*.py            # Kernel patching scripts
├── run-*.sh                     # Run scripts
└── README.md                    # This file
```

## 🔧 Kernel Patching

The kernel has been patched to bypass CPUID hardware checks. See `PATCHING_STATUS.md` for details.

### Current Status

✅ **Patched**: 10 CPUID validation checks  
❌ **Still blocking**: FPGA, GPIO, device register checks

### Using QNX IDE

For full kernel patching, use QNX Momentics IDE. See `QNX_IDE_SETUP.md` for detailed instructions.

## 🎯 Features

- ✅ Full iDrive 6 system dump
- ✅ QNX kernel emulation
- ✅ Hardware check bypasses
- ✅ Web interface serving
- ✅ QEMU ARM emulation
- ✅ Filesystem access via virtio-9p

## 📖 Documentation

- `README.md` - This file
- `PATCHING_STATUS.md` - Kernel patching status
- `QNX_IDE_SETUP.md` - QNX IDE setup guide
- `EMULATION_GUIDE.md` - Detailed emulation guide
- `UNDERSTANDING_IDRIVE.md` - System architecture

## 🐛 Known Issues

- Kernel gets stuck waiting for hardware (FPGA, GPIO)
- Requires QNX IDE for full hardware check bypass
- Some QNX-specific features require hardware emulation

## 📝 License

This project is for educational and research purposes only.

## 🙏 Credits

- System dump: https://git.davidpetric.com/thepetric/nbtevo-system-dump.git
- QNX Neutrino RTOS by BlackBerry QNX

## 🔗 Links

- GitHub: https://github.com/MakaveliRoberto/iDrive-6-local-run
- QNX: https://www.qnx.com/
