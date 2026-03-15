# Now lets learn to write payload for much bigger proper files to get our priorities straight

- Note: The script remains same for C, Python and x86
- For x86 code ... we have to create raw bytes using :
  ```
    gdb --batch -ex "set print elements 0" -ex "x/s &desired_output" /challenge/cimg > dump.txt
  ```
- Load dump.txt instead of source.c for x86.

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

# 3. Use Regex to extract the R, G, B, and ASCII char
# Using (.*?) to catch escaped backslashes (\\)
pixels = re.findall(r'\\x1b\[38;2;(\d{3});(\d{3});(\d{3})m(.*?)\\x1b\[0m', raw_str)

total_pixels = len(pixels)
width = 40
height = total_pixels // width

print(f"[*] Found {total_pixels} pixels.")
print(f"[*] Calculated dimensions: {width}x{height}")

# 4. Pack the binary file
with open("internal_state_c.cimg", "wb") as f:
    # Header: Magic (4), Version (2), Width (1), Height (1)
    f.write(b"cIMG")
    f.write(struct.pack("<H", 2))
    f.write(struct.pack("<B", width))
    f.write(struct.pack("<B", height))
    
    # Pixel Data: R, G, B, ASCII
    for r, g, b, c in pixels:
        # If C source had an escaped backslash, turn it back into a single '\'
        if c == '\\\\':
            char_val = ord('\\')
        else:
            char_val = ord(c)
            
        f.write(struct.pack("<BBBB", int(r), int(g), int(b), char_val))

print("[*] Successfully generated internal_state_c.cimg!")
```

- For more information look at the notes provided for the same topic.
