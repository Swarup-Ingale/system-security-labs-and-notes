# Once you force $s=1$, the AES key becomes a fixed sequence of bytes. You just need to take the ciphertext the server gives you, split it into the IV (first 16 bytes) and the Encrypted Data, and decrypt it.

  ```
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import unpad
    import binascii
    
    # 1. THE FORCED KEY
    # Based on s = 1 (derived from B = p + 1)
    s = 1
    key = s.to_bytes(256, "little")[:16] 
    
    # 2. GET THE DATA FROM THE SERVER
    # Run the nc command, get 'p', and calculate B = p + 1
    # Then paste the 'Data Ciphertext (hex)' here:
    ciphertext_hex = "ENTER_YOUR_PROVIDED_CIPHERTEXT"
    ciphertext_bytes = binascii.unhexlify(ciphertext_hex)
    
    # 3. SPLIT IV AND DATA
    # The server code says: ciphertext = cipher.iv + cipher.encrypt(...)
    iv = ciphertext_bytes[:16]
    encrypted_data = ciphertext_bytes[16:]
    
    # 4. DECRYPT
    cipher = AES.new(key, AES.MODE_CBC, iv=iv)
    padded_data = cipher.decrypt(encrypted_data)
    data = unpad(padded_data, 16)
    
    print(f"Decrypted Flag: {data.decode()}")
  ```

# Step-by-Step Execution Workflow 
- Connect: Run nc ....
- Calculate B: Copy the value of $p$ provided by the server.
- Open a Python terminal and type print(hex(p + 1)).
- Submit B: Paste that hex value into the B? prompt on the server.
- Get Ciphertext: The server will output a long hex string.
- Copy it.
- Run Decryptor Python Script: Paste that hex string into the ciphertext_hex variable in the script above and run it.

---

- For more information look at the notes provided for this module.
