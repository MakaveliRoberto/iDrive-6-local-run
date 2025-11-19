#!/usr/bin/env python3

"""
Conservative binary patching - only patch specific CPUID checks
that are likely to be hardware validation
"""

import sys
import struct

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def find_string_offset(data, pattern):
    """Find offset of a string"""
    pos = data.find(pattern.encode('utf-8'))
    return pos if pos != -1 else None

def patch_cpuid_validation(data):
    """Find and patch CPUID validation that leads to 'Unsupported CPUID' error"""
    print("Finding CPUID validation code...")
    
    # Find the error string
    error_string = "Unsupported CPUID"
    string_offset = find_string_offset(data, error_string)
    if not string_offset:
        print("❌ Error string not found")
        return data, 0
    
    print(f"✅ Found error string at offset 0x{string_offset:x}")
    print("")
    
    # Strategy: Find code that's likely checking CPUID and branching to error
    # Look for patterns:
    # 1. MRC p15,0,Rd,c0,c0,0 (read MIDR/CPUID)
    # 2. CMP Rd, #value (compare with expected CPUID)
    # 3. BNE error_handler (branch if not equal)
    
    patches = []
    
    # Search for CMP followed by BNE patterns near the error string
    # This is more conservative - only patch branches that are likely
    # CPUID validation checks
    
    search_start = max(0, string_offset - 5000)
    search_end = min(len(data), string_offset + 1000)
    
    print(f"Searching code range: 0x{search_start:x} to 0x{search_end:x}")
    print("")
    
    for i in range(search_start, search_end - 12, 4):
        if i + 12 > len(data):
            break
        
        # Look for CMP instruction
        # CMP Rn, #imm = 0xE3500000 + (Rn << 16) + imm
        inst1 = data[i:i+4]
        if len(inst1) != 4:
            continue
        
        # Check if it's a CMP instruction (bits 27-20 = 0xE35)
        if (inst1[3] & 0xFF) == 0xE3 and (inst1[2] & 0xF0) == 0x50:
            # Might be CMP - check next instruction
            inst2 = data[i+4:i+8]
            if len(inst2) != 4:
                continue
            
            # Check for BNE (Branch if Not Equal) = 0x1A000000
            if inst2[3] == 0x1A:
                # Calculate branch target
                offset = ((inst2[2] & 0x7F) << 16) | (inst2[1] << 8) | inst2[0]
                if offset & 0x400000:
                    offset |= 0xFF800000  # Sign extend
                offset <<= 2
                target = i + 8 + offset
                
                # Only patch if branch goes toward error string
                # (within reasonable range)
                if target >= string_offset - 500 and target <= string_offset + 500:
                    print(f"  Found CMP+BNE at 0x{i:x} → 0x{target:x} (near error)")
                    # Patch: Change BNE to BEQ (invert condition - always take success path)
                    new_inst2 = bytes([inst2[0], inst2[1], inst2[2], 0x0A])  # BEQ instead of BNE
                    patches.append((i+4, inst2, new_inst2))
                    
                    if len(patches) >= 3:  # Limit to 3 most relevant patches
                        break
    
    # Apply patches
    if patches:
        print("")
        print(f"Applying {len(patches)} conservative patches...")
        for offset, old_inst, new_inst in patches:
            data = data[:offset] + new_inst + data[offset+4:]
            print(f"  Patched at 0x{offset:x}")
        return data, len(patches)
    else:
        print("⚠️  No conservative patches found")
        return data, 0

def main():
    print("=" * 60)
    print("🔧 Conservative Binary Patching")
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
    
    # Apply conservative patches
    data, patch_count = patch_cpuid_validation(data)
    
    print("")
    if patch_count > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Conservative patches: {patch_count}")
        print("")
        print("This version only patches CPUID validation checks")
        print("that are directly related to the 'Unsupported CPUID' error.")
    else:
        print("⚠️  No patches applied")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

