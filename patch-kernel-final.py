#!/usr/bin/env python3

"""
Final binary patching - patch CMP+BNE patterns that are CPUID checks
This matches the logic from the first successful patching attempt
"""

import sys

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def main():
    print("=" * 60)
    print("🔧 Final Binary Patching - CPUID Checks")
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
    
    # Find and patch CMP+BNE patterns (CPUID checks)
    print("Finding CMP+BNE patterns (CPUID checks)...")
    patches = []
    
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        
        inst1 = data[i:i+4]
        if len(inst1) != 4:
            continue
        
        # Check for CMP instruction (0xE3500000 pattern)
        if (inst1[3] & 0xF0) == 0xE0 and (inst1[2] & 0xF0) == 0x50:
            inst2 = data[i+4:i+8]
            if len(inst2) != 4:
                continue
            
            # Check for BNE (Branch if Not Equal) = 0x1A000000
            if inst2[3] == 0x1A:
                patches.append(i+4)  # Patch the BNE instruction
                if len(patches) >= 10:  # Limit to 10 patches
                    break
    
    print(f"Found {len(patches)} CMP+BNE patterns")
    print("")
    
    if patches:
        print("Patching BNE → BEQ (invert condition)...")
        for offset in patches:
            inst = data[offset:offset+4]
            # Change BNE (0x1A) to BEQ (0x0A)
            new_inst = bytes([inst[0], inst[1], inst[2], 0x0A])
            data = data[:offset] + new_inst + data[offset+4:]
            print(f"  Patched BNE at 0x{offset:x} → BEQ")
        
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print("")
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Total patches: {len(patches)}")
        print("")
        print("⚠️  WARNING: Binary patching is experimental!")
        print("   The kernel may not boot correctly.")
        print("   Keep the backup safe.")
    else:
        print("⚠️  No CMP+BNE patterns found")
        print("   Hardware checks may use different patterns")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

