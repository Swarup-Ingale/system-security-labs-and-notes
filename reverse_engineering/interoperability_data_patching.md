# Concept

The core concept of this challenge revolves around software **interoperability** and **binary patching**. 

We are provided with the source code for a Python-based game (`quest.py`) and a compiled C-based graphics engine (`cimg`). The Python game communicates with the graphics engine by sending a binary stream of rendering directives to standard output. 

However, there is an intentional mismatch in the protocol:
* When the game is run in "compatibility mode" (`NOFLAG`), it outputs the magic bytes `cIMG` in its header.
* When the game is run normally (to retrieve the flag), it utilizes a custom engine class (`CIMG_1337`) that outputs the magic bytes `CNNR`.
* The provided `cimg` compiled binary contains a hardcoded check using `strncmp` that strictly expects the magic bytes `cIMG`. If it sees anything else, it throws an "Invalid magic number!" error and exits.

Because we do not have the source code for the `CIMG_1337` compatible engine, we must achieve interoperability by modifying the compiled `cimg` binary directly. Since both magic strings are exactly four bytes long, we can perform an in-place byte replacement without altering the binary's memory offsets or overall structure.

---

## Method of Solve

1. **Identify the Target Bytes:** By analyzing the provided `cimg.c` source and `quest.py`, we identify that the standard engine expects `b"cIMG"`, while the flag-bearing game outputs `b"CNNR"`.
2. **Patch the Binary:** We write a script to read the compiled `cimg` binary, search for the ASCII string `cIMG`, and overwrite it exactly with `CNNR`. 
3. **Set Permissions:** Make sure the newly patched binary is executable.
4. **Chain the Execution:** Run the Python game without the `NOFLAG` argument and pipe its standard output directly into the standard input of our newly patched graphics engine.
5. **Play the Game:** With the patched engine successfully interpreting the `CNNR` protocol, the game renders correctly. The final step is to manually play the game, avoid the bombs (`B`), and repeatedly collect the hidden targets (`?` using the `l` key) to uncover the flag characters one by one.

---

## Cimg Patching Script

Below is the Python script used to automatically generate the patched, compatible engine. 

```python
#!/usr/bin/env python3
import os

# Define the input and output paths
original_binary = "/challenge/cimg"
patched_binary = "/home/hacker/your-patched-cimg"

# Read the original compiled binary
with open(original_binary, "rb") as f:
    binary_data = f.read()

# Perform an in-place byte replacement of the magic string.
# This specifically modifies the bytes checked by strncmp in the compiled C code.
patched_data = binary_data.replace(b"cIMG", b"CNNR")

# Write the modified data to a new executable file
with open(patched_binary, "wb") as f:
    f.write(patched_data)

# Ensure the new binary has execute permissions
os.chmod(patched_binary, 0o755)

print("[+] Binary patched successfully!")
print(f"[+] To play, run: /challenge/quest.py | {patched_binary}")
