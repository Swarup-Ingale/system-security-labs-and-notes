## Vulnerable Overflow

**Concepts Used:** Cryptography (AES-ECB Oracle) + Binary Exploitation (Ret2Win Buffer Overflow)

## 1. Challenge Overview
The challenge consists of two interlinked components:
1.  **`dispatch` (Python Script):** A wrapper that reads a 16-byte encryption key from `/challenge/.key`, takes our input, prepends a verified header, pads it, and encrypts it using **AES in ECB mode**.
2.  **`vulnerable-overflow` (C Binary):** A SUID C executable that reads ciphertexts, decrypts the first block to verify the header, and then blindly decrypts the rest of the ciphertext onto the stack. If successful, a `win` function at address `0x4013b6` can be executed to read and print the flag.

The goal is to exploit the Python script's ECB mode to forge a malicious encrypted payload, which, when decrypted by the C binary, overflows the stack and redirects execution to the `win` function.

---

## 2. Vulnerability Analysis

### 2.1 The Cryptography Flaw: AES-ECB Block Splicing
The `dispatch` script uses AES-ECB (Electronic Codebook). ECB mode is inherently flawed because it encrypts each 16-byte block of plaintext independently.
If we send exactly 16 bytes of payload to dispatch, the resulting plaintext is 32 bytes (before padding):
- Block 1 (Header): b"VERIFIED" + p64(16) (16 bytes)
- Block 2 (Our Input): message (16 bytes)
- Block 3 (Padding): PKCS#7 padding (16 bytes of \x10)

Because blocks are encrypted independently, we can use dispatch as an Encryption Oracle. By observing Block 2 of the output, we can learn the exact ciphertext for any 16-byte plaintext chunk we choose. We can then collect these blocks and splice them together to construct a valid, encrypted, and arbitrarily long malicious payload.

### 2.2 The Binary Flaw: Stack Buffer Overflow

Analyzing the disassembled vulnerable-overflow binary reveals how the payload is processed:
1. It reads up to 0x1000 bytes of encrypted data from stdin.
2. It decrypts the first 16 bytes and uses memcmp to ensure it matches the VERIFIED header.
3. It sets up a second decryption context for the rest of the payload, specifically calling EVP_CIPHER_CTX_set_padding(ctx, 0) to disable padding checks.
4. It decrypts the rest of the ciphertext into a buffer located at rbp - 0x70 (112 bytes).

**The Bug:** The program never checks if the remaining ciphertext exceeds the 112-byte buffer. It blindly loops and decrypts the provided blocks onto the stack. This allows us to overwrite the saved Base Pointer (rbp) and the Instruction Pointer (Return Address / rip).

---

## 3. Exploit Strategy (Ret2Win)

To hijack control flow, we need to overwrite the return address of the challenge() function with the address of the win() function (0x4013b6).
**Calculating the Offset:**
- Buffer size: 0x70 (112 bytes)
- Saved rbp: 8 bytes
- Total offset to Return Address: 112 + 8 = 120 bytes.
- Return Address overwrite: 8 bytes.
- Total Payload Size: 128 bytes (Exactly 8 AES blocks).

**Payload Construction:**
1. Block 1 to 7 (112 bytes): Garbage padding (e.g., A * 112).
2. Block 8 (16 bytes): 8 bytes of garbage to fill the saved rbp, followed by the 8-byte little-endian address of win() (0x4013b6).

Because the binary expects this payload to be encrypted, we cannot just send raw bytes. We must encrypt these 128 bytes, 16 bytes at a time, using our dispatch oracle.

---

## 4. Step-by-Step Execution

Here is the exact methodology used to solve the challenge interactively via tmux and ipython:

### Step 1: Setting up the Oracle Helper

We created a Python helper function in pwntools to automate the extraction of the 2nd block from dispatch.
```python
def get_encrypted_block(data):
    p = process('./dispatch')
    p.send(data)
    res = p.readall()
    p.close()
    return res[16:32] # Extract Block 2
```

### Step 2: Grabbing a Valid Header

The C binary requires a valid header to pass the initial validation.
```python
p = process('./dispatch')
p.send(b'A' * 16)
enc_header = p.readall()[:16] # Extract Block 1
p.close()
```

### Step 3: Forging the Encrypted Padding

We generated 112 bytes of padding and encrypted it block-by-block.
```python
padding = b'A' * 112
enc_padding = b''
for i in range(0, len(padding), 16):
    enc_padding += get_encrypted_block(padding[i:i+16])
```

### Step 4: Forging the Encrypted Return Address

We packed the target win address (0x4013b6) and encrypted it.
```python
ret_overwrite = b'B' * 8 + p64(0x4013b6)
enc_ret = get_encrypted_block(ret_overwrite)
```

### Step 5: Splicing and Delivery

We concatenated the pieces and sent them to the vulnerable binary.
```python
final_payload = enc_header + enc_padding + enc_ret
target = process('/challenge/vulnerable-overflow')
target.send(final_payload)
target.interactive()
```

*Result:* The binary successfully verified the header, decrypted our forged payload onto the stack, returned to 0x4013b6, and printed the flag.
