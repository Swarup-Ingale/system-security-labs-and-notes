# Method of Solve
  
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

# The Script :
```
#!/usr/bin/env python3
import struct
from pathlib import Path


WIDTH = 76
HEIGHT = 24


def directive_3(sprite_id, rows):
    height = len(rows)
    width = len(rows[0])
    data = "".join(rows).encode("ascii")
    assert all(len(row) == width for row in rows)
    assert all(0x20 <= b <= 0x7e for b in data)
    return struct.pack("<HBBB", 3, sprite_id, width, height) + data


def directive_4(sprite_id, rgb, x, y, repeat_w=1, repeat_h=1, transparent=0):
    return struct.pack(
        "<HBBBBBBBBB",
        4,
        sprite_id,
        rgb[0],
        rgb[1],
        rgb[2],
        x,
        y,
        repeat_w,
        repeat_h,
        transparent,
    )


directives = []

directives.append(directive_3(0, ["."] + ["|"] * 22 + ["'"]))
directives.append(directive_4(0, (255, 255, 255), 0, 0))
directives.append(directive_4(0, (255, 255, 255), 75, 0))

directives.append(directive_3(1, ["-"]))
directives.append(directive_4(1, (255, 255, 255), 1, 0, repeat_w=74))
directives.append(directive_4(1, (255, 255, 255), 1, 23, repeat_w=74))

art = [
    (2, (255, 0, 0), 23, 10, ["  ___ ", " / __|", "| (__ ", " \\___|"]),
    (3, (0, 255, 0), 30, 9, [" ___ ", "|_ _|", " | | ", " | | ", "|___|"]),
    (
        4,
        (0, 0, 255),
        36,
        9,
        [" __  __ ", "|  \\/  |", "| |\\/| |", "| |  | |", "|_|  |_|"],
    ),
    (5, (128, 128, 128), 45, 9, ["  ____ ", " / ___|", "| |  _ ", "| |_| |", " \\____|"]),
]

for sprite_id, rgb, x, y, rows in art:
    directives.append(directive_3(sprite_id, rows))
    directives.append(directive_4(sprite_id, rgb, x, y, transparent=ord(" ")))

payload = struct.pack("<4sHBBI", b"cIMG", 4, WIDTH, HEIGHT, len(directives)) + b"".join(directives)
assert len(payload) == 279

Path("solve.cimg").write_bytes(payload)
print(f"wrote solve.cimg ({len(payload)} bytes, {len(directives)} directives)")
```

- This solves a most complex reverse category challenge of generating a custom file.
