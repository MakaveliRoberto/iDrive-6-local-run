#!/usr/bin/env python3

"""
Aggressive kernel patching - patch ALL hardware checks to make emulation work
This patches wait loops, device checks, and hardware initialization
"""

import sys

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def patch_wait_loops(data):
    """Find and break wait/poll loops"""
    print("Finding wait/poll loops...")
    patches = []
    
    # Look for patterns that create wait loops
    # Pattern 1: SUB (decrement) + CMP + BNE (loop back)
    # Pattern 2: LDR (load) + CMP + BNE (poll loop)
    
    for i in range(0, len(data) - 16, 4):
        if i + 16 > len(data):
            break
        
        # Pattern: SUB + CMP + BNE (timeout loop)
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        inst3 = data[i+8:i+12]
        
        if len(inst1) != 4 or len(inst2) != 4 or len(inst3) != 4:
            continue
        
        # SUB instruction = 0xE24xxxxx
        if (inst1[3] & 0xFF) == 0xE2 and (inst1[2] & 0xF0) == 0x40:
            # CMP instruction = 0xE35xxxxx
            if (inst2[3] & 0xF0) == 0xE0 and (inst2[2] & 0xF0) == 0x50:
                # BNE (loop back)
                if inst3[3] == 0x1A:
                    # Check if loops backwards
                    offset = ((inst3[2] & 0x7F) << 16) | (inst3[1] << 8) | inst3[0]
                    if offset & 0x400000:
                        offset |= 0xFF800000
                    offset <<= 2
                    target = i + 12 + offset
                    if target < i:  # Loops backwards
                        patches.append(i+8)  # Patch BNE
                        if len(patches) >= 10:
                            break
    
    return patches

def patch_device_register_reads(data):
    """Patch device register reads that might fail"""
    print("Finding device register reads...")
    patches = []
    
    # Look for MRC (read coprocessor) instructions that might read hardware
    # MRC p15,0,Rd,c0,c0,0 = Read MIDR
    # MRC p15,0,Rd,c1,c0,0 = Read SCTLR
    # These might be followed by checks
    
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        
        if len(inst1) != 4 or len(inst2) != 4:
            continue
        
        # MRC instruction = 0xEE10xxxx
        if inst1[3] == 0xEE and inst1[2] == 0x10:
            # Check if followed by conditional branch
            if inst2[3] in [0x1A, 0x0A, 0x1B, 0x0B]:  # BNE, BEQ, BGT, BLT
                patches.append(i+4)  # Patch the branch
                if len(patches) >= 10:
                    break
    
    return patches

def patch_all_conditional_branches_to_error(data):
    """Patch all BNE that might branch to error handlers"""
    print("Finding error branches...")
    patches = []
    
    # Find "Unsupported CPUID" string
    error_string = b"Unsupported CPUID"
    string_offset = data.find(error_string)
    
    if string_offset == -1:
        return patches
    
    # Search for BNE instructions that branch toward error
    search_start = max(0, string_offset - 10000)
    search_end = min(len(data), string_offset + 1000)
    
    for i in range(search_start, search_end, 4):
        if i + 4 > len(data):
            break
        
        inst = data[i:i+4]
        if len(inst) != 4:
            continue
        
        # BNE = 0x1A
        if inst[3] == 0x1A:
            # Calculate branch target
            offset = ((inst[2] & 0x7F) << 16) | (inst[1] << 8) | inst[0]
            if offset & 0x400000:
                offset |= 0xFF800000
            offset <<= 2
            target = i + 8 + offset
            
            # If branch goes toward error string, patch it
            if target >= string_offset - 500 and target <= string_offset + 500:
                patches.append(i)
                if len(patches) >= 15:
                    break
    
    return patches

def main():
    print("=" * 60)
    print("🔧 Aggressive Kernel Patching")
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
    
    all_patches = []
    
    # 1. Patch wait loops
    wait_patches = patch_wait_loops(data)
    print(f"Found {len(wait_patches)} wait loops")
    all_patches.extend([(offset, 'wait_loop') for offset in wait_patches])
    
    # 2. Patch device register reads
    device_patches = patch_device_register_reads(data)
    print(f"Found {len(device_patches)} device register checks")
    all_patches.extend([(offset, 'device_check') for offset in device_patches])
    
    # 3. Patch error branches
    error_patches = patch_all_conditional_branches_to_error(data)
    print(f"Found {len(error_patches)} error branches")
    all_patches.extend([(offset, 'error_branch') for offset in error_patches])
    
    # 4. Patch all CMP+BNE patterns (comprehensive)
    print("Finding all CMP+BNE patterns...")
    cmp_bne_count = 0
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        if (inst1[3] & 0xF0) == 0xE0 and (inst1[2] & 0xF0) == 0x50:  # CMP
            if inst2[3] == 0x1A:  # BNE
                all_patches.append((i+4, 'cmp_bne'))
                cmp_bne_count += 1
                if cmp_bne_count >= 30:  # Limit to avoid breaking everything
                    break
    
    print(f"Found {cmp_bne_count} CMP+BNE patterns")
    print("")
    
    print(f"Total patches to apply: {len(all_patches)}")
    print("")
    
    # Apply patches
    applied = 0
    for offset, patch_type in all_patches:
        if offset + 4 > len(data):
            continue
        
        inst = data[offset:offset+4]
        if len(inst) != 4:
            continue
        
        if patch_type in ['wait_loop', 'device_check', 'error_branch', 'cmp_bne']:
            # Change BNE to BEQ (invert condition)
            if inst[3] == 0x1A:
                new_inst = bytes([inst[0], inst[1], inst[2], 0x0A])  # BEQ
                data = data[:offset] + new_inst + data[offset+4:]
                applied += 1
    
    print(f"Applied {applied} patches")
    print("")
    
    if applied > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Total patches: {applied}")
        print("")
        print("⚠️  WARNING: Aggressive patching!")
        print("   This patches many hardware checks.")
        print("   Test carefully. Keep backup safe.")
    else:
        print("⚠️  No patches applied")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())


