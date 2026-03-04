# This Python Script Helps in simple Simulation of the RSA Algorithm and how we can Descrypt an ciphertext using RSA

  ```
    import binascii

    # 1. PASTE THE VALUES FROM THE SERVER
    n =  # Paste the (public) n here
    e =  # Paste the (public) e here
    d =  # Paste the (private) d here
    ciphertext_hex = " " # Paste the Flag Ciphertext (hex) here
    
    # 2. CONVERT HEX CIPHERTEXT TO A NUMBER
    # The server used "little" endian to store it
    c = int.from_bytes(binascii.unhexlify(ciphertext_hex), "little")
    
    # 3. RSA DECRYPTION FORMULA: m = c^d mod n
    m_int = pow(c, d, n)
    
    # 4. CONVERT NUMBER BACK TO BYTES (Data)
    # The server used "little" endian for the flag too
    data = m_int.to_bytes((m_int.bit_length() + 7) // 8, "little")
    
    print(f"Decrypted Data: {data.decode()}")
  ```

# The script provided does the following:
- Generates a 2048-bit RSA key pair.
- $n$ and $e$ are the Public Key.
- $d$ is the Private Key.
- It takes the data, turns it into a giant number, and encrypts it using the formula:
  - $$c = \pm^e mod n$$It gives us $n$, $e$, $d$, and the Ciphertext.
- Since we have the Private Key ($d$), our job is simply to "undo" the math.

---

- For more information read the notes provided.
