# Now lets take it one step furthur

- Note: The Script remains same regardless the language

# The Evolution of the Format: Directives
- In earlier levels, the cIMG format was rigid: a header followed by a massive, linear block of raw pixel data. In this level, the format upgraded to use Directives (similar to "chunks" in PNG files or "atoms" in MP4s).
- Instead of just reading pixels, the parser reads a 2-byte command (the directive code) that tells it how to interpret the data that follows.
- Directive 60619 (Raw Data): Read a massive block of uncompressed pixels.
- Directive 14992 (Patch/Rectangle): Read X, Y, Width, Height, and then draw that specific box of pixels onto the canvas.

# The Trap: Overhead vs. Payload
- The binary enforced a strict file size limit: 1340 bytes.
- If we used the raw data directive (60619), the file would be over 16,000 bytes.
- So, we had to use the patch directive (14992) to compress the image.
- However, every time you use the patch directive, it costs 6 bytes of overhead just to tell the parser where the patch goes (Directive Code + X + Y + Width + Height).
- When we first tried grouping the pixels row-by-row, we created so many patches that the 6-byte overhead stacked up and blew past the 1340-byte limit.
- We had too much metadata and not enough actual pixel data.

# Script
The cIMG program initializes its entire blank canvas with white spaces. The desired_output string we dumped from memory used black spaces for its background.

Instead of wasting precious bytes meticulously drawing black spaces to match the target, our Python script simply ignored all spaces entirely. We only generated patches for the visible ASCII text (the letters and borders).

When the validation loop ran:
- It checked our drawn letters using memcmp and they matched perfectly.
- It checked the background, saw the pre-initialized white spaces, evaluated char != ' ' as false, bypassed the color check, and accepted it!

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

# 3. Dynamically calculate dimensions
chars = [p[3] for p in pixels]
width = 0
for i in range(1, len(chars)):
    if chars[i] == '.':
        width = i + 1
        break

height = total_pixels // width
print(f"[*] Found {total_pixels} pixels.")
print(f"[*] Calculated Dimensions: {width}x{height}")

# ONLY draw characters that are NOT spaces. Ignore color entirely.
def is_drawing_pixel(x, y):
    r, g, b, c = pixels[y * width + x]
    if c == '\\\\': c = '\\'
    elif c == '\\"': c = '"'
    return c != ' '

patches = []

# 4. Compress using smart horizontal contiguous blocks
for y in range(height):
    x = 0
    while x < width:
        if is_drawing_pixel(x, y):
            start_x = x
            # Group ALL contiguous drawing pixels on this row into one patch
            while x < width and is_drawing_pixel(x, y):
                x += 1
            run_width = x - start_x
            patches.append((start_x, y, run_width, 1))
        else:
            x += 1

# 5. Pack the binary file
directives_data = b""

for px, py, pw, ph in patches:
    # Add Directive 14992 (Patch) + X, Y, Width, Height
    directives_data += struct.pack("<H", 14992)
    directives_data += struct.pack("<BBBB", px, py, pw, ph)
    
    # Add the raw pixels for this horizontal block
    for y in range(py, py + ph):
        for x in range(px, px + pw):
            r, g, b, c = pixels[y * width + x]
            if c == '\\\\': char_val = ord('\\')
            elif c == '\\"': char_val = ord('"')
            else: char_val = ord(c)
            directives_data += struct.pack("<BBBB", int(r), int(g), int(b), char_val)

total_size = 12 + len(directives_data)
print(f"[*] Grouped image into {len(patches)} smart patches.")
print(f"[*] Total file size: {total_size} bytes (Limit: 1340 bytes)")

if total_size > 1340:
    print("[-] Compression failed! The math is off.")
    exit(1)

with open("patch_directive.cimg", "wb") as f:
    # Header: Magic (4), Version (3), Width (1), Height (1), Remaining Directives (4)
    f.write(b"cIMG")
    f.write(struct.pack("<H", 3))
    f.write(struct.pack("<B", width))
    f.write(struct.pack("<B", height))
    f.write(struct.pack("<I", len(patches)))
    f.write(directives_data)

print("[*] Successfully forged patch_directive.cimg!")
```
- The dump.txt is achieved from :
```
gdb --batch -ex "set print elements 0" -ex "x/s &desired_output" /challenge/cimg > dump.txt
```
- For more information read the notes provided on the topic.
