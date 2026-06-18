# Concept

This iteration of the challenge escalates the complexity of code-level binary patching. The fundamental problem remains the same: the Python game engine (`CIMG_1337`) sends scrambled opcodes, and the C graphics engine (`cimg`) needs to be modified to interpret them correctly.

However, the source code of the C engine was modified to use sequential `if` statements instead of a `switch` block for opcode handling. This minor source-level change causes the GCC compiler to optimize the opcode dispatching mechanism significantly. Instead of simple x86 `cmp` instructions checking against constant byte values, the binary now relies on a jump table utilizing 32-bit relative `call` instructions to jump directly to specific handler functions (e.g., `call 4015c6 <handle_1>`). 

To restore interoperability, we cannot simply swap constant bytes. We must perform relative address calculation to intentionally corrupt the `call` destinations, redirecting the execution flow to the correct, un-scrambled handler functions.

---

## Method of Solve

1. **Disassemble and Analyze:** Use `objdump -d cimg` to view the compiled assembly. In the `<main>` function, identify the sequence of `call` instructions associated with the jump table. 
2. **Understand Relative Addressing:** In x86-64, an `e8` `call` instruction uses a 32-bit relative offset. The CPU calculates the final destination by taking the address of the *next* instruction (Instruction Address + 5 bytes) and adding the relative offset.
3. **Calculate New Offsets:** For each scrambled opcode, calculate the new relative offset required to reach the correct handler function using the formula: `Target_Address - (Instruction_Address + 5)`.
4. **Map the File Offsets:** Convert the virtual memory address of the offset payload (the 4 bytes immediately following the `e8` opcode) into physical file offsets by subtracting the binary's base load address (`0x400000`).
5. **Apply the Patch:** Write a script to calculate these new offsets, pack them as 32-bit little-endian integers, and write them directly into the `cimg` binary file. (The magic header `cIMG` must also be patched to `CNNR`).
6. **Execution:** Pipe the standard output of the Python game into the newly patched graphics engine, then utilize an automated headless pathfinding script to parse the game state and extract the hidden flag.

---

## Cimg Patching Script

Below is the Python script used to automatically calculate the relative math and generate the opcode-compatible engine.

```python
#!/usr/bin/env python3
import os
import struct

original_binary = "/challenge/cimg"
patched_binary = "/home/hacker/your-patched-cimg"

# Read the original compiled binary into a mutable bytearray
with open(original_binary, "rb") as f:
    binary_data = bytearray(f.read())

# 1. Patch the Magic Number (Protocol Compatibility)
binary_data = bytearray(binary_data.replace(b"cIMG", b"CNNR"))

# 2. Patch the 32-bit Relative Offsets in the Call Instructions
# Formula: Target Address - (Call Instruction Address + 5)
# Note: The hex keys are the physical file offsets of the arguments being modified
patches = {
    # Opcode 1 -> Map to handle_7
    0x1409: struct.pack("<i", 0x401e91 - (0x401408 + 5)),
    
    # Opcode 2 -> Map to handle_6
    0x1410: struct.pack("<i", 0x401f6b - (0x40140f + 5)),
    
    # Opcode 3 -> Map to handle_5
    0x1417: struct.pack("<i", 0x401a9e - (0x401416 + 5)),
    
    # Opcode 4 stays mapped to handle_4 (no patch needed)
    
    # Opcode 5 -> Map to handle_3
    0x1425: struct.pack("<i", 0x40194d - (0x401424 + 5)),
    
    # Opcode 6 -> Map to handle_2
    0x142c: struct.pack("<i", 0x401748 - (0x40142b + 5)),
    
    # Opcode 7 -> Map to handle_1
    0x1433: struct.pack("<i", 0x4015c6 - (0x401432 + 5)),
}

# Apply the packed bytes directly to the bytearray
for offset, new_bytes in patches.items():
    binary_data[offset:offset+4] = new_bytes

# Write the modified data to a new executable file
with open(patched_binary, "wb") as f:
    f.write(binary_data)

# Ensure the new binary has execute permissions
os.chmod(patched_binary, 0o755)

print("[+] Call instruction offsets patched successfully!")
print(f"[+] To play, run: /challenge/quest.py | {patched_binary}")
