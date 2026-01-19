## Low-Level HTTP Server Development Notes (x86_64 Assembly)

This repository contains concise, step-by-step notes documenting the process of building a minimal HTTP web server in x86_64 Linux assembly using raw system calls.

The focus is on understanding how web servers work internally, including networking, HTTP parsing, process management, and security implications.

---

## Topics Covered

1. Linux syscall interface (x86_64)
2. Process lifecycle and exit syscall
3. TCP socket creation, binding, listening, and accepting connections
4. HTTP request structure and parsing
5. Static and dynamic HTTP responses
6. GET request handling (file serving)
7. POST request handling (request body extraction)
8. Multi-client handling using fork()
9. File descriptor management across processes
10. Common security risks in low-level servers

---

## Key System Calls Explained

socket, bind, listen, accept

read, write, open, close

fork, exit

**Each syscall is documented with its purpose and role in the server.**

---

## Learning Progression

1. Understanding Linux system calls
2. Creating a TCP server
3. Handling client connections
4. Sending static HTTP responses
5. Parsing HTTP requests
6. Building **GET** and **POST** handlers
7. Supporting multiple clients using **fork()**
8. Combining all components into a working web server

---

## License

**MIT License — free to use for learning and research.**

---

This repository contains documentation and learning notes only.
The actual server implementation is available in the companion repository:

**Minimal HTTP GET & POST Server in x86_64 Assembly**

---

## Reference

**◘ https://github.com/Swarup-Ingale/asm-http-server**
