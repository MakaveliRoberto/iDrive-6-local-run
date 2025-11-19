#!/usr/bin/env python3

"""
Comprehensive binary patching - find and patch ALL hardware checks
Including FPGA, GPIO, device registers, wait loops, etc.
"""

import sys

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def find_wait_loops(data):
    """Find polling/wait loops that might be waiting for hardware"""
    print("Finding wait/poll loops...")
    patches = []
    
    # Look for patterns that might be polling loops
    # Common pattern: LDR (load), CMP (compare), BNE (branch back)
    # This creates a loop that waits for a value to change
    
    for i in range(0, len(data) - 16, 4):
        if i + 16 > len(data):
            break
        
        # Pattern: LDR + CMP + BNE (polling loop)
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        inst3 = data[i+8:i+12]
        
        if len(inst1) != 4 or len(inst2) != 4 or len(inst3) != 4:
            continue
        
        # Check for LDR instruction (0xE59xxxxx pattern)
        # Check for CMP instruction (0xE35xxxxx pattern)
        # Check for BNE that branches backwards (negative offset)
        if (inst1[3] & 0xF0) == 0xE0 and (inst1[3] & 0x0F) == 0x09:  # LDR pattern
            if (inst2[3] & 0xF0) == 0xE0 and (inst2[2] & 0xF0) == 0x50:  # CMP pattern
                if inst3[3] == 0x1A:  # BNE
                    # Check if BNE branches backwards (polling loop)
                    offset = ((inst3[2] & 0x7F) << 16) | (inst3[1] << 8) | inst3[0]
                    if offset & 0x400000:
                        offset |= 0xFF800000  # Sign extend
                    offset <<= 2
                    target = i + 12 + offset
                    
                    # If branch goes backwards, might be a polling loop
                    if target < i:
                        patches.append(i+8)  # Patch the BNE
                        if len(patches) >= 5:
                            break
    
    return patches

def find_device_register_checks(data):
    """Find checks for device registers that might fail"""
    print("Finding device register checks...")
    patches = []
    
    # Look for patterns that check register values
    # MRC (read coprocessor) + CMP + conditional branch
    
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        inst3 = data[i+8:i+12]
        
        if len(inst1) != 4 or len(inst2) != 4 or len(inst3) != 4:
            continue
        
        # Check for MRC (read coprocessor register) = 0xEE10xxxx
        # Followed by CMP
        # Followed by conditional branch
        if inst1[3] == 0xEE and inst1[2] == 0x10:  # MRC pattern
            if (inst2[3] & 0xF0) == 0xE0 and (inst2[2] & 0xF0) == 0x50:  # CMP
                if inst3[3] in [0x1A, 0x0A, 0x1B, 0x0B]:  # BNE, BEQ, BGT, BLT
                    patches.append(i+8)  # Patch the branch
                    if len(patches) >= 10:
                        break
    
    return patches

def find_error_returns(data):
    """Find error return patterns and change to success"""
    print("Finding error returns...")
    patches = []
    
    # Look for MOV R0, #1 (error return) = 0xE3A00001
    # Change to MOV R0, #0 (success return) = 0xE3A00000
    
    error_pattern = bytes([0x01, 0x00, 0xA0, 0xE3])
    success_pattern = bytes([0x00, 0x00, 0xA0, 0xE3])
    
    offset = 0
    while True:
        pos = data.find(error_pattern, offset)
        if pos == -1:
            break
        
        # Check if followed by BX LR (return) = 0xE12FFF1E
        if pos + 8 <= len(data):
            next_inst = data[pos+4:pos+8]
            if next_inst == bytes([0x1E, 0xFF, 0x2F, 0xE1]):  # BX LR
                patches.append(pos)
                if len(patches) >= 10:
                    break
        
        offset = pos + 4
    
    return patches, success_pattern

def patch_all_hardware_checks(data):
    """Comprehensive patching of all hardware checks"""
    print("=" * 60)
    print("Comprehensive Hardware Check Patching")
    print("=" * 60)
    print("")
    
    all_patches = []
    
    # 1. Find wait/poll loops
    wait_patches = find_wait_loops(data)
    print(f"  Found {len(wait_patches)} wait/poll loops")
    all_patches.extend([(offset, 'wait_loop') for offset in wait_patches])
    
    # 2. Find device register checks
    device_patches = find_device_register_checks(data)
    print(f"  Found {len(device_patches)} device register checks")
    all_patches.extend([(offset, 'device_check') for offset in device_patches])
    
    # 3. Find error returns
    error_patches, success_pattern = find_error_returns(data)
    print(f"  Found {len(error_patches)} error returns")
    all_patches.extend([(offset, 'error_return', success_pattern) for offset in error_patches])
    
    # 4. Find CMP+BNE patterns (like before)
    print("Finding CMP+BNE patterns...")
    cmp_bne_patches = []
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        inst1 = data[i:i+4]
        inst2 = data[i+4:i+8]
        if (inst1[3] & 0xF0) == 0xE0 and (inst1[2] & 0xF0) == 0x50:  # CMP
            if inst2[3] == 0x1A:  # BNE
                cmp_bne_patches.append(i+4)
                if len(cmp_bne_patches) >= 15:  # More than before
                    break
    print(f"  Found {len(cmp_bne_patches)} CMP+BNE patterns")
    all_patches.extend([(offset, 'cmp_bne') for offset in cmp_bne_patches])
    
    print("")
    print(f"Total patches to apply: {len(all_patches)}")
    print("")
    
    # Apply patches
    applied = 0
    for patch_info in all_patches:
        offset = patch_info[0]
        patch_type = patch_info[1]
        
        if offset + 4 > len(data):
            continue
        
        inst = data[offset:offset+4]
        if len(inst) != 4:
            continue
        
        if patch_type == 'wait_loop' or patch_type == 'device_check' or patch_type == 'cmp_bne':
            # Change BNE to BEQ (invert condition)
            if inst[3] == 0x1A:
                new_inst = bytes([inst[0], inst[1], inst[2], 0x0A])
                data = data[:offset] + new_inst + data[offset+4:]
                applied += 1
        elif patch_type == 'error_return':
            # Change error return to success
            success_pattern = patch_info[2]
            if data[offset:offset+4] == bytes([0x01, 0x00, 0xA0, 0xE3]):
                data = data[:offset] + success_pattern + data[offset+4:]
                applied += 1
    
    return data, applied

def main():
    print("=" * 60)
    print("🔧 Comprehensive Binary Patching")
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
    
    # Apply comprehensive patches
    data, patch_count = patch_all_hardware_checks(data)
    
    print("")
    if patch_count > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Total patches applied: {patch_count}")
        print("")
        print("This comprehensive patch includes:")
        print("  • CPUID checks (CMP+BNE)")
        print("  • Wait/poll loops")
        print("  • Device register checks")
        print("  • Error returns → success")
        print("")
        print("⚠️  WARNING: Extensive binary patching!")
        print("   The kernel may behave differently.")
        print("   Keep the backup safe.")
    else:
        print("⚠️  No patches applied")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

