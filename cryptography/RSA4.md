# This Script Simulates the RSA Algorithm but in reverse state 

  ```
    from Crypto.PublicKey import RSA
    import binascii
    
    # 1. GENERATE YOUR OWN KEY PAIR
    # 1024 bits fits the server's requirement (2^512 < n < 2^1024)
    key = RSA.generate(1024)
    
    print(f"--- YOUR PUBLIC KEY ---")
    print(f"e (hex): {hex(key.e)}")
    print(f"n (hex): {hex(key.n)}")
    
    # 2. INPUT THE CHALLENGE FROM THE SERVER
    # Run the nc command and paste the 'challenge' hex here
    challenge_hex = input("Enter the challenge hex from the server: ")
    challenge = int(challenge_hex, 16)
    
    # 3. CALCULATE THE RESPONSE
    # Because you generated the key, you have the private 'd'
    # Formula: response = challenge^d mod n
    response = pow(challenge, key.d, key.n)
    
    print(f"\n--- YOUR RESPONSE ---")
    print(f"response (hex): {hex(response)}")
    
    # 4. AFTER SUBMITTING RESPONSE, THE SERVER GIVES YOU THE DATA CIPHERTEXT
    # Paste the 'secret ciphertext (b64)' here
    ciphertext_b64 = input("Enter the secret ciphertext (b64): ")
    ciphertext_bytes = binascii.a2b_base64(ciphertext_b64)
    c = int.from_bytes(ciphertext_bytes, "little")
    
    # DECRYPT THE DATA
    # Formula: m = c^d mod n
    m_int = pow(c, key.d, key.n)
    data = m_int.to_bytes((m_int.bit_length() + 7) // 8, "little")
    
    print(f"\nDECRYPTED DATA: {data.decode()}")
  ```

# Step-by-Step Workflow 
- Run the script: It will generate a key and print $e$ and $n$ in hex.
- Submit to Server: Copy those $e$ and $n$ values into your nc session.
- Get Data: The server will give you a data hex.
- Calculate: Paste that hex back into your Python script.
- It will output the response.
- Submit Response: Paste the response hex back into the server.
- Final Decryption: The server will send a secret ciphertext (b64).
- Paste that into the script to finally reveal the data.

---

- For more information read the notes provided for the topic.
