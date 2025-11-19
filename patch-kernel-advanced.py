#!/usr/bin/env python3

"""
Advanced binary patching - find and fix hardware checks
Looks for code that references error strings and patches the checks
"""

import sys
import struct

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

# ARM instruction patterns
ARM_NOP = bytes([0x00, 0x00, 0xA0, 0xE1])  # MOV R0, R0 (NOP)
ARM_MOV_R0_0 = bytes([0x00, 0x00, 0xA0, 0xE3])  # MOV R0, #0 (success)
ARM_MOV_R0_1 = bytes([0x01, 0x00, 0xA0, 0xE3])  # MOV R0, #1 (error)
ARM_BX_LR = bytes([0x1E, 0xFF, 0x2F, 0xE1])  # BX LR (return)

def find_string_offset(data, pattern):
    """Find offset of a string"""
    pattern_bytes = pattern.encode('utf-8')
    pos = data.find(pattern_bytes)
    return pos if pos != -1 else None

def find_code_referencing_string(data, string_offset):
    """Find code that references a string (likely via LDR instruction)"""
    # ARM LDR instruction often loads string addresses
    # Pattern: LDR R0, [PC, #offset] where offset points to string
    references = []
    
    # Search for LDR instructions that might load the string address
    # LDR R0, [PC, #imm] = 0xE59F0000 + (imm << 2)
    # We'll look for instructions near the string that might reference it
    
    # Calculate PC-relative offset range
    # LDR can reach +/- 4095 bytes
    search_start = max(0, string_offset - 4096)
    search_end = min(len(data), string_offset + 4096)
    
    # Look for LDR instructions in this range
    for i in range(search_start, search_end - 4, 4):
        inst = data[i:i+4]
        # Check if it's a LDR instruction (bits 27-26 = 01, bits 25-20 = 011001)
        if (inst[3] & 0xE0) == 0xE0 and (inst[2] & 0xF0) == 0x90:
            # Calculate potential target
            # This is simplified - actual LDR decoding is more complex
            references.append(i)
    
    return references

def patch_cpuid_check(data):
    """Find and patch CPUID check code"""
    print("Finding CPUID check code...")
    
    # Find "Unsupported CPUID" string
    unsupported_offset = find_string_offset(data, "Unsupported CPUID")
    if not unsupported_offset:
        print("❌ 'Unsupported CPUID' string not found")
        return data, 0
    
    print(f"✅ Found 'Unsupported CPUID' at offset 0x{unsupported_offset:x}")
    
    # Look for code that might check CPUID
    # Common pattern: Read CPUID register, compare, branch on error
    
    # ARM MRC instruction reads coprocessor register (CPUID)
    # MRC p15, 0, Rd, c0, c0, 0 = Read MIDR (CPU ID register)
    # Pattern: 0xE1A00000 + (Rd << 12) + 0x00000000
    # Actually: MRC p15,0,Rd,c0,c0,0 = 0xE1A00000 + (Rd << 12)
    
    patches = 0
    
    # Search for MRC instructions that read CPUID
    # MRC p15,0,Rd,c0,c0,0 = 0xE1A00000 + (Rd << 12)
    for i in range(0, len(data) - 4, 4):
        inst = data[i:i+4]
        # Check for MRC p15,0,Rd,c0,c0,0
        # This is a simplified check
        if inst[0] == 0x00 and (inst[1] & 0xF0) == 0x10 and inst[2] == 0x00 and inst[3] == 0xE1:
            # Might be MRC - check if followed by comparison
            if i + 8 < len(data):
                next_inst = data[i+4:i+8]
                # Look for CMP instruction (0xE3500000 pattern)
                if (next_inst[3] & 0xF0) == 0xE0 and (next_inst[2] & 0xF0) == 0x50:
                    print(f"  Found potential CPUID check at 0x{i:x}")
                    # Try to patch: replace comparison with NOP or force success
                    # Actually, let's be more careful - just mark it
                    patches += 1
                    if patches >= 5:
                        break
    
    return data, patches

