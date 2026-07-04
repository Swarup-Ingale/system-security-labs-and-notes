# Name
Directory Lockout Bypass via Symlink and Relative Path Flaw

# Concept
When I analyzed the script, I immediately noticed its aggressive approach to locking down the file system. It takes an absolute path (`DEST`), creates it, and then loops through every single directory in that path, changing its ownership to `root:root` and its permissions to `000`. It also explicitly checks if any directory fragment is a symlink and exits if it finds one. 

At first glance, this seemed incredibly secure. If I provide a path, the script locks me out of traversing it before it even asks for the source file (`SRC`) to copy. 

However, I spotted two critical oversights:
1. **The missing check on the final file:** The script checks if any *directory component* of `$DEST` is a symlink, but it never checks if the final output file itself (`$DEST/out`) is a symlink. 
2. **The flawed `rm -f out` sanitization:** The author tried to prevent attackers from pre-creating `$DEST/out` as a symlink by adding the line `rm -f out` just before the final copy operation. But I noticed a fatal mistake: they used a relative path. `rm -f out` deletes a file named `out` in the *Current Working Directory* (CWD) where the script was executed, **not** necessarily in `$DEST`!

This created a massive blind spot. By running the script from a completely different directory, I realized I could pre-create `$DEST/out` as a symlink. The flawed `rm` command safely misses my symlink, and when the root-privileged script redirects the flag output to `$DEST/out`, it follows my symlink right out of the locked `000` directory and drops the flag into a readable location!

# Method of Solve
Here are the exact steps I used to perform this exploit and capture the flag:

1. **Setting up the safe zones:** I opened two terminal sessions. I decided to use `/tmp/x` as my locked destination directory, and `/dev/shm` (shared memory) as my completely separate workspace where the flag would be delivered.

2. **Pre-creating the directory and symlink:** In my first terminal, I created the destination directory and planted the symlink. I pointed the symlink to a file I could read in my safe zone.
   ```bash
   mkdir -p /tmp/x
   ln -s /dev/shm/flag_copy /tmp/x/out
   ```
3. **Dodging the rm -f out command:** To ensure the script's rm command wouldn't touch my symlink, I changed my Current Working Directory to /dev/shm before running the challenge.
   ```bash
   cd /dev/shm
   /challenge/run
   ```
4. **Triggering the directory lockdown:** The script paused for the first input. I provided /tmp/x as my DEST.
   ```bash
   /tmp/x
   ```
   The script processed this, looping through /tmp and /tmp/x, aggressively changing their permissions to 000. Immediately after, it executed rm -f out. Because I was in /dev/shm, it uselessly tried to delete /dev/shm/out, leaving my symlink perfectly intact inside the locked /tmp/x directory!
5. **Executing the bypass:** The script paused again for the SRC input. I provided the path to the flag:
   ```bash
   /flag
   ```
   The script executed cat /flag > /tmp/x/out. Because the script was running as root, it completely ignored the 000 directory permissions blocking normal users. It resolved /tmp/x/out, followed my symlink, and wrote the contents of the flag directly into /dev/shm/flag_copy.
6. **Capturing the flag:** From my second terminal, I simply read the dropped file!
   ```bash
   cat /dev/shm/flag_copy
   ```

# Conclusion

This challenge was an incredible lesson in path resolution and execution context. I learned that root processes will happily follow symlinks out of completely restricted (000) directories. More importantly, it highlighted the sheer danger of mixing relative paths (out) with absolute paths ($DEST) in security scripts. The author's attempt to sanitize the workspace with rm -f out failed purely because it assumed my execution context (CWD) would be the same as the destination directory. Relying on implicit environments rather than explicit, absolute paths is a critical flaw that renders even the strictest directory lockdowns useless.
