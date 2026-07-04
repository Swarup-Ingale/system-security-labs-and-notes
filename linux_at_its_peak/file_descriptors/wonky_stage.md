# Current Working Directory (CWD) Relocation TOCTOU

# Concept
When I examined the script, the challenge's title and description ("the stage can be rocky") made perfect sense. The script creates a highly specific directory structure (`/tmp/circus/stage`), changes its Current Working Directory (CWD) into it, and strictly verifies its location using `realpath`. 

After confirming its location, the script pauses indefinitely, waiting for my input via the `read` command. Once I provide a file name, it executes `cat "../../$NAME"`. Because my input is heavily sanitized to only contain lowercase letters (`tr -cd "[a-z]"`), I cannot simply type `../flag`. If the script executes normally, `../../` from `/tmp/circus/stage` resolves to `/tmp`, restricting me to reading lowercase files specifically inside the `/tmp` directory.

However, I spotted a fatal flaw: **a process's CWD is tied to the physical directory inode, not the string path.** During the execution pause, the script has already passed the `realpath` check. This gives me a Time-of-Check to Time-of-Use (TOCTOU) window to physically move the "stage" directory! 

If I open another terminal and move the directory up one level (e.g., renaming `/tmp/circus/stage` to `/tmp/stage`), the script's CWD physically moves with it. When the script finally resumes and resolves `../../$NAME`, it starts from the new location (`/tmp/stage`). The first `..` takes it to `/tmp`, and the second `..` takes it straight to `/` (the root directory). Thus, `../../flag` flawlessly resolves to `/flag`.

**The Ownership Hurdle:**
There was one catch. If I let the root-privileged script create `/tmp/circus/stage`, the `root` user owns the `circus` directory. This means I would get a `Permission denied` error when trying to move the `stage` folder out of it. To bypass this, I simply needed to pre-create the directory structure myself *before* running the script. The script's `mkdir -p` command safely ignores existing directories, leaving my normal user as the owner and granting me the permissions needed to pull the rug out from under it.

# Method of Solve
To perform this filesystem sleight-of-hand, I used two terminal sessions:

1. **Pre-creating the stage (Terminal 1):** Before running the challenge, I manually created the directory path. This ensured I was the owner of `/tmp/circus` and had the necessary permissions to modify its contents later.
   ```bash
   user@machine:~$ mkdir -p /tmp/circus/stage
   ```
2. **Triggering the vulnerable pause (Terminal 1):** I executed the challenge. The script ran mkdir -p (which did nothing since the folder existed), successfully verified it was in /tmp/circus/stage, and then froze, waiting for my input.
   ```bash
   user@machine:~$ /challenge/abc
   Where should I backflip? ??
   ```
3. **Moving the stage (Terminal 2):** I left the first terminal hanging and switched to my second terminal. Because I owned the parent directory, I successfully moved the stage directory out of circus and directly into /tmp.
   ```bash
   user@machine:~$ mv /tmp/circus/stage /tmp/stage
   ```
4. **Executing the bypass (Terminal 1):** I switched back to my first terminal. Now that the ground had literally shifted beneath the script's feet, I provided my sanitized payload:
   ```bash
   flag
   ```
5. **Capturing the flag:** As soon as I pressed Enter, the script executed cat "../../flag". Because the underlying CWD was now /tmp/stage, the kernel resolved the path as /tmp/stage/../../flag, which simplified perfectly to /flag. The script printed the flag directly to my screen!
   ```bash
   flag{REDACTED}
   ```

# Conclusion

This challenge was a fantastic, creative lesson in how the Linux kernel handles relative path resolution (../) and Current Working Directories. I learned that CWDs are pointers to inodes, meaning that if a directory is renamed or moved, any process currently inside it stays inside it, but its relative relationship to the rest of the filesystem changes. I also learned the importance of directory ownership when attempting to manipulate the filesystem around a privileged process. From a security standpoint, this proves that a script cannot rely on a one-time realpath check if it subsequently yields control or pauses. If an attacker can manipulate the directory tree between the Time-of-Check and the Time-of-Use, even strictly enforced relative paths can be trivially hijacked to reach arbitrary locations.
