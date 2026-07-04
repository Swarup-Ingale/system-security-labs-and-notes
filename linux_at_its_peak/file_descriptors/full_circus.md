# File Descriptor Exhaustion (The Sold Out Night)

# Concept
When analyzing the `.init` and `chal.c` files, two massive hints immediately caught my attention: the challenge description mentioning a "sold out night" (meaning all seats, or resources, are taken) and the fact that the binary is compiled statically (`gcc -static`). 

The `chal.c` code operates in three steps:
1. It tries to open `/flag` with `O_TRUNC|O_WRONLY` (which immediately empties the file).
2. It writes "NO FLAG FOR YOU" to the open file descriptor (`fd`).
3. It changes the permissions of `/flag` to `0644` (world-readable) using the string path.

The vulnerability lies in the lack of error handling. The program assumes `open()` will always succeed. But what happens if the operating system denies the `open()` request? The function will fail and return `-1`. Consequently, the file is *never truncated*, and the subsequent `write(-1, ...)` operation fails silently in the background. However, the program keeps running and executes the final `chmod("/flag", 0644)` as a root SUID process, graciously making the intact flag readable to me!

So, how do I force `open()` to fail? By exhausting the process's File Descriptors (FDs). A Linux process can only have a certain number of files open at a time. If I restrict the maximum number of FDs to exactly 3, the process will consume them on standard input (FD 0), standard output (FD 1), and standard error (FD 2). When the program tries to open `/flag`, there will be no FDs left, and the call will fail. 

This is also exactly why the binary was compiled statically. If it were dynamically linked, the program would crash before `main()` even started because it wouldn't have any spare FDs to open and load shared libraries like `libc.so`!

# Method of Solve
To exploit this missing error check and exhaust the file descriptors, I utilized a subshell and the `ulimit` command. Here are the exact steps I took:

1. **Restricting File Descriptors:** I needed to run the challenge binary in an environment where it was only allowed to have 3 open file descriptors. Instead of permanently breaking my current shell's limits, I wrapped the execution in a subshell.
   ```bash
   (ulimit -n 3; /challenge/chal)
   ```
2. **The Silent Failure:** Under the hood, the restricted environment worked flawlessly. The chal binary ran, and when it hit the open("/flag") line, the operating system refused to grant it a 4th file descriptor. Because open() failed, the flag was protected from being truncated (O_TRUNC). The script then happily executed chmod("/flag", 0644), unlocking the file for everyone.
3. **Capturing the Flag:** Because I ran the limit restriction in a subshell (...), my main terminal's file descriptor limits remained normal. This allowed me to easily read the newly unlocked flag using the standard cat command:
  ```bash
  /flag
  ```

# Conclusion

This challenge was a brilliant demonstration of resource exhaustion and the critical importance of handling system call return values. I learned that just because a script has root privileges doesn't mean its system calls are guaranteed to succeed; external resource limits imposed by the user can alter the execution flow drastically. By failing to verify if fd != -1 before proceeding, the program unwittingly acted as a confused deputy, protecting the file from its own destructive instructions while still executing the permission change that allowed me to capture the flag.
