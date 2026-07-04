# Time-of-Check to Time-of-Use (TOCTOU)

# Concept
When I examined the provided script, the line `read SRC < <(head -n 1 | tr -cd "[a-z0-9/]")` immediately caught my eye. I noticed that the script first creates `/challenge/vault` with default (readable) permissions. Then, it pauses execution and waits indefinitely for me to provide input. Only *after* receiving my input does it execute `chmod 222 /challenge/vault` to make the file write-only, followed by appending my chosen file into it.

This introduces a classic Time-of-Check to Time-of-Use (TOCTOU) vulnerability. In Linux, file permissions are strictly checked when a process opens a file and requests a file descriptor via the `open()` syscall. If I open the file while it is still readable, the operating system grants me a read-allowed file descriptor. If the script subsequently changes the file's permissions on disk to write-only, my already-open file descriptor remains perfectly valid. I can continue reading the file even though its outward permissions have changed!

# Method of Solve
To exploit this pause in execution, I realized I needed to open the file for reading while the script was waiting for my input, and keep it open while the flag was being appended. 

Here are the exact steps I took using two terminal sessions:

1. **Triggering the vulnerable pause:** In my first terminal session, I ran the challenge executable (`/challenge/run`). The script created the vault, wrote the initial "The secret is: " line, and then froze, waiting for my standard input.
2. **Opening the file descriptor:** I left the first terminal hanging and switched to a second terminal. At this point, `/challenge/vault` was still readable because the `chmod` command had not executed yet. I ran `tail -f /challenge/vault` to open the file and continuously listen for appended data. It printed the initial text and waited.
3. **Injecting the payload:** I switched back to my first terminal. The script was asking for a file to read from, so I typed `/flag` and pressed Enter.
4. **Capturing the flag:** As soon as I pressed Enter, the script resumed. It ran the `chmod 222` command and then appended the contents of `/flag` to the vault. Because my `tail -f` process in the second terminal already had an active, read-allowed file descriptor, it completely bypassed the new write-only permissions. It captured the appended flag in real-time and printed it directly to my screen!

# Conclusion
This challenge was a highly practical demonstration of how Linux handles open file descriptors versus file system permissions. I learned that permissions are enforced at the moment a file is opened, not dynamically during subsequent read or write operations. From a security perspective, it emphasized exactly why developers must securely lock down file permissions *before* writing sensitive data to them or pausing execution. Leaving a time gap—especially an indefinite wait for user input—between file creation and permission restriction opens the door to trivial but devastating TOCTOU exploits.
