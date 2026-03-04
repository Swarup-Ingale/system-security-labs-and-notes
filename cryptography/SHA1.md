# A full SHA-256 hash has $2^{256}$ possible values. However, a 3-byte (24-bit) prefix only has $2^{24}$ (16,777,216) possible values. On a modern computer, checking 16 million hashes is extremely fast.

# This Script basically helps us understand how we can perform hash collision and genrerate same hash as our secret to get the data

---

# The Strategy
- Identify the Target: When we run the source script, it prints the data_hash[:6]. This is your target (e.g., a1b2c3).
- Brute Force: Write a script that hashes random numbers or increments a counter until the first 6 hex characters of the hash match that target.
- Submit: Once a match is found, send the input (in hex) to the server.

--- 

# collide.py
This script will rapidly hash numbers until it finds a match for the prefix provided by the server.
  ```
    import hashlib
    
    # 1. GET THIS FROM THE SERVER
    # Example: if the server says data_hash[:6]='a1b2c3', target is 'a1b2c3'
    target_prefix = input("Enter the 6-character hex prefix from the server: ").strip()
    
    print(f"Searching for a collision for prefix: {target_prefix}...")
    
    counter = 0
    while True:
        # Convert counter to bytes
        test_input = str(counter).encode()
        
        # Calculate SHA-256 hash
        current_hash = hashlib.sha256(test_input).hexdigest()
        
        # Check if the first 6 characters match
        if current_hash[:6] == target_prefix:
            print(f"\nSUCCESS!")
            print(f"Input (string): {counter}")
            print(f"Input (hex):    {test_input.hex()}")
            print(f"Full Hash:      {current_hash}")
            break
        
        counter += 1
        if counter % 1000000 == 0:
            print(f"Checked {counter} hashes...")
  ```

---

# The Workflow
- Connect: Run nc ... to start the challenge.
- Read Target: Note the 6 characters printed (e.g., data_hash[:6]='d4e5f6').
- Run Solver: * Open a second terminal.
    - Run python3 collide.py.
    - Type in the 6 characters when prompted.
- Copy Hex: The script will eventually spit out an Input (hex).
- Submit: Paste that hex value into the Colliding input prompt on the server.

---

- For more information read the notes provided for this simulation.
