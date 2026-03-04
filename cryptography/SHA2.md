# The goal is to prove you've performed a certain amount of computational "work" by finding a specific value (a nonce) that makes a hash meet a strict requirement.

---

# Proof-of-Work
- The server gives you a random challenge. You must find a response such that when they are joined together and hashed:
```SHA256(challenge + response)```
- The resulting hash must start with two null bytes (00 00).
- In hexadecimal, this means the first four characters of the hash must be 0000. Since each hex character is 4 bits, you are looking for a hash that starts with 16 leading zero bits.

---

# Strategy
Because SHA-256 is unpredictable, there is no mathematical way to "calculate" the response. The only way is to Brute-Force:
- Take the challenge bytes.
- Pick a random number or a counter as your response.
- Join them and hash them.
- If the first two bytes are \x00\x00, you win.
- If not, increment the counter and try again.

---

# pow_solver.py
This script will automate the guessing process to find correct value.
  ```
    import base64
    from Crypto.Hash import SHA256
    
    # 1. GET THE CHALLENGE FROM THE SERVER
    # Example: if the server says challenge (b64): ABCD...
    challenge_b64 = input("Enter the challenge (b64) from the server: ").strip()
    challenge = base64.b64decode(challenge_b64)
    
    print("Mining for a valid response...")
    
    counter = 0
    while True:
        # We use the counter as our trial response
        response = counter.to_bytes((counter.bit_length() + 7) // 8, 'big') or b'\0'
        
        # Hash(challenge + response)
        h = SHA256.new(challenge + response)
        digest = h.digest()
        
        # Check if the first 2 bytes are null (\x00\x00)
        if digest[:2] == b'\0\0':
            print(f"\nSUCCESS!")
            print(f"Response (hex): {response.hex()}")
            print(f"Response (b64): {base64.b64encode(response).decode()}")
            print(f"Resulting Hash: {h.hexdigest()}")
            break
            
        counter += 1
        if counter % 100000 == 0:
            print(f"Tried {counter} combinations...", end='\r')
  ```

---

# The Workflow
- Connect: Run nc ... to start the challenge.
- Copy Challenge: Look for the challenge (b64) line.
- Run Solver: Run the Python script above and paste that base64 string.
- Submit Response: The script will eventually give us a Response (b64).
- Paste that back into the server's response (b64): prompt.

---

- For more information read the notes on the topic.
