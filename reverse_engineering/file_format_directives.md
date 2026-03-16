# Now lets learn to format file format directives i.e chunks of data such as PNG, JPG, etc. as per our need

- Note: The Script remains same just change input fields and important metadata according to need
- Also the code remains same for C, Python, x86

# Script
```
import re
import struct

# 1. Read the C source code
with open("source.c", "r") as f:
    c_code = f.read()

# 2. Extract the massive desired_output string
match = re.search(r'char desired_output\[\] = "(.*?)";', c_code, re.DOTALL)
if not match:
    print("[-] Could not find desired_output string!")
    exit(1)
raw_str = match.group(1)

# 3. Extract the R, G, B, and ASCII char using Regex
pixels = re.findall(r'\\x1b\[38;2;(\d{3});(\d{3});(\d{3})m(.*?)\\x1b\[0m', raw_str)
total_pixels = len(pixels)

# Dynamically calculate width by finding the first '|' character
chars = [p[3] for p in pixels]
width = chars.index('|') if '|' in chars else 66 # Fallback if not found
height = total_pixels // width

print(f"[*] Found {total_pixels} pixels.")
print(f"[*] Calculated dimensions: {width}x{height}")

# 4. Pack the binary file
with open("directives.cimg", "wb") as f:
    # --- HEADER (12 Bytes) ---
    f.write(b"cIMG")                 # Magic (4)
    f.write(struct.pack("<H", 3))    # Version: 3 (<H)
    f.write(struct.pack("<B", width))# Width (<B)
    f.write(struct.pack("<B", height))# Height (<B)
    f.write(struct.pack("<I", 1))    # Remaining Directives: 1 (<I)
    
    # --- DIRECTIVE (2 Bytes) ---
    f.write(struct.pack("<H", 24740))# Directive Code: 24740 (<H)
    
    # --- PIXEL DATA ---
    for r, g, b, c in pixels:
        # Handle escaped characters
        if c == '\\\\':
            char_val = ord('\\')
        elif c == '\\"':
            char_val = ord('"')
        else:
            char_val = ord(c)
            
        f.write(struct.pack("<BBBB", int(r), int(g), int(b), char_val))

print("[*] Successfully forged directives.cimg!")
```

- For x86 or elf file perform objdump to get assembly code
- Then use this command to get the dump file whicih will be used as input file
    ```
        gdb --batch -ex "set print elements 0" -ex "x/s &desired_output" /challenge/cimg > dump.txt
    ```
- And then the script ...
```
import re
import struct

# 1. Read the raw memory dump from GDB
try:
    with open("dump.txt", "r") as f:
        raw_str = f.read()
except FileNotFoundError:
    print("[-] dump.txt not found. Run the GDB command first!")
    exit(1)

# 2. Extract the R, G, B, and ASCII char using Regex
pixels = re.findall(r'\\033\[38;2;(\d{3});(\d{3});(\d{3})m(.*?)\\033\[0m', raw_str)
total_pixels = len(pixels)

print(f"[*] Extracted {total_pixels} pixels from the memory dump.")

width = 53
height = 17

if total_pixels != 901:
    print(f"[-] Warning: Expected 901 pixels, but found {total_pixels}. Check your dump file!")

# 3. Pack the binary file
with open("x86_directives.cimg", "wb") as f:
    # --- HEADER (12 Bytes) ---
    f.write(b"cIMG")                 # Magic (4)
    f.write(struct.pack("<H", 3))    # Version: 3 (<H)
    f.write(struct.pack("<B", width))# Width: 53 (<B)
    f.write(struct.pack("<B", height))# Height: 17 (<B)
    f.write(struct.pack("<I", 1))    # Remaining Directives: 1 (<I)
    
    # --- DIRECTIVE (2 Bytes) ---
    f.write(struct.pack("<H", 55369))# Directive Code: 55369 (<H)
    
    # --- PIXEL DATA ---
    for r, g, b, c in pixels:
        if c == '\\\\':
            char_val = ord('\\')
        elif c == '\\"':
            char_val = ord('"')
        else:
            char_val = ord(c)
            
        f.write(struct.pack("<BBBB", int(r), int(g), int(b), char_val))

print("[*] Successfully forged x86_directives.cimg!")
```

- For more information read the notes provided for this topic.
