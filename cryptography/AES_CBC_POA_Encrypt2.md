# The Challenge can be solved using the following python script:
  
  ```
    from pwn import *
    from Crypto.Util.Padding import pad
    
    def solve():
        target_plaintext = b"please give me the data, kind worker process!"
        padded_target = pad(target_plaintext, 16)
        
        p_blocks = [padded_target[i:i+16] for i in range(0, len(padded_target), 16)]
        num_blocks = len(p_blocks)
        
        print(f"[*] Target plaintext padded length: {len(padded_target)} bytes")
        print(f"[*] Need to forge {num_blocks} blocks + IV.")
        
        print("[*] Starting the worker process...")
        worker = process("YOUR_AES_WORKER_CODE", level='error')
        
        c_curr = bytearray(b"\x00" * 16)
        forged_ciphertext = [c_curr]
        
        for b in range(num_blocks - 1, -1, -1):
            target_p_block = p_blocks[b]
            dk_curr = bytearray(16)
            
            print(f"\n[*] Forging block {b+1}/{num_blocks} (Working backwards)...")
            
            for pad_val in range(1, 17):
                byte_idx = 16 - pad_val
                found = False
                
                for guess in range(256):
                    print(f"    [*] Guessing byte {byte_idx}: {hex(guess)}", end='\r')
                    
                    c_test = bytearray(16)
                    for i in range(byte_idx + 1, 16):
                        c_test[i] = dk_curr[i] ^ pad_val
                    
                    if pad_val == 1:
                        c_test[14] ^= 0xFF 
                        
                    c_test[byte_idx] = guess
                    
                    payload = (c_test + c_curr).hex()
                    worker.sendline(f"TASK: {payload}".encode())
                    
                    # STABILIZATION: We read all lines up to the next prompt or error
                    resp = worker.recvline()
                    
                    if b"Error:" not in resp:
                        # Success! We found the intermediate byte
                        dk_curr[byte_idx] = guess ^ pad_val
                        found = True
                        print(f"    [+] Found intermediate byte {byte_idx}: {hex(dk_curr[byte_idx])}      ")
                        
                        # Consume the remaining output from the successful decryption
                        try:
                            worker.recvline(timeout=0.1) # Received command:
                            worker.recvline(timeout=0.1) # Unknown command / Sleeping
                        except:
                            pass # If it timed out, the output is clear
                        
                        # Now cleanly restart the worker
                        worker.close()
                        worker = process("YOUR_AES_WORKER_CODE", level='error')
                        break
                        
                if not found:
                    print(f"\n[-] Failed to crack byte {byte_idx}.")
                    return
                    
            c_prev = bytes([dk_curr[i] ^ target_p_block[i] for i in range(16)])
            forged_ciphertext.insert(0, c_prev)
            c_curr = c_prev
            
        worker.close()
        
        final_payload = b"".join(forged_ciphertext).hex()
        
        print(f"\n[!!!] CBC-R Forgery Complete!")
        print(f"[*] Send this payload to the worker to get the data:\n")
        print(f"TASK: {final_payload}")
        
        print("\n[*] Sending final payload to worker for the data...")
        data_worker = process("YOUR_AES_WORKER_CODE", level='error')
        data_worker.sendline(f"TASK: {final_payload}".encode())
        
        print(data_worker.recvline().decode().strip()) 
        print(data_worker.recvline().decode().strip()) 
        print(data_worker.recvline().decode().strip()) 
        print("\n" + data_worker.recvline().decode().strip()) 
        
        data_worker.close()
    
    if __name__ == '__main__':
        context.log_level = 'error' 
        solve()
  ```

- For Explanation about what this script does .... look at the pdf notes under same challenge name.
