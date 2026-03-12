# Now lets learn to assign proper height and width along with other configurations to our cimg file.
- Note: This is same for python, c as well as x86

# What to expect
The 8-Byte Header Structure
- The header has shrunk back down, and the byte sizes have shifted:
  - Magic Number (Bytes 0-3): Exactly cIMG.
  - Version (Bytes 4-5): header[4:6] is 2 bytes long, so it's an unsigned short (<H). Must be 1.
  - Width (Byte 6): header[6:7] is exactly 1 byte long (<B).
  - Height (Byte 7): header[7:8] is exactly 1 byte long (<B).
 
Instead of asserting a fixed width and height, the program dictates that your image must contain exactly 275 non-space characters (meaning anything other than a blank space, 0x20).

# Intended Solution
Since Width and Height are each only 1 byte long, their maximum value is 255. We can't just make an image with a width of 275 and a height of 1!

We need to choose a width and a height that, when multiplied together, give us an image large enough to hold at least 275 characters.

To keep things perfectly exact and simple, let's find two numbers under 255 that multiply together to make exactly 275:

25 * 11 = 275

If we create an image that is 25 pixels wide and 11 pixels tall, the total data size will be exactly 275 bytes. 

If we fill that entire image with our trusty "A" character, we will have exactly 275 non-space characters, perfectly satisfying the condition

# Script
```
  import struct

with open("display.cimg", "wb") as f:
    # 1. Magic Number: 4 bytes
    f.write(b"cIMG")
    
    # 2. Version: 2 bytes (<H)
    f.write(struct.pack("<H", 1))
    
    # 3. Width: 1 byte (<B)
    f.write(struct.pack("<B", 25))
    
    # 4. Height: 1 byte (<B)
    f.write(struct.pack("<B", 11))
    
    # 5. Pixel Data: width * height (25 * 11 = 275 bytes)
    # Filling it with 'A' means exactly 275 non-space characters!
    f.write(b"A" * 275)
```

- for more information read the notes regarding the topic.
