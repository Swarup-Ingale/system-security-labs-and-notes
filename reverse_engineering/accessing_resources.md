# The Script to solve the challenge is :
```
#!/usr/bin/env python3
import argparse
import re
import struct
import subprocess
import sys


ANSI_RE = re.compile(rb"\x1b\[[0-9;]*m")


def build_payload(resource_path: str, length: int) -> bytes:
    if not (1 <= length <= 255):
        raise ValueError("length must be in the range 1..255")

    path = resource_path.encode()
    if len(path) > 255:
        raise ValueError("resource path is too long for directive 5")

    sprite_id = 0
    canvas_width = length
    canvas_height = 1

    header = b"cIMG" + struct.pack("<HBBI", 4, canvas_width, canvas_height, 2)

    load_record = bytearray(0x102)
    load_record[0] = sprite_id
    load_record[1] = length
    load_record[2] = 1
    load_record[3 : 3 + len(path)] = path

    render_record = bytes(
        [
            sprite_id,
            255,
            255,
            255,
            0,
            0,
            1,
            1,
            0,
        ]
    )

    return (
        header
        + struct.pack("<H", 5)
        + bytes(load_record)
        + struct.pack("<H", 4)
        + render_record
    )


def extract_first_row(stdout: bytes) -> str:
    plain = ANSI_RE.sub(b"", stdout)
    return plain.split(b"\n", 1)[0].decode("latin1", errors="replace")


def probe(binary: str, resource_path: str, max_len: int) -> str:
    best = ""
    for length in range(1, max_len + 1):
        payload = build_payload(resource_path, length)
        result = subprocess.run(
            [binary],
            input=payload,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if result.returncode != 0:
            break

        row = extract_first_row(result.stdout)
        if not row:
            break

        best = row
        print(best, flush=True)
        if best.endswith("}"):
            break

    return best


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", default="/challenge/cimg")
    parser.add_argument("--path", default="/flag")
    parser.add_argument("--max-len", type=int, default=255)
    parser.add_argument("--make", metavar="OUT.cimg")
    parser.add_argument("--length", type=int)
    args = parser.parse_args()

    if args.make:
        if args.length is None:
            parser.error("--make requires --length")
        payload = build_payload(args.path, args.length)
        with open(args.make, "wb") as f:
            f.write(payload)
        return 0

    flag = probe(args.binary, args.path, args.max_len)
    if flag:
        print(f"\nfinal: {flag}")
        return 0

    print("no readable prefix recovered", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

```

- For more info ping me Ill explain it in detail.
