#!/usr/bin/env python3

"""
Selective binary patching - patch only specific CPUID checks
Based on analysis of the binary structure
"""

import sys

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def patch_selective_locations(data):
    """Patch specific locations that are likely CPUID checks"""
    print("Applying selective patches to known CPUID check locations...")
    print("")
    
    # These are the offsets found in the first patching attempt
    # We'll patch only a few to be conservative
    # Format: (offset, description)
    patch_locations = [
        (0x684, "Early CPUID check 1"),
        (0x6c4, "Early CPUID check 2"),
        (0x930, "CPUID validation 1"),
    ]
    
    patches_applied = 0
    
    for offset, desc in patch_locations:
        if offset + 4 > len(data):
            print(f"⚠️  Offset 0x{offset:x} out of range - skipping")
            continue
        
        inst = data[offset:offset+4]
        if len(inst) != 4:
            continue
        
        # Check if it's a BNE instruction (0x1A)
        if inst[3] == 0x1A:
            print(f"  Patching {desc} at 0x{offset:x}")
            # Change BNE to BEQ (invert condition)
            new_inst = bytes([inst[0], inst[1], inst[2], 0x0A])
            data = data[:offset] + new_inst + data[offset+4:]
            patches_applied += 1
        else:
            print(f"  ⚠️  Offset 0x{offset:x} doesn't contain BNE - skipping")
    
    return data, patches_applied

def main():
    print("=" * 60)
    print("🔧 Selective Binary Patching")
    print("=" * 60)
    print("")
    
    try:
        with open(BOOT_IMAGE, 'rb') as f:
            data = bytearray(f.read())
    except FileNotFoundError:
        print(f"❌ Boot image not found: {BOOT_IMAGE}")
        return 1
    
    print(f"✅ Loaded: {len(data)} bytes")
    print("")
    
    # Backup
    import shutil
    import os
    if not os.path.exists(BACKUP_IMAGE):
        shutil.copy(BOOT_IMAGE, BACKUP_IMAGE)
        print(f"✅ Backup: {BACKUP_IMAGE}")
    print("")
    
    # Apply selective patches
    data, patch_count = patch_selective_locations(data)
    
    print("")
    if patch_count > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Selective patches: {patch_count}")
        print("")
        print("This version patches only the first 3 CPUID check locations")
        print("to minimize risk of breaking the kernel.")
    else:
        print("⚠️  No patches applied")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

