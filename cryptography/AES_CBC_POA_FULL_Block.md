# The Python Script for solving this challenge is as follows:

```
    from pwn import *
    
    def solve():
        print("[*] Getting the encrypted password from the dispatcher...")
        dispatcher = process(["YOUR_DISPATCHER_CODE_FOR AES", "pw"], level='error')
        task_line = dispatcher.recvline().decode().strip()
        dispatcher.close()
        
        target_hex = task_line.split()[1]
        target_data = bytearray.fromhex(target_hex)
        
        # --- THE FULL BLOCK SHORTCUT ---
        print(f"[*] Original ciphertext length: {len(target_data)} bytes.")
        # Chop off the final 16-byte block because we know it's purely padding
        target_data = target_data[:-16]
        print(f"[*] Dropped the final padding block. New length: {len(target_data)} bytes.")
        
        blocks = [target_data[i:i+16] for i in range(0, len(target_data), 16)]
        
        print("[*] Starting the worker process...")
        worker = process("YOUR_AES_WORKER_CODE_PATH_FOR_DESCRYPTION", level='error')
        worker.recvline() 
        
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
                        dk_curr[byte_idx] = guess ^ pad_val
                        found = True
                        
                        print(f"    [+] Found byte {byte_idx}: {hex(guess)} (Target pad: {pad_val})      ")
                        
                        worker.close()
                        worker = process("YOUR_AES_WORKER_CODE_PATH_FOR_DESCRYPTION", level='error')
                        worker.recvline() 
                        break
                
                if not found:
                    print(f"\n[-] Failed to crack byte {byte_idx}.")
                    return
                    
            pt_block = bytes([dk_curr[i] ^ c_prev[i] for i in range(16)])
            recovered_plaintext += pt_block
            print(f"[+] Recovered block {b}: {pt_block}")
            
        worker.close()
        
        # --- NO UNPADDING NEEDED ---
        # Because we dropped the padding block entirely, the recovered text is the raw password!
        final_password = recovered_plaintext.decode('latin1')
        
        print(f"\n[!!!] Attack Complete!")
        print(f"Password: {final_password}")
        print("\nNext step: Run YOUR_REDEEM_CODE_FOR_PASSWORD and submit this password!")
    
    if __name__ == '__main__':
        context.log_level = 'error' 
        solve()
```

- For Explanation about what this script does .... look at the pdf notes under same challenge name.
