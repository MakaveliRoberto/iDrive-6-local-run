#!/usr/bin/env python3

"""
Patch hardware checks in QNX boot binary
Finds and modifies ARM instructions that check for hardware
"""

import sys
import re
import struct

BOOT_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs"
BACKUP_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.backup"
PATCHED_IMAGE = "nbtevo-system-dump/sda2/boot1.ifs.patched"

def find_string_offsets(data, pattern):
    """Find all offsets of a string pattern"""
    offsets = []
    pattern_bytes = pattern.encode('utf-8')
    start = 0
    while True:
        pos = data.find(pattern_bytes, start)
        if pos == -1:
            break
        offsets.append(pos)
        start = pos + 1
    return offsets

def patch_arm_instruction(data, offset, old_inst, new_inst):
    """Patch an ARM instruction at given offset"""
    # ARM instructions are 32-bit (4 bytes)
    if offset + 4 > len(data):
        return False
    
    current = data[offset:offset+4]
    if current == old_inst:
        # Replace instruction
        new_data = data[:offset] + new_inst + data[offset+4:]
        return new_data
    return False

def find_hardware_checks(data):
    """Find hardware check patterns in binary"""
    print("Searching for hardware check patterns...")
    print("")
    
    # Find string references
    patterns = [
        b"get_omap5430_info",
        b"Unsupported CPUID",
        b"omap5432uevm",
        b"hwi_omap5430",
    ]
    
    for pattern in patterns:
        offsets = find_string_offsets(data, pattern.decode('utf-8', errors='ignore'))
        if offsets:
            print(f"Found '{pattern.decode('utf-8', errors='ignore')}' at offsets:")
            for off in offsets[:5]:
                print(f"  0x{off:x} ({off})")
                # Show surrounding bytes
                start = max(0, off - 32)
                end = min(len(data), off + len(pattern) + 32)
                print(f"    Context: {data[start:end].hex()[:80]}...")
            print("")
    
    return offsets

def patch_error_returns(data):
    """Try to patch error return instructions to success"""
    print("Attempting to patch error returns...")
    print("")
    
    # ARM MOV R0, #1 (error return) = 0xE3A00001
    # ARM MOV R0, #0 (success return) = 0xE3A00000
    # Pattern: E3 A0 00 01 -> E3 A0 00 00
    
    error_pattern = bytes([0xE3, 0xA0, 0x00, 0x01])
    success_pattern = bytes([0xE3, 0xA0, 0x00, 0x00])
    
    count = 0
    offset = 0
    while True:
        pos = data.find(error_pattern, offset)
        if pos == -1:
            break
        
        # Check if this looks like a return (might be followed by BX LR or similar)
        # For now, just patch it
        data = data[:pos] + success_pattern + data[pos+4:]
        count += 1
        offset = pos + 4
        
        if count >= 10:  # Limit patches
            break
    
    if count > 0:
        print(f"✅ Patched {count} potential error returns")
    else:
        print("⚠️  No error return patterns found (or already patched)")
    
    return data, count

def main():
    print("=" * 50)
    print("🔧 QNX Kernel Binary Patching")
    print("=" * 50)
    print("")
    
    try:
        with open(BOOT_IMAGE, 'rb') as f:
            data = bytearray(f.read())
    except FileNotFoundError:
        print(f"❌ Boot image not found: {BOOT_IMAGE}")
        return 1
    
    print(f"✅ Loaded boot image: {len(data)} bytes")
    print("")
    
    # Create backup
    import shutil
    import os
    if not os.path.exists(BACKUP_IMAGE):
        shutil.copy(BOOT_IMAGE, BACKUP_IMAGE)
        print(f"✅ Backup created: {BACKUP_IMAGE}")
    print("")
    
    # Find hardware checks
    find_hardware_checks(data)
    
    # Try to patch error returns
    data, patch_count = patch_error_returns(data)
    
    if patch_count > 0:
        # Save patched image
        with open(PATCHED_IMAGE, 'wb') as f:
            f.write(data)
        print("")
        print(f"✅ Patched image saved: {PATCHED_IMAGE}")
        print("")
        print("⚠️  WARNING: Binary patching is experimental!")
        print("   The patched image may not work correctly.")
        print("   Test carefully and keep the backup.")
    else:
        print("")
        print("⚠️  No patches applied")
        print("   Hardware checks may use different patterns")
        print("   or require more advanced analysis")
    
    print("")
    print("=" * 50)
    return 0

if __name__ == "__main__":
    sys.exit(main())

