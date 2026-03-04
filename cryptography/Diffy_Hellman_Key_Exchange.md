# The Python Code for solving the DHKE is as follows:
  ```
    p_hex = "Paste the 'p' from the server here" 
    p = int(p_hex, 16)
    
    # We choose B = p + 1. 
    # Because (p + 1)^a mod p == 1^a mod p == 1
    my_B = p + 1
    my_s = 1
    
    print(f"Send this as B: {hex(my_B)}")
    print(f"Send this as s: {hex(my_s)}")
  ```
- For the explanation and working of DHKE read the notes.
