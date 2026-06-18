# Concept

Building upon the previous interoperability challenge, this level introduces a new layer of complexity: **opcode scrambling**. 

While the Python game and the C graphics engine can now agree on the magic bytes, they fundamentally disagree on the operation codes used to communicate. The standard engine (`cimg.c`) expects sequential opcodes (e.g., `RENDER_FRAME = 1`, `SLEEP = 7`). However, the flag-bearing engine (`CIMG_1337` in `quest.py`) sends these opcodes in reverse order (`RENDER_FRAME = 7`, `SLEEP = 1`).

To bridge this communication gap without the custom engine's source code, we must perform **binary patching at the code level**. By modifying the x86-64 comparison (`cmp`) instructions directly inside the compiled `cimg` executable, we can remap the expected opcodes to trigger the correct internal handler functions, restoring full rendering functionality to the game.

---

## Method of Solve

1. **Disassemble the Target:** Use a disassembler like `objdump -d cimg` to view the compiled x86-64 assembly of the graphics engine.
2. **Locate the Comparison Logic:** Navigate to the `<main>` function and identify the sequence of `cmp` instructions that validate the incoming `directive_code` before calling the respective handler functions (e.g., `cmp $0x1, %cx` followed by a jump or call to `handle_1`).
3. **Calculate File Offsets:** For each comparison instruction checking an opcode, calculate the exact physical file offset of the constant byte. By taking the virtual memory address of the instruction (e.g., `0x4013ea`) and subtracting the binary's base load address (`0x400000`), we can find the exact byte position on disk.
4. **Apply the Patch:** Create a script to read the binary as a mutable byte array and overwrite the original opcode constants (1, 2, 3, 5, 6, 7) with the scrambled opcodes (7, 6, 5, 3, 2, 1) at the carefully calculated offsets. The magic bytes from the previous level (`cIMG` to `CNNR`) must also be patched.
5. **Execute and Win:** Run the Python game without the `NOFLAG` argument and pipe its standard output into the newly patched graphics engine. The engine will successfully interpret the scrambled protocol, allowing you to play the game and uncover the hidden flag.

---

## Cimg Patching Script

Below is the Python script used to automatically generate the fully compatible, opcode-patched engine.

```python
#!/usr/bin/env python3
import os

# Define the input and output paths
original_binary = "/challenge/cimg"
patched_binary = "/home/hacker/your-patched-cimg"

# Read the original compiled binary into a mutable bytearray
with open(original_binary, "rb") as f:
    binary_data = bytearray(f.read())

# 1. Patch the Magic Number (Protocol Compatibility)
binary_data = bytearray(binary_data.replace(b"cIMG", b"CNNR"))

# 2. Patch the Comparison Constants (Opcode Un-scrambling)
# These are the exact physical file offsets of the comparison bytes
offsets = {
    0x13ed: 0x07,  # Remap handle_1 to expect 7
    0x13fd: 0x06,  # Remap handle_2 to expect 6
    0x140d: 0x05,  # Remap handle_3 to expect 5
    # handle_4 stays 4, no patch needed
    0x142d: 0x03,  # Remap handle_5 to expect 3
    0x1440: 0x02,  # Remap handle_6 to expect 2
    0x1453: 0x01,  # Remap handle_7 to expect 1
}

# Apply the patches directly to the bytearray
for offset, new_byte in offsets.items():
    binary_data[offset] = new_byte

# Write the modified data to a new executable file
with open(patched_binary, "wb") as f:
    f.write(binary_data)

# Ensure the new binary has execute permissions
os.chmod(patched_binary, 0o755)

print("[+] Binary patched successfully!")
print(f"[+] To play, run: /challenge/quest.py | {patched_binary}")
