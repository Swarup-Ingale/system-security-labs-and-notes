# Now in this script we will learn to generate proper data fragments with encoding, RGB color scheme and provide it to the elf binary 

- Note: The Script code remains same for C, Python and x86

# Script
```
import struct

with open("state.cimg", "wb") as f:
    # 1. Header
    f.write(b"cIMG")               # Magic: 4 bytes
    f.write(struct.pack("<H", 2))  # Version: 2 (2 bytes, <H)
    f.write(struct.pack("<B", 4))  # Width: 4 (1 byte, <B)
    f.write(struct.pack("<B", 1))  # Height: 1 (1 byte, <B)
    
    # 2. Pixel Data
    # Pack each pixel as <BBBB (Red, Green, Blue, ASCII)
    f.write(struct.pack("<BBBB", 119, 170, 30, ord('c'))) # Pixel 1
    f.write(struct.pack("<BBBB", 195, 26, 8, ord('I')))   # Pixel 2
    f.write(struct.pack("<BBBB", 102, 67, 59, ord('M')))  # Pixel 3
    f.write(struct.pack("<BBBB", 176, 91, 137, ord('G'))) # Pixel 4
```

- For more information read the notes provided on the topic.
