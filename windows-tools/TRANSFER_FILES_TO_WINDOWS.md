# Transfer Files from Mac to Windows

**The files on your Mac are actual binaries (not pointer files). You can transfer them to Windows!**

## Option 1: Copy Files Directly (Easiest)

### Using USB Drive or Network Share

1. **On Mac: Copy files to USB drive or shared folder:**
   ```bash
   # Copy kernel files
   cp nbtevo-system-dump/sda2/boot1.ifs.patched /Volumes/USB_DRIVE/
   cp nbtevo-system-dump/sda2/boot1.ifs.backup /Volumes/USB_DRIVE/
   cp nbtevo-system-dump/sda2/boot1.ifs /Volumes/USB_DRIVE/
   
   # Copy patching script
   cp patch-kernel-aggressive.py /Volumes/USB_DRIVE/
   ```

2. **On Windows: Copy to repository:**
   ```powershell
   # Navigate to repository
   cd C:\Users\YourName\Documents\iDrive-6-local-run
   
   # Copy files from USB
   copy E:\boot1.ifs.patched nbtevo-system-dump\sda2\
   copy E:\boot1.ifs.backup nbtevo-system-dump\sda2\
   copy E:\boot1.ifs nbtevo-system-dump\sda2\
   copy E:\patch-kernel-aggressive.py .
   ```

### Using Cloud Storage (Google Drive, Dropbox, etc.)

1. **Upload from Mac:**
   - Upload `nbtevo-system-dump/sda2/boot1.ifs.patched` (1.5 MB)
   - Upload `nbtevo-system-dump/sda2/boot1.ifs.backup` (1.5 MB)
   - Upload `patch-kernel-aggressive.py`

2. **Download on Windows:**
   - Download files to repository directory
   - Place in correct locations

## Option 2: Use Git (If Repository is Synced)

If you push the files to GitHub from Mac, you can pull them on Windows:

### On Mac:
```bash
# Make sure files are committed
git add nbtevo-system-dump/sda2/boot1.ifs*
git commit -m "Add patched kernel files"
git push
```

### On Windows:
```powershell
# Pull from repository
cd C:\Users\YourName\Documents\iDrive-6-local-run
git pull
git lfs pull  # Still need this for other LFS files
```

## Option 3: Create Archive and Transfer

### On Mac:
```bash
# Create archive with kernel files
cd /Users/robertoamateesei/Desktop/iDrive6
tar -czf idrive-kernels.tar.gz \
  nbtevo-system-dump/sda2/boot1.ifs* \
  patch-kernel-aggressive.py \
  MANUAL_KERNEL_PATCHING_WINDOWS.md \
  QUICK_PATCH_REFERENCE.md \
  GIT_LFS_SETUP_WINDOWS.md

# Copy to USB or upload
cp idrive-kernels.tar.gz /Volumes/USB_DRIVE/
```

### On Windows:
```powershell
# Extract archive (use 7-Zip or WinRAR)
# Extract to: C:\Users\YourName\Documents\iDrive-6-local-run
```

## Files You Need to Transfer

### Essential Files:
1. **`boot1.ifs.patched`** (1,610,796 bytes) - Current patched kernel
2. **`boot1.ifs.backup`** (1,610,796 bytes) - Original backup
3. **`boot1.ifs`** (1,610,796 bytes) - Original kernel

### Helpful Files:
4. **`patch-kernel-aggressive.py`** - Python patching script
5. **`MANUAL_KERNEL_PATCHING_WINDOWS.md`** - Full guide
6. **`QUICK_PATCH_REFERENCE.md`** - Quick reference
7. **`GIT_LFS_SETUP_WINDOWS.md`** - Git LFS guide

## Verify Files After Transfer

On Windows, verify files are correct:

```powershell
# Check file sizes
dir nbtevo-system-dump\sda2\boot1.ifs*

# Should show:
# boot1.ifs.patched    1,610,796 bytes  ✅
# boot1.ifs.backup     1,610,796 bytes  ✅
# boot1.ifs            1,610,796 bytes  ✅

# If files are smaller (~100 bytes), they're pointer files ❌
```

## Quick Transfer Script (Mac)

Create a script to copy files to USB:

```bash
#!/bin/bash
# save as: transfer-to-windows.sh

USB_PATH="/Volumes/USB_DRIVE"
REPO_PATH="/Users/robertoamateesei/Desktop/iDrive6"

if [ ! -d "$USB_PATH" ]; then
    echo "❌ USB drive not found at $USB_PATH"
    echo "   Insert USB drive or update USB_PATH"
    exit 1
fi

echo "📦 Copying files to USB drive..."
cp "$REPO_PATH/nbtevo-system-dump/sda2/boot1.ifs.patched" "$USB_PATH/"
cp "$REPO_PATH/nbtevo-system-dump/sda2/boot1.ifs.backup" "$USB_PATH/"
cp "$REPO_PATH/nbtevo-system-dump/sda2/boot1.ifs" "$USB_PATH/"
cp "$REPO_PATH/patch-kernel-aggressive.py" "$USB_PATH/"
cp "$REPO_PATH/MANUAL_KERNEL_PATCHING_WINDOWS.md" "$USB_PATH/"
cp "$REPO_PATH/QUICK_PATCH_REFERENCE.md" "$USB_PATH/"
cp "$REPO_PATH/GIT_LFS_SETUP_WINDOWS.md" "$USB_PATH/"

echo "✅ Files copied to $USB_PATH"
echo ""
echo "On Windows, copy files to:"
echo "  C:\\Users\\YourName\\Documents\\iDrive-6-local-run\\"
```

Run with:
```bash
chmod +x transfer-to-windows.sh
./transfer-to-windows.sh
```

## After Transfer

Once files are on Windows:

1. ✅ Verify file sizes (should be ~1.5 MB each)
2. ✅ Follow `MANUAL_KERNEL_PATCHING_WINDOWS.md` for patching
3. ✅ Use QNX tools to disassemble and patch

**You're ready to patch!** 🚀

