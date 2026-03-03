# The Python Script for solving this challenge is as follows:
  ```
    from pwn import *
    
    def solve():
        print("[*] Asking the dispatcher for the encrypted flag...")
        # Run the dispatcher with 'flag' to get the multi-block target
        dispatcher = process(["YOUR_DISPATCHER_CODE_FOR_AES_IV_GENERATOR", "flag"], level='error')
        task_line = dispatcher.recvline().decode().strip()
        dispatcher.close()
        
        # Extract the hex and slice it into 16-byte blocks
        target_hex = task_line.split()[1]
        target_data = bytearray.fromhex(target_hex)
        blocks = [target_data[i:i+16] for i in range(0, len(target_data), 16)]
        
        print(f"[*] Target contains {len(blocks)} blocks (including IV).")
        print("[*] Starting the worker process...")
        
        worker = process("YOUR_AES_WORKER_CODE_WHICH_DOES_DECRYPTION", level='error')
        recovered_flag = b""
    
        # Loop through every block containing data
        for b in range(1, len(blocks)):
            c_prev_real = blocks[b-1] # The REAL previous block
            c_curr = blocks[b]        # The block we are currently cracking
            dk_curr = bytearray(16)   # To hold the intermediate state
            
            print(f"\n[*] Cracking Block {b}...")
            
            for pad_val in range(1, 17):
                byte_idx = 16 - pad_val
                found = False
                
                for guess in range(256):
                    print(f"    [*] Guessing byte {byte_idx}: {hex(guess)}", end='\r')
                    
                    # The FAKE previous block we mutate to test padding
                    c_prev_fake = bytearray(16)
                    
                    # Set up the already-cracked bytes to produce the correct padding
                    for i in range(byte_idx + 1, 16):
                        c_prev_fake[i] = dk_curr[i] ^ pad_val
                    
                    # Prevent the "Fake Positive" on the very first byte guess
                    if pad_val == 1:
                        c_prev_fake[14] ^= 0xFF 
                        
                    c_prev_fake[byte_idx] = guess
                    
                    # Send our two-block payload (Fake C_prev + Target C_curr)
                    payload = (c_prev_fake + c_curr).hex()
                    worker.sendline(f"TASK: {payload}".encode())
                    
                    # Read the single line response
                    resp = worker.recvline()
                    
                    if b"Error:" not in resp:
                        # Valid padding! We found the intermediate byte.
                        dk_curr[byte_idx] = guess ^ pad_val
                        found = True
                        print(f"    [+] Found byte {byte_idx}: {hex(guess)} (Target pad: {pad_val})      ")
                        break
                
                if not found:
                    print(f"\n[-] Failed to crack byte {byte_idx}. Exiting.")
                    return
                    
            # Once we have the full intermediate state for the block, 
            # XOR it with the REAL previous block to reveal the plaintext!
            pt_block = bytes([dk_curr[i] ^ c_prev_real[i] for i in range(16)])
            recovered_data += pt_block
            print(f"[+] Recovered plaintext for block {b}: {pt_block}")
            
        worker.close()
        
        # Strip the PKCS7 padding off the final combined plaintext
        from Crypto.Util.Padding import unpad
        try:
            final_data = unpad(recovered_flag, 16).decode('latin1')
            print(f"\n[!!!] Multi-Block Attack Complete!")
            print(f"DATA: {final_data}")
        except Exception as e:
            print(f"\n[!] Decrypted, but unpadding failed. Raw text: {recovered_data}")
    
    if __name__ == '__main__':
        context.log_level = 'error' 
        solve()
  ```

- 
