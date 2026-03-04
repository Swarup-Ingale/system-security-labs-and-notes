# This Script Solves the randomly generated challenge and generates a response for the challenge which can be used to decrypt the message

- The server gives you a random "challenge" (a big number). It then asks: "What number, when raised to my public power $e$, equals this challenge?" Because of the way RSA works, only someone who knows the private key $d$ can calculate that answer.

  ```
    # 1. PASTE THE VALUES FROM THE SERVER
    e =  #Paste the e here
    d =  # Paste the d here
    n =  #Paste the n here
    challenge =  #Paste the challenge here
    
    # 2. CALCULATE THE RESPONSE
    # Formula: response = challenge^d mod n
    response = pow(challenge, d, n)
    
    # 3. OUTPUT THE RESULT
    print(f"Send this back to the server: {hex(response)}")
  ```

# Step-by-Step Workflow 
- Connect: Run your nc command.
- Copy-Paste: Take the $e, d, n,$ and challenge hex values and put them into the script above.
- Run: Execute the script to get your response.
- Submit: Paste the response hex (usually just the part after 0x) back into the server's prompt.
- Get Data: The server will verify the math and print your data.

---

- For more information read the notes provided.
