#!/usr/bin/env python3

"""
Selective patching - only patch hardware checks that are likely
to block boot, avoiding patches that might break the kernel
"""

import sys

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def main():
    print("=" * 60)
    print("🔧 Selective Hardware Check Patching v2")
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
    
    # Find "Unsupported CPUID" string
    error_string = b"Unsupported CPUID"
    string_offset = data.find(error_string)
    
    if string_offset == -1:
        print("❌ Error string not found")
        return 1
    
    print(f"✅ Found error string at 0x{string_offset:x}")
    print("")
    
    # Strategy: Only patch CMP+BNE patterns that are near the error string
    # These are most likely to be hardware validation checks
    print("Finding CMP+BNE patterns near error string...")
    
    patches = []
    search_start = max(0, string_offset - 10000)  # Search 10KB before error
    search_end = min(len(data), string_offset + 1000)  # And 1KB after
    
    for i in range(search_start, search_end - 12, 4):
        if i + 12 > len(data):
            break
        
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        
        if len(inst1) != 4 or len(inst2) != 4:
            continue
        
        # CMP instruction
        if (inst1[3] & 0xF0) == 0xE0 and (inst1[2] & 0xF0) == 0x50:
            # BNE instruction
            if inst2[3] == 0x1A:
                # Calculate branch target
                offset = ((inst2[2] & 0x7F) << 16) | (inst2[1] << 8) | inst2[0]
                if offset & 0x400000:
                    offset |= 0xFF800000
                offset <<= 2
                target = i + 8 + offset
                
                # Only patch if branch goes toward error string
                # (within reasonable range)
                if abs(target - string_offset) < 500:
                    patches.append(i+4)
                    if len(patches) >= 5:  # Limit to 5 most relevant
                        break
    
    print(f"Found {len(patches)} relevant CMP+BNE patterns")
    print("")
    
    # Also patch the original 10 CPUID checks we found before
    # These are at known offsets
    known_offsets = [0x68c, 0x6cc, 0x938, 0x978, 0xdb4, 0xdf0, 0xe48, 0xf9c, 0x10f0, 0x1248]
    
    print("Applying patches...")
    applied = 0
    
    # Patch known CPUID checks
    for offset in known_offsets:
        if offset + 4 > len(data):
            continue
        inst = data[offset:offset+4]
        if inst[3] == 0x1A:  # BNE
            new_inst = bytes([inst[0], inst[1], inst[2], 0x0A])  # BEQ
            data = data[:offset] + new_inst + data[offset+4:]
            applied += 1
            print(f"  Patched CPUID check at 0x{offset:x}")
    
    # Patch patterns near error string
    for offset in patches:
        if offset + 4 > len(data):
            continue
        inst = data[offset:offset+4]
        if inst[3] == 0x1A:  # BNE
            new_inst = bytes([inst[0], inst[1], inst[2], 0x0A])  # BEQ
            data = data[:offset] + new_inst + data[offset+4:]
            applied += 1
            print(f"  Patched hardware check at 0x{offset:x}")
    
    print("")
    if applied > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Selective patches: {applied}")
        print("")
        print("This version only patches hardware checks that are")
        print("directly related to the 'Unsupported CPUID' error,")
        print("avoiding patches that might break the kernel.")
    else:
        print("⚠️  No patches applied")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

