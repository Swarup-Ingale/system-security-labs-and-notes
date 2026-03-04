# we need to act as the Certificate Authority (CA). This Script Simulates the workflow of how a Certificate Authorizer works.

---

- The server has given you the "Keys to the Kingdom" (the root private key $d$). Your job is to create a new identity (User Certificate), sign it with that root key, and then use your own new key to decrypt the data the server sends you.

---

#  The Strategy 
- Extract the Root Modulus ($n$): Decode the root certificate (b64) to find the value of $n$.
- Generate a User Key: Create a new RSA key pair for yourself.
- Create the JSON: Construct a JSON object for your user certificate.
- Sign: Hash that JSON and sign it using the root key d and root n.
- Submit & Decrypt: Provide the certificate and signature to the server, then decrypt the resulting ciphertext with your private user key.

---

# Solution Script
we will need pycryptodome installed in our environment. Replace the placeholders with the data from your terminal.
  ```
    import json
    import base64
    from Crypto.PublicKey import RSA
    from Crypto.Hash import SHA256
    
    # DATA FROM YOUR TERMINAL
    root_d = #Place root ID
    
    # We need the 'n' from the root certificate. 
    # You can decode it or just paste it if you have it.
    root_cert_b64 = "PLACE ROOT CERT=="
    root_n = json.loads(base64.b64decode(root_cert_b64))['key']['n']
    
    # GENERATE USER KEY
    user_key = RSA.generate(1024)
    
    # CONSTRUCT CERTIFICATE (with strict formatting)
    user_certificate = {
        "name": "gemini_explorer",
        "key": {
            "e": user_key.e,
            "n": user_key.n,
        },
        "signer": "root",
    }
    
    # separators=(',', ':') removes all extra whitespace
    cert_data = json.dumps(user_certificate, separators=(',', ':')).encode()
    
    # SIGN
    cert_hash = SHA256.new(cert_data).digest()
    signature_int = pow(int.from_bytes(cert_hash, "little"), root_d, root_n)
    signature_bytes = signature_int.to_bytes(256, "little")
    
    print("--- SUBMIT THESE ---")
    print(f"user certificate (b64): {base64.b64encode(cert_data).decode()}")
    print(f"user certificate signature (b64): {base64.b64encode(signature_bytes).decode()}")
    
    # DECRYPT
    ct_b64 = input("\nEnter secret ciphertext (b64): ")
    ct_int = int.from_bytes(base64.b64decode(ct_b64), "little")
    m_int = pow(ct_int, user_key.d, user_key.n)
    print(f"\nFLAG: {m_int.to_bytes((m_int.bit_length() + 7) // 8, 'little').decode()}")
  ```

---

# The Workflow 
- Copy the code above into a file named solve.py.
- Run it in your terminal: ```python3 solve.py.```
- The script will print two long Base64 strings. Paste them into the nc window when it asks for "user certificate" and "user certificate signature".
- The server will verify your signature and then print a secret ciphertext (b64).
- Copy that ciphertext and paste it back into your Python script's prompt. It will then reveal the data.

---

- For more information read the notes provided on the topic.
