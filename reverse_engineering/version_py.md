# file headers containing both a magic number to identify the format and a version number to dictate how the rest of the parser should behave.

- The Code is same for C, Python and X86

# NOTE : For x86
- first do objdump and read the asm code
- Then look into main section and look for cmpb and cmpl
- the cmpb compares bytes and cmpl compares long value
- decode the hexadecimal into ASCII and feed it as raw bytes and modify the magic number of version of the file by decoding the cmpl
- Script used :
  ```
    echo -ne "<0%R\x0b\x00\x00\x00" > x86_version.cimg
  ```
- As for me ... the cmpb decoded to *<0%R* and cmpl to *11* which in raw bytes is \x0b\x00\x00\x00

# Script
  ```
    import struct
    
    # Open a file with the correct extension in write-binary mode
    with open("versioned_image.cimg", "wb") as f:
        # Write the 4-byte magic number
        f.write(b"CONR")
        
        # Pack the integer 95 as a 4-byte little-endian unsigned int (<I)
        f.write(struct.pack("<I", 95))
  ```

- This writes the neccessary bytes for magic number of headers and file contents and hence modifies the ELF binary of the file
