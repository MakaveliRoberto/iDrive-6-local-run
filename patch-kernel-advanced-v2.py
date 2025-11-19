#!/usr/bin/env python3

"""
Advanced patching - find code that references hardware strings
and patch the checks that use them
"""

import sys

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def find_string_references(data, target_string):
    """Find code that might reference a string"""
    string_bytes = target_string.encode('utf-8')
    string_offset = data.find(string_bytes)
    
    if string_offset == -1:
        return []
    
    # Look for LDR instructions that load the string address
    # LDR R0, [PC, #offset] where offset points to string
    references = []
    
    # Search in a range around the string
    search_start = max(0, string_offset - 5000)
    search_end = min(len(data), string_offset + 1000)
    
    for i in range(search_start, search_end, 4):
        if i + 4 > len(data):
            break
        
        inst = data[i:i+4]
        if len(inst) != 4:
            continue
        
        # LDR instruction pattern: 0xE59xxxxx
        # Check if it might load an address near our string
        if (inst[3] & 0xFF) == 0xE5 and (inst[2] & 0xF0) == 0x90:
            # Calculate potential target
            # This is simplified - actual LDR decoding is complex
            references.append(i)
            if len(references) >= 10:
                break
    
    return references

def patch_timeout_checks(data):
    """Find and patch timeout/wait checks"""
    print("Finding timeout/wait checks...")
    
    # Look for patterns that might be timeout loops
    # SUB (decrement counter) + CMP + BNE (loop)
    
    patches = []
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        inst3 = data[i+8:i+12]
        
        if len(inst1) != 4 or len(inst2) != 4 or len(inst3) != 4:
            continue
        
        # SUB instruction = 0xE24xxxxx
        # CMP instruction = 0xE35xxxxx
        # BNE = 0x1A
        if (inst1[3] & 0xFF) == 0xE2 and (inst1[2] & 0xF0) == 0x40:  # SUB
            if (inst2[3] & 0xF0) == 0xE0 and (inst2[2] & 0xF0) == 0x50:  # CMP
                if inst3[3] == 0x1A:  # BNE (loop back)
                    # Check if it loops backwards (timeout loop)
                    offset = ((inst3[2] & 0x7F) << 16) | (inst3[1] << 8) | inst3[0]
                    if offset & 0x400000:
                        offset |= 0xFF800000
                    offset <<= 2
                    target = i + 12 + offset
                    if target < i:  # Loops backwards
                        patches.append(i+8)  # Patch BNE to break loop
                        if len(patches) >= 5:
                            break
    
    return patches

def main():
    print("=" * 60)
    print("🔧 Advanced Hardware Check Patching v2")
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
    
    # Load previous patches or start fresh
    # For now, start from original
    print("Applying advanced patches...")
    print("")
    
    # 1. Patch timeout loops
    timeout_patches = patch_timeout_checks(data)
    print(f"Found {len(timeout_patches)} timeout loops")
    
    # Apply timeout patches
    applied = 0
    for offset in timeout_patches:
        if offset + 4 > len(data):
            continue
        inst = data[offset:offset+4]
        if inst[3] == 0x1A:  # BNE
            # Change to BEQ to break the loop
            new_inst = bytes([inst[0], inst[1], inst[2], 0x0A])
            data = data[:offset] + new_inst + data[offset+4:]
            applied += 1
            print(f"  Patched timeout loop at 0x{offset:x}")
    
    # 2. Find all CMP+BNE patterns (comprehensive)
    print("")
    print("Finding all CMP+BNE patterns...")
    cmp_bne_count = 0
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        if (inst1[3] & 0xF0) == 0xE0 and (inst1[2] & 0xF0) == 0x50:  # CMP
            if inst2[3] == 0x1A:  # BNE
                # Patch it
                new_inst = bytes([inst2[0], inst2[1], inst2[2], 0x0A])  # BEQ
                data = data[:i+4] + new_inst + data[i+8:]
                cmp_bne_count += 1
                if cmp_bne_count >= 20:  # Limit to avoid breaking everything
                    break
    
    print(f"  Patched {cmp_bne_count} CMP+BNE patterns")
    applied += cmp_bne_count
    
    print("")
    if applied > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Total patches: {applied}")
    else:
        print("⚠️  No patches applied")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

