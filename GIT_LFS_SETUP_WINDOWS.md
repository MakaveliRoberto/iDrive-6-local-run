# Git LFS Setup for Windows - Critical Step!

**The kernel files are stored in Git LFS. You MUST download them before patching!**

## What is Git LFS?

Git LFS (Large File Storage) stores large binary files separately from the main repository. The files you see in the repository are just **pointer files** (small text files) that reference the actual binaries.

## How to Identify LFS Pointer Files

If you open a file and see this:
```
version https://git-lfs.github.com/spec/v1
oid sha256:c34ea8de30b6b1bb41e30d6ef062180c1c79eb84f572110ae7b6378002841db1
size 1610796
```

**This is a pointer file!** The actual binary is stored in Git LFS and needs to be downloaded.

## Step-by-Step: Download Actual Files

### 1. Install Git LFS (if not already installed)

**Option A: During Git Installation**
- When installing Git for Windows, make sure to check "Git LFS" option
- Download: https://git-scm.com/download/win

**Option B: Install Separately**
```powershell
# Download Git LFS installer
# https://github.com/git-lfs/git-lfs/releases
# Or use Chocolatey:
choco install git-lfs
```

### 2. Initialize Git LFS

```powershell
# Open PowerShell in repository directory
cd C:\Users\YourName\Documents\iDrive-6-local-run

# Initialize Git LFS
git lfs install
```

You should see:
```
Git LFS initialized.
```

### 3. Download All LFS Files

```powershell
# Pull all LFS files
git lfs pull
```

This will download all large files from Git LFS. **This may take a while** (the repository is ~15 GB).

### 4. Verify Files Are Downloaded

```powershell
# Check file sizes
dir nbtevo-system-dump\sda2\boot1.ifs*

# Should show:
# boot1.ifs.patched    1,610,796 bytes  (~1.5 MB) ✅
# boot1.ifs.backup     1,610,796 bytes  (~1.5 MB) ✅
# boot1.ifs            1,610,796 bytes  (~1.5 MB) ✅

# If files are only ~100 bytes, they're still pointer files! ❌
```

### 5. Check Disk Image

```powershell
# Check disk image size
dir emulation\idrive-disk.img

# Should be ~4 GB ✅
# If only ~100 bytes, run git lfs pull again! ❌
```

## Troubleshooting

### Files Still Small After `git lfs pull`

**Problem**: Files are still pointer files (small text files)

**Solution 1: Force Fetch**
```powershell
git lfs fetch --all
git lfs checkout
```

**Solution 2: Re-clone with LFS**
```powershell
# Delete repository
cd ..
rmdir /s iDrive-6-local-run

# Re-clone
git clone https://github.com/MakaveliRoberto/iDrive-6-local-run.git
cd iDrive-6-local-run
git lfs pull
```

**Solution 3: Check Git LFS Status**
```powershell
# Check what LFS is tracking
git lfs ls-files

# Should show files with (LFS) tag
```

### Git LFS Not Installed

**Error**: `git: 'lfs' is not a git command`

**Solution**: Install Git LFS:
- Download: https://github.com/git-lfs/git-lfs/releases
- Or: `choco install git-lfs`

### Network Issues / Slow Download

The repository is large (~15 GB). If download is slow:

1. **Check your internet connection**
2. **Use GitHub Desktop** (has better LFS support)
3. **Download in parts** (not recommended, but possible)

### Authentication Issues

If Git LFS asks for authentication:

```powershell
# Use GitHub CLI
gh auth login

# Or set up SSH keys
# Or use personal access token
```

## Files Tracked in Git LFS

These files are stored in Git LFS:
- `nbtevo-system-dump/**/*` - All system dump files (~15 GB)
- `emulation/**/*` - Emulation files (disk images, logs)
- `*.ifs` - QNX IFS kernel images
- `*.bin` - Binary files
- Large log files

## Quick Check Commands

```powershell
# Check if Git LFS is installed
git lfs version

# Check LFS status
git lfs ls-files

# Check file sizes
dir nbtevo-system-dump\sda2\boot1.ifs* /s
dir emulation\idrive-disk.img /s

# Verify a file is actual binary (not pointer)
# Open in hex editor - should see binary data, not text
```

## Expected File Sizes

| File | Expected Size | If Pointer File |
|------|---------------|-----------------|
| `boot1.ifs.patched` | 1,610,796 bytes | ~100 bytes |
| `boot1.ifs.backup` | 1,610,796 bytes | ~100 bytes |
| `boot1.ifs` | 1,610,796 bytes | ~100 bytes |
| `idrive-disk.img` | ~4 GB | ~100 bytes |
| `arm-cortexA15_bios_packet.bin` | 262,144 bytes | ~100 bytes |

## After Downloading

Once files are downloaded:
1. ✅ Files should be actual binary size
2. ✅ You can open them in hex editor
3. ✅ You can disassemble with QNX tools
4. ✅ You can patch them

**Then proceed to `MANUAL_KERNEL_PATCHING_WINDOWS.md` for patching instructions!**

