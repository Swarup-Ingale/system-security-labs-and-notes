# This Script Demonstrates the Decryption of RSA Encrypted plaintext if p and q primes are known.

- Standard computers try to factor $n$ by basically guessing and checking (very slowly). Shor's Algorithm uses quantum properties to find the "period" of a function related to $n$. Once the period is found, the factors $p$ and $q$ drop out with simple math. So In RSA, knowing the factors $p$ and $q$ is equivalent to having the private key $d$

  ```
    import binascii
    from Crypto.Util.number import inverse
    
    # 1. VALUES FROM THE SERVER
    e =  #Paste e
    p =  # Paste p
    q =  #Paste q
    ciphertext_hex = "" #Paste the Data Ciphertext (hex)
    
    # 2. DERIVE THE PRIVATE KEY
    n = p * q
    phi = (p - 1) * (q - 1)
    
    # d is the 'multiplicative inverse' of e modulo phi
    d = inverse(e, phi)
    
    # 3. DECRYPT
    c = int.from_bytes(binascii.unhexlify(ciphertext_hex), "little")
    m_int = pow(c, d, n)
    
    # 4. CONVERT TO BYTES
    data = m_int.to_bytes((m_int.bit_length() + 7) // 8, "little")
    print(f"Decrypted Data: {data.decode()}")
  ```

# To solve this, we will:
- Calculate $n = p \times q$.
- Calculate the totient $\phi(n) = (p-1) \times (q-1)$.
- Calculate $d$ (the modular inverse of $e \pmod{\phi(n)}$).
- Decrypt the ciphertext using $m = c^d \pmod n$.

---

- For more information read the notes provided fr=or this topic.
