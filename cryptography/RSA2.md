# Standard computers try to factor $n$ by basically guessing and checking (very slowly). Shor's Algorithm uses quantum properties to find the "period" of a function related to $n$. Once the period is found, the factors $p$ and $q$ drop out with simple math. So In RSA, knowing the factors $p$ and $q$ is equivalent to having the private key $d$
  ```
    import binascii
    from Crypto.Util.number import inverse
    
    # 1. VALUES FROM THE SERVER
    e = 0x10001 #Paste e
    p = 0xe4aaef45f61729b70438e57098fae31f982ecdcd02c9314c220ee33baabbeb05c75617d8bab3633d55818cc61cdbafb281b5e57bf81d49edd07adc5dcabe4014afb8b4c95d7d556b3c21ea5db04ccc152847cd0a57a973655b2736880adbdb24729c0173a4de87531fd2b5fd9070a66875d1044151b67c4ddbc95873ab1f2411 # Paste p
    q = 0xfabbd8ad8ef05bb7526decd3fc2d28f253b3f08c488f0905ffe35f2048ca11231a8ad2bc10db2f8414f31264948a86a37306042b8fcd6e2f7b9f5db8b209a4319af03c7dbdc50e86bcd8c2010499258b03b0424d0698570dec7db1361717cc5335609c73142dcf5c2abffd3bff561e0378483694b25b34a96e2f698fb7bae615 #Paste q
    ciphertext_hex = "a83cb70a17a71c1d7c88f57b4cd41a7cd9d4648d66132dc6140395bfdfc863fbd913caa66e426b9f8c21b5627bd64d32870c82df827f5640af68cf03ababf5819cccf8f737c35fc1197520c7fa95fff865bf0be01ff8264df4d7a0e77b1613df311bd0cf8b820222bbc3567fbb368087249cd13e7c1e83e2a76782896b69413f0972400020b2d5e9aea321cd25f5a84fd33ff3f981e976dd2795f1438bfe72e03da98e2d12f17272b9310dfc881c9e87860e54119f79a5019effd0172f51778c151f9f058a4e6317e97bddba3d8b620154674d01c3fbc55baeab92a5964096d744d409f65b68b5fb14205d1922a2ef4ebf3b9fda412ad80c28720244d4e3b18f" #Paste the Data Ciphertext (hex)
    
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
