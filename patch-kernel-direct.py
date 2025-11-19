#!/usr/bin/env python3

"""
Direct binary patching - find code that prints "Unsupported CPUID"
and patch it to never execute
"""

import sys
import struct

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def find_all_occurrences(data, pattern):
    """Find all occurrences of a pattern"""
    offsets = []
    start = 0
    while True:
        pos = data.find(pattern, start)
        if pos == -1:
            break
        offsets.append(pos)
        start = pos + 1
    return offsets

def patch_function_to_return_success(data, function_start, max_size=200):
    """Patch a function to immediately return success (MOV R0, #0; BX LR)"""
    # ARM: MOV R0, #0 = 0xE3A00000
    # ARM: BX LR = 0xE1A0F00E
    success_return = bytes([0x00, 0x00, 0xA0, 0xE3, 0x0E, 0xF0, 0xA0, 0xE1])
    
    # Find a safe place to patch (aligned to 4 bytes)
    for offset in range(function_start, min(function_start + max_size, len(data) - 8), 4):
        # Check if we can safely overwrite this instruction
        # Don't patch if it looks like it's part of a critical structure
        if offset + 8 <= len(data):
            # Patch: replace first two instructions with success return
            data = data[:offset] + success_return + data[offset+8:]
            return data, offset
    return data, None

def find_code_near_string(data, string_offset, search_range=500):
    """Find code that might reference a string"""
    # Look for LDR instructions that load the string address
    # LDR R0, [PC, #offset] where offset points to string
    
    start = max(0, string_offset - search_range)
    end = min(len(data), string_offset + search_range)
    
    # Look for patterns that might be function prologues
    # PUSH {R4-R11, LR} = 0xE92D4FF0 (or variations)
    # Or simpler: PUSH {LR} = 0xE52DE004
    
    function_starts = []
    for i in range(start, end - 4, 4):
        inst = data[i:i+4]
        if len(inst) == 4:
            # Check for PUSH instruction (common function start)
            # PUSH {regs} = 0xE92Dxxxx
            if inst[3] == 0xE9 and inst[2] == 0x2D:
                function_starts.append(i)
    
    return function_starts

def patch_unsupported_cpuid_check(data):
    """Find and patch the "Unsupported CPUID" check"""
    print("Finding 'Unsupported CPUID' check...")
    
    # Find the error string
    error_string = b"Unsupported CPUID"
    string_offset = data.find(error_string)
    if string_offset == -1:
        print("❌ 'Unsupported CPUID' string not found")
        return data, 0
    
    print(f"✅ Found error string at offset 0x{string_offset:x}")
    
    # Find code that references this string
    # Look backwards for code that might call print/error with this string
    patches = 0
    
    # Strategy 1: Find function that contains this string reference
    # Look for code patterns near the string
    code_candidates = find_code_near_string(data, string_offset, 1000)
    print(f"Found {len(code_candidates)} potential function starts near string")
    
    # Strategy 2: Look for BL (Branch with Link) instructions that might
    # call error/print functions
    # BL = 0xEB000000 + offset
    # Search backwards from string
    search_start = max(0, string_offset - 2000)
    
    for i in range(search_start, string_offset, 4):
        if i + 4 > len(data):
            break
        inst = data[i:i+4]
        if len(inst) == 4:
            # Check for BL instruction
            if inst[3] == 0xEB:
                # Calculate branch target
                offset = ((inst[2] & 0x7F) << 16) | (inst[1] << 8) | inst[0]
                if offset & 0x400000:
                    offset |= 0xFF800000  # Sign extend
                offset <<= 2
                target = i + 8 + offset
                
                # If branch goes near error string, might be error handler
                if abs(target - string_offset) < 200:
                    print(f"  Found BL near error at 0x{i:x} (target ~0x{target:x})")
                    # Try to patch: NOP the branch
                    nop = bytes([0x00, 0x00, 0xA0, 0xE1])  # MOV R0, R0
                    data = data[:i] + nop + data[i+4:]
                    patches += 1
                    if patches >= 5:
                        break
    
    # Strategy 3: Look for the actual CPUID check
    # MRC p15,0,Rd,c0,c0,0 reads MIDR (CPUID)
    # Then CMP to check value
    # Then conditional branch
    
    # Search for MRC followed by CMP
    for i in range(0, len(data) - 12, 4):
        if i + 12 > len(data):
            break
        
        # Check for MRC p15,0,Rd,c0,c0,0 pattern
        # MRC = 0xEE100010 + (Rd << 12) + (crm << 0) + (opc2 << 5)
        # MRC p15,0,R0,c0,c0,0 = 0xEE100F10
        inst1 = data[i:i+4]
        
        # Check for CMP instruction (0xE3500000 pattern)
        if i + 4 < len(data):
            inst2 = data[i+4:i+8]
            if (inst2[3] & 0xF0) == 0xE0 and (inst2[2] & 0xF0) == 0x50:
                # Might be CMP - check if followed by conditional branch
                if i + 8 < len(data):
                    inst3 = data[i+8:i+12]
                    # Check for BNE (branch if not equal) = 0x1A000000
                    if inst3[3] == 0x1A:
                        print(f"  Found potential CPUID check at 0x{i:x}")
                        # Patch: Change BNE to BEQ (invert condition)
                        # BNE = 0x1A, BEQ = 0x0A
                        new_inst3 = bytes([inst3[0], inst3[1], inst3[2], 0x0A])
                        data = data[:i+8] + new_inst3 + data[i+12:]
                        patches += 1
                        if patches >= 10:
                            break
    
    return data, patches

def main():
    print("=" * 60)
    print("🔧 Direct Binary Patching - Hardware Checks")
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
    
    # Patch CPUID check
    data, patches = patch_unsupported_cpuid_check(data)
    
    print("")
    if patches > 0:
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print(f"   Total patches: {patches}")
        print("")
        print("⚠️  WARNING: Experimental binary patching!")
        print("   The kernel may not boot correctly.")
        print("   Keep the backup safe.")
    else:
        print("⚠️  No patches applied")
        print("   May need ARM disassembler for precise patching")
    
    print("")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    sys.exit(main())

