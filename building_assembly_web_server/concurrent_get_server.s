.intel_syntax noprefix
.global _start

.section .text

_start:
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall

mov rbx, rax

mov rax, 49
mov rdi, rbx
lea rsi, [rip+sockaddr]
mov rdx, 16
syscall

mov rax, 50
mov rdi, rbx
mov rsi, 0
syscall

server_loop:

	mov rax, 43
	mov rdi, rbx
	xor rsi, rsi
	xor rdx, rdx
	syscall

	mov r12, rax
	
	mov rax, 57
	syscall

	cmp rax, 0
	je child_path

	parent_path:
		mov rax, 3
        	mov rdi, r12
        	syscall
		
		jmp server_loop
	
	child_path:
		mov rax, 3
		mov rdi, rbx
		syscall

		mov rax, 0
		mov rdi, r12
		lea rsi, [rip+request_buf]
		mov rdx, 1024
		syscall

		lea rsi, [rip+request_buf]
		add rsi, 4 
	
		mov r13, rsi

		parse_path_loop:
			mov al, byte ptr [rsi]
			cmp al, ' '
			je  parse_path_done
			cmp al, 0 
			je  parse_path_done
			inc rsi
			jmp parse_path_loop

		parse_path_done:
			mov byte ptr [rsi], 0
	
		mov rax, 2
		mov rdi, r13
		mov rsi, 0
		mov rdx, 0
		syscall

		mov r13, rax

		mov rax, 0
		mov rdi, r13
		lea rsi, [rip+file_buf]
		mov rdx, 4096
		syscall

		mov r14, rax

		mov rax, 3
		mov rdi, r13
		syscall


		mov rax, 1
		mov rdi, r12
		lea rsi, [rip+response]
		mov rdx, 19
		syscall

		mov rax, 1
		mov rdi, r12
		lea rsi, [rip+file_buf]
		mov rdx, r14 
		syscall

		mov rax, 3
		mov rdi, r12
		syscall
	
		mov rdi, 0
		mov rax, 60
		syscall

.section .data
sockaddr:
	.word 2
	.word 0x5000
	.long 0
	.quad 0

response:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"

.section .bss
request_buf:
	.zero 1024
file_buf:
	.zero 4096