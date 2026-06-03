  1. Read the challenge source
     In cimg.c, the important checks were:
      - magic must be cIMG
      - version must be 4
      - final framebuffer must match desired_output
      - total_data <= 285

     So this was not about memory corruption. It was about constructing a valid tiny .cimg file.

  2. Understand the file format
     Header:

     struct cimg_header {
         char magic_number[4];      // cIMG
         uint16_t version;          // 4
         uint8_t width;
         uint8_t height;
         uint32_t remaining_directives;
     };

     We used:

     width  = 76
     height = 24

  3. Reverse the missing handlers
     The source included:

     #include "cimg-handlers.c" // YOU DON'T GET THIS FILE!

     So we disassembled cimg and found:
      - handle_1: raw full image draw, too expensive
      - handle_2: raw rectangular patch draw, still expensive
      - handle_3: define an ASCII sprite
      - handle_4: render a sprite with RGB color, position, repeats, and transparent char

     Directive 3 format:

     u16 directive = 3
     u8  sprite_id
     u8  width
     u8  height
     bytes sprite_ascii[width * height]

     Directive 4 format:

     u16 directive = 4
     u8  sprite_id
     u8  r
     u8  g
     u8  b
     u8  x
     u8  y
     u8  repeat_w
     u8  repeat_h
     u8  transparent_char

  4. Extract the target image
     desired_output was embedded in the binary as terminal pixels. Each rendered pixel is 24 bytes.

     The target was a mostly empty 76x24 frame:

     .--------------------------------------------------------------------------.
     |                                                                          |
     ...
     |                              ___   __  __    ____                        |
     |                        ___  |_ _| |  \/  |  / ___|                       |
     |                       / __|  | |  | |\/| | | |  _                        |
     |                      | (__   | |  | |  | | | |_| |                       |
     |                       \___| |___| |_|  |_|  \____|                       |
     ...
     '--------------------------------------------------------------------------'

  5. Compress using sprites
     Because total_data had to be <= 285, drawing raw pixels was impossible.

     The trick was:
      - one vertical-border sprite: ., many |, '
      - one single-character dash sprite: -, repeated 74 times for top/bottom borders
      - four small colored sprites for the word art:
          - red C
          - green I
          - blue M
          - gray G

  6. Build the payload
     The final payload had:
      - 12-byte header
      - 14 directives
      - total size: 279 bytes

     That is below the challenge limit of 285.

     The generator is here:

     solve_advanced_sprites.py

  7. Verify locally
     Running:

     ./cimg solve.cimg

     locally reached the win() path, proven by this message:

     ERROR: Failed to open the flag -- No such file or directory!

     That means the image matched, but local /flag was unavailable.

  8. Run remotely
     Then we sent the same payload to the actual challenge binary:

     ssh -i /home/swale/PWN/key hacker@dojo.pwn.college /challenge/cimg < solve.cimg
