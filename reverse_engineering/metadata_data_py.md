# Concept 
- We will learn to provide custom generated metadata such as dimensions along with version, headers, etc.
- Same goes for X86, and C too.

# Solution 
- Magic Number (Bytes 0-3): Must be exactly (M63.
- Version (Bytes 4-7): Must be 1. Since it reads header[4:8], this is a 4-byte little-endian integer (\x01\x00\x00\x00).
- Width (Byte 8): Must be 62. Notice it only reads header[8:9], so this is a 1-byte integer (\x3e).
- Height (Bytes 9-12): Must be 14. It reads header[9:13], so this is another 4-byte little-endian integer (\x0e\x00\x00\x00).
- Data (Pixels): The script calculates width * height (62 * 14 = 868). It then attempts to read exactly 868 bytes of data immediately after the header.
- Because we need to write exactly 868 bytes of padding for the image data, using a Python script is much easier than trying to chain echo commands.
- We can use struct.pack with <I for the 4-byte integers and <B for the 1-byte integer.

# Script
```
  import struct
  
  with open("dimensions.cimg", "wb") as f:
      # 1. Magic Number (4 bytes)
      f.write(b"(M63")
      
      # 2. Version: 1 (4-byte little-endian)
      f.write(struct.pack("<I", 1))
      
      # 3. Width: 62 (1-byte integer)
      f.write(struct.pack("<B", 62))
      
      # 4. Height: 14 (4-byte little-endian)
      f.write(struct.pack("<I", 14))
      
      # 5. Pixel Data: width * height (62 * 14 = 868 bytes)
      # We can just write 868 'A's to satisfy the length check!
      f.write(b"A" * 868)
```
- The script will construct the perfect 13-byte header, append 868 bytes of dummy pixel data, and pass every single assertion.
