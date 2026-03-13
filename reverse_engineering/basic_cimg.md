# Now we will create a cimg file with proper color composition and headers and data. 
- Note: The Script will be same for python, C as well as x86 programs

# What we want to achieve
- Magic Number (Bytes 0-3): header[:4] == b"cIMG" (4 bytes)
- Version (Bytes 4-5): header[4:6] == 2 (2 bytes, <H)
- Width (Byte 6): header[6:7] == 51 (1 byte, <B)
- Height (Bytes 7-14): header[7:15] == 24 (8 bytes, <Q)

# Color Scheme 
Because the Pixel namedtuple now expects 4 values (["r", "g", "b", "ascii"]), the data parsing logic multiplies your width * height by 4 to calculate the total payload size.
- We have three strict checks on our pixel data:
  - Printable ASCII: Just like last time, the ASCII byte must fall between 0x20 and 0x7E. We'll use "A" (0x41).
  - Non-Space Count: nonspace_count != 1224. Let's do the math: $51 \text{ (width)} \times 24 \text{ (height)} = 1224$ total pixels. This means every single pixel in your image must be a non-space character.
  - ASU Maroon Color: pythonasu_maroon = (0x8C, 0x1D, 0x40)if any((pixel.r, pixel.g, pixel.b) != asu_maroon for pixel in pixels):return
 
# Script
```
import struct

with open("color.cimg", "wb") as f:
    # 1. Magic Number (4 bytes)
    f.write(b"cIMG")
    
    # 2. Version: 2 (2-byte unsigned short -> <H)
    f.write(struct.pack("<H", 2))
    
    # 3. Width: 51 (1-byte unsigned char -> <B)
    f.write(struct.pack("<B", 51))
    
    # 4. Height: 24 (8-byte unsigned long long -> <Q)
    f.write(struct.pack("<Q", 24))
    
    # 5. Pixel Data
    # 1 pixel = Red (0x8c), Green (0x1d), Blue (0x40), ASCII ('A' = 0x41)
    # We pack 4 unsigned bytes (<BBBB) into a single pixel
    single_pixel = struct.pack("<BBBB", 0x8C, 0x1D, 0x40, ord("A"))
    
    # Write the pixel exactly 1224 times (51 * 24)
    f.write(single_pixel * 1224)
```

- for more information go through the notes to read the exact description.
