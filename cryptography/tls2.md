# Bypassing Simplified TLS Authentication via Leaked Root Keys

---

- The goal is to successfully complete a simplified Transport Layer Security (TLS) handshake acting as the client. The server implementation contains a fatal vulnerability: it inadvertently leaks the Root Certificate Authority's (CA) private RSA key (root key d). By exploiting this leak, an attacker can bypass the Public Key Infrastructure (PKI) trust model entirely, forge a valid user certificate for any requested identity, and complete the encrypted handshake to retrieve the data.

---

# tls_handshake.py
- This Script will initiate an tls handshake with the server acting as client and get the data required.

  ```
    import json
    import base64
    import os
    from Crypto.Hash.SHA256 import SHA256Hash
    from Crypto.PublicKey import RSA
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import pad, unpad
    
    print("=== STEP 1: Paste the server parameters ===")
    p = int(input("p: "), 16)
    g = int(input("g: "), 16)
    root_d = int(input("root key d: "), 16)
    root_cert_b64 = input("root certificate (b64): ")
    # We don't actually need to copy the root certificate signature for our exploit
    name = input("name: ")
    A = int(input("A: "), 16)
    
    # Extract root_n from the decoded root certificate
    root_cert_data = base64.b64decode(root_cert_b64)
    root_cert = json.loads(root_cert_data)
    root_n = root_cert['key']['n']
    
    print("\n=== STEP 2: Diffie-Hellman Key Exchange ===")
    # Generate our private key 'b' and calculate public key 'B'
    b = int.from_bytes(os.urandom(256), 'big')
    B = pow(g, b, p)
    
    print(f"\n[+] Paste this back into the challenge for B:")
    print(hex(B)[2:]) # Print hex without the '0x' prefix
    
    # Calculate shared secret 's' and derive the AES key
    s = pow(A, b, p)
    aes_key = SHA256Hash(s.to_bytes(256, "little")).digest()[:16]
    
    # Initialize ONE stateful cipher to encrypt our three payloads in sequence
    cipher_encrypt = AES.new(key=aes_key, mode=AES.MODE_CBC, iv=b"\0"*16)
    
    print("\n=== STEP 3: Forging the Certificate ===")
    # Generate a 1024-bit key for our fake user
    user_key = RSA.generate(1024) 
    user_cert = {
        "name": name,
        "key": {
            "e": user_key.e,
            "n": user_key.n
        },
        "signer": "root"
    }
    user_cert_json = json.dumps(user_cert).encode()
    
    # Sign the fake cert with the leaked Root private key (root_d)
    user_cert_hash = SHA256Hash(user_cert_json).digest()
    user_cert_sig = pow(int.from_bytes(user_cert_hash, "little"), root_d, root_n).to_bytes(256, "little")
    
    # Create the handshake signature payload
    user_sig_data = (
        name.encode().ljust(256, b"\0") +
        A.to_bytes(256, "little") +
        B.to_bytes(256, "little")
    )
    user_sig_hash = SHA256Hash(user_sig_data).digest()
    
    # Sign using our NEW user private key (user_key.d)
    user_signature = pow(int.from_bytes(user_sig_hash, "little"), user_key.d, user_key.n).to_bytes(256, "little")
    
    # Encrypt all three items (state is maintained across these calls)
    enc_user_cert = cipher_encrypt.encrypt(pad(user_cert_json, 16))
    enc_user_cert_sig = cipher_encrypt.encrypt(pad(user_cert_sig, 16))
    enc_user_signature = cipher_encrypt.encrypt(pad(user_signature, 16))
    
    print("\n[+] Paste these back into the challenge:")
    print(f"user certificate (b64): {base64.b64encode(enc_user_cert).decode()}")
    print(f"user certificate signature (b64): {base64.b64encode(enc_user_cert_sig).decode()}")
    print(f"user signature (b64): {base64.b64encode(enc_user_signature).decode()}")
    
    print("\n=== STEP 4: Decrypting the data ===")
    enc_data_b64 = input("secret ciphertext (b64): ")
    enc_data = base64.b64decode(enc_data_b64)
    
    # The server creates a brand new cipher to send the data, so we reset our IV
    cipher_decrypt_data = AES.new(key=aes_key, mode=AES.MODE_CBC, iv=b"\0"*16)
    data = unpad(cipher_decrypt_data.decrypt(enc_data), 16)
    
    print("\n[!] DATA RECOVERED:")
    print(data.decode())
  ```

---

# Workflow 
- Extract Parameters: Run the program binary and collect the server's Diffie-Hellman parameters ($p$, $g$, $A$), the leaked Root CA private key, the Root CA certificate (to extract its modulus $n$), and the target username.
- Establish Shared Secret: Generate a local Diffie-Hellman private key ($b$) and calculate the public key $B$.
- Send $B$ to the server.
- Derive Symmetric Key: Calculate the shared Diffie-Hellman secret and derive an AES-128 key by hashing the secret with SHA256.
- Forge User Certificate: Generate a new 1024-bit RSA keypair.
- Create a JSON certificate binding the server's requested username to this new public key.
- Sign the Certificate: Hash the forged certificate and sign it using the leaked Root CA private key.
- This tricks the server into trusting it.
- Sign the Handshake: Concatenate the username, $A$, and $B$, hash the payload, and sign it with your newly generated user private key.
- This proves ownership of the forged certificate.
- Encrypt Payloads: Use a single, stateful AES-CBC cipher to sequentially encrypt the forged certificate, the certificate signature, and the handshake signature.
- Send these base64-encoded payloads to the server.
- Decrypt the data: The server validates the payloads and returns the encrypted data.
- Initialize a fresh AES-CBC cipher with a null IV to decrypt it.

---

- For more information read the notes provided regarding the topic.
