# file headers containing both a magic number to identify the format and a version number to dictate how the rest of the parser should behave.

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