def patch_branch_to_error(data):
    """Find branches to error handlers and patch them"""
    print("Finding error branches...")
    
    # Find "Unsupported CPUID" string
    unsupported_offset = find_string_offset(data, "Unsupported CPUID")
    if not unsupported_offset:
        return data, 0
    
    patches = 0
    
    # Look for BL (Branch with Link) or B (Branch) instructions
    # that might jump to error handler
    # BL = 0xEB000000 + offset
    # B = 0xEA000000 + offset
    
    # Search backwards from error string for branches
    search_start = max(0, unsupported_offset - 4096)
    
    for i in range(search_start, unsupported_offset, 4):
        inst = data[i:i+4]
        # Check for BL or B instruction
        if len(inst) == 4:
            opcode = (inst[3] << 24) | (inst[2] << 16) | (inst[1] << 8) | inst[0]
            
            # BL instruction: bits 27-24 = 1011 (0xB)
            if (opcode & 0xFF000000) == 0xEB000000:
                # Calculate branch target
                offset = (opcode & 0x00FFFFFF) << 2
                if offset & 0x02000000:  # Sign extend
                    offset |= 0xFC000000
                target = i + 8 + offset  # PC is 8 bytes ahead in ARM
                
                # Check if this branch might go to error handler
                if abs(target - unsupported_offset) < 100:
                    print(f"  Found branch to error at 0x{i:x} (target ~0x{target:x})")
                    # Patch: Change BL to NOP
                    data = data[:i] + ARM_NOP + data[i+4:]
                    patches += 1
                    if patches >= 10:
                        break
    
    return data, patches

def patch_conditional_error_branches(data):
    """Patch conditional branches that lead to error paths"""
    print("Finding conditional error branches...")
    
    # Find error string
    unsupported_offset = find_string_offset(data, "Unsupported CPUID")
    if not unsupported_offset:
        return data, 0
    
    patches = 0
    
    # Look for BNE (Branch if Not Equal) instructions
    # BNE = 0x1A000000 + offset
    # These often branch to error handlers when comparison fails
    
    search_start = max(0, unsupported_offset - 2048)
    
    for i in range(search_start, unsupported_offset, 4):
        inst = data[i:i+4]
        if len(inst) == 4:
            opcode = (inst[3] << 24) | (inst[2] << 16) | (inst[1] << 8) | inst[0]
            
            # BNE: bits 27-24 = 0001 (0x1), bit 28 = 1 (NE)
            # Actually BNE = 0x1A000000
            if (opcode & 0xFF000000) == 0x1A000000:
                # Calculate target
                offset = (opcode & 0x00FFFFFF) << 2
                if offset & 0x02000000:
                    offset |= 0xFC000000
                target = i + 8 + offset
                
                # If branch goes toward error, patch it to never branch (BEQ or NOP)
                if target > i and target < unsupported_offset + 100:
                    print(f"  Found BNE to error at 0x{i:x}")
                    # Change BNE to BEQ (0x0A000000) - invert condition
                    new_opcode = (opcode & 0xFF000000) | 0x0A000000 | (opcode & 0x00FFFFFF)
                    new_inst = struct.pack('<I', new_opcode)
                    data = data[:i] + new_inst + data[i+4:]
                    patches += 1
                    if patches >= 10:
                        break
    
    return data, patches

def main():
    print("=" * 60)
    print("🔧 Advanced QNX Kernel Binary Patching")
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
    
    total_patches = 0
    
    # Try different patching strategies
    print("Strategy 1: Patch CPUID checks")
    data, count = patch_cpuid_check(data)
    total_patches += count
    print(f"  Patches: {count}")
    print("")
    
    print("Strategy 2: Patch branches to error handlers")
    data, count = patch_branch_to_error(data)
    total_patches += count
    print(f"  Patches: {count}")
    print("")
    
    print("Strategy 3: Patch conditional error branches")
    data, count = patch_conditional_error_branches(data)
    total_patches += count
    print(f"  Patches: {count}")
    print("")
    
    if total_patches > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Total patches: {total_patches}")
        print("")
        print("⚠️  WARNING: Experimental patching!")
        print("   Test carefully. Keep backup.")
    else:
        print("⚠️  No patches applied")
        print("   May need ARM disassembler for precise patching")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

