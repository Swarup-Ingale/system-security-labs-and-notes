# Animated cIMG — Figlet Reconstruction

### Overview

The vulnerability from Challenge 1 was fixed: `handle_6` now calls `printf("clear")` instead of `system("clear")`. As compensation, a setuid script (`generate_flag_image`) creates `/challenge/flag.cimg` containing the flag rendered as a figlet ASCII art animation.

### The Script

The `generate_flag_image` script:
1. Reads `/flag`
2. Pipes it through `figlet -fascii9` to create large ASCII art
3. Extracts every (x, y, character) pixel from the figlet output
4. **Shuffles** all pixels randomly
5. Creates a cIMG file with directive 2 (draw pixel), directive 6 (clear), and directive 7 (sleep) interleaved

The resulting animation draws pixels one-by-one in random order with a clear-and-sleep cycle, making it unreadable in real-time.

### Approach

The `/challenge/flag.cimg` file is world-readable (group `hacker`) even though it is owned by root. We can parse the cIMG binary format directly, extracting all directive-2 pixel entries with their (x, y, character) data, then sort by (y, x) to reconstruct the full figlet output.

### Solution

Parser script:

```python
import struct
with open("/challenge/flag.cimg", "rb") as f:
    data = f.read()
magic = data[0:4]
version = struct.unpack("<H", data[4:6])[0]
width = struct.unpack("B", data[6:7])[0]
height = struct.unpack("B", data[7:8])[0]
num_directives = struct.unpack("<I", data[8:12])[0]
offset = 12
pixels = []
while offset < len(data):
    code = struct.unpack("<H", data[offset:offset+2])[0]
    offset += 2
    if code == 2:
        x = struct.unpack("B", data[offset:offset+1])[0]
        y = struct.unpack("B", data[offset+1:offset+2])[0]
        w = struct.unpack("B", data[offset+2:offset+3])[0]
        h = struct.unpack("B", data[offset+3:offset+4])[0]
        for i in range(w * h):
            ch = struct.unpack("B", data[offset+7+i*4:offset+8+i*4])[0]
            pixels.append((y, x, ch))
        offset += 4 + w * h * 4
    elif code == 6:
        offset += 1
    elif code == 7:
        offset += 4
    else:
        break
pixels.sort()
result = [[" " for _ in range(width)] for _ in range(height)]
for y, x, ch in pixels:
    if y < height and x < width:
        result[y][x] = chr(ch)
print("\n".join("".join(r) for r in result))
```

The reconstructed figlet output visually renders the flag text in the `ascii9` font, which can be decoded to recover the flag string.

### Flag

The flag was obtained successfully.
