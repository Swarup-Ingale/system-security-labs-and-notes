# The Python Script to Solve this challenge is :
```
  from pwn import *
    
    def solve():
        print("[*] Getting the encrypted password from the dispatcher...")
        dispatcher = process(["/challenge/dispatcher", "pw"])
        task_line = dispatcher.recvline().decode().strip()
        dispatcher.close()
        
        target_hex = task_line.split()[1]
        target_data = bytearray.fromhex(target_hex)
        blocks = [target_data[i:i+16] for i in range(0, len(target_data), 16)]
        
        print("[*] Starting the worker process...")
        worker = process("/challenge/worker")
        worker.recvline() # Consume the "The password is X bytes long!" line
        
        recovered_plaintext = b""
    
        for b in range(1, len(blocks)):
            c_prev = blocks[b-1]
            c_curr = blocks[b]
            dk_curr = bytearray(16)
            
            print(f"\n[*] Cracking Block {b}...")
            
            for pad_val in range(1, 17):
                byte_idx = 16 - pad_val
                found = False
                
                for guess in range(256):
                    # --- Visual Progress Indicator ---
                    print(f"    [*] Guessing byte {byte_idx}: {hex(guess)}", end='\r')
                    
                    c_prev_fake = bytearray(16)
                    
                    for i in range(byte_idx + 1, 16):
                        c_prev_fake[i] = dk_curr[i] ^ pad_val
                    
                    if pad_val == 1:
                        c_prev_fake[14] ^= 0xFF 
                        
                    c_prev_fake[byte_idx] = guess
                    
                    payload = (c_prev_fake + c_curr).hex()
                    worker.sendline(f"TASK: {payload}".encode())
                    
                    resp = worker.recvline()
                    
                    if b"Error:" not in resp:
                        # Success!
                        dk_curr[byte_idx] = guess ^ pad_val
                        found = True
                        
                        # Overwrite the progress line with the found byte
                        print(f"    [+] Found byte {byte_idx}: {hex(guess)} (Target pad: {pad_val})      ")
                        
                        # --- THE BULLETPROOF FIX ---
                        # Kill and restart the worker to clear any leftover \n garbage
                        worker.close()
                        worker = process("/challenge/worker", level='error')
                        worker.recvline() # Consume the startup line again
                        break
                
                if not found:
                    print(f"\n[-] Failed to crack byte {byte_idx}. Something went wrong.")
                    return
                    
            pt_block = bytes([dk_curr[i] ^ c_prev[i] for i in range(16)])
            recovered_plaintext += pt_block
            print(f"[+] Recovered block {b}: {pt_block}")
            
        worker.close()
        
        from Crypto.Util.Padding import unpad
        try:
            final_password = unpad(recovered_plaintext, 16).decode('latin1')
            print(f"\n[!!!] Attack Complete!")
            print(f"Password: {final_password}")
            print("\nRun /challenge/redeem and paste this password to get the flag!")
        except Exception as e:
            print(f"\n[!] Decrypted, but unpadding failed. Raw text: {recovered_plaintext}")
    
    if __name__ == '__main__':
        context.log_level = 'error' # Keep the output clean
```

- For Explanation about what this script does .... look at the pdf notes under same challenge name.
