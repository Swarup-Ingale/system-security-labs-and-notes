# This Script and attack simulates the RSA Signatures usage and how they are used to authenticate the users and how can we abuse it

# The Attack Workflow
- Collect Info: Run cat key-n and cat key-e on the server.
- Blind: Run blind.py locally to get a Base64 string.
- Sign: Pass that string to signer.
- Unblind: Run unblind.py with the signer's output to get the final signature.
- Execute: Pass the final signature to worker

---

# Create blind.py
This script takes the word "data" and hides it mathematically so the oracle doesn't see it.
  ```
    import base64
    from Crypto.Util.number import bytes_to_long
    
    # Replace with the hex string from key-n
    n_hex = "PASTE_YOUR_N_HEX_HERE" 
    n = int(n_hex, 16)
    e = 0x10001
    r = 2 # Our secret blinding factor
    
    # 1. Convert "data" to a number
    message = b"data"
    m = bytes_to_long(message[::-1]) # Little-endian conversion
    
    # 2. Blind the message: m' = (m * r^e) mod n
    m_prime = (m * pow(r, e, n)) % n
    
    # 3. Convert to bytes (256 bytes per challenge spec)
    m_prime_bytes = m_prime.to_bytes(256, "little")
    
    print(" ORACLE INPUT ")
    print(base64.b64encode(m_prime_bytes).decode())
  ```

---

# Create unblind.py
After the oracle signs our "random noise," this script removes our secret factor ($r=2$) to reveal the real signature for "data."
  ```
    import base64
    from Crypto.Util.number import inverse
    
    n_hex = "PASTE_YOUR_N_HEX_HERE" 
    n = int(n_hex, 16)
    r = 2
    
    # Paste the base64 string returned by signer
    oracle_output = input("Enter the Base64 signature from the signer: ")
    
    # 1. Decode the blinded signature (s')
    s_prime_bytes = base64.b64decode(oracle_output)
    s_prime = int.from_bytes(s_prime_bytes, "little")
    
    # 2. Unblind: s = (s' * r^-1) mod n
    # This removes the r we added in the first script
    r_inv = inverse(r, n)
    s = (s_prime * r_inv) % n
    
    # 3. Format for the worker
    final_sig_bytes = s.to_bytes(256, "little")
    
    print("\n WORKER INPUT")
    print(base64.b64encode(final_sig_bytes).decode())
  ```

---

# Execution Steps in Terminal
- Get n:
```
cat key-n
```
- Run blind.py:
- Paste the hex into the script, run it, and copy the ORACLE INPUT.
- Get Oracle Signature:
```
$ /signer [YOUR_ORACLE_INPUT]
```
- Copy the long B64 string it gives you.
- Run unblind.py:
- Paste the signer's output when prompted. Copy the WORKER INPUT.
- Submit to Worker:
```
$ /worker [YOUR_WORKER_INPUT]
```
- Our Verification of signature happens and we get the data.

---

- For more information read the notes provided for the topic.
