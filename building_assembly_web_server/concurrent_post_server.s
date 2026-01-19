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

		mov r15, rax
		lea r14, [rip+request_buf]

		lea rsi, [rip+request_buf]
		
		skip_method:
			mov al, byte ptr [rsi]
			cmp al, ' '
			je skip_method_done
			cmp al, 0
			je skip_method_done
			inc rsi
			jmp skip_method
	
		skip_method_done:
			inc rsi

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
		mov rsi, 65
		mov rdx, 0777
		syscall

		mov r13, rax

		mov rbx, r14
		xor rcx, rcx

		find_body:
        		cmp rcx, r15
        		jge no_body               
				
			mov al, byte ptr [rbx+rcx]

		        cmp al, 13                          ;'\r' 
        		jne next_char
        		cmp byte ptr [rbx+rcx+1], 10        ;'\n'
        		jne next_char
        		cmp byte ptr [rbx+rcx+2], 13        ;'\r' 
        		jne next_char
        		cmp byte ptr [rbx+rcx+3], 10        ;'\n'
        		jne next_char

       			add rcx, 4                          ; skip "\r\n\r\n"
        		jmp body_found

		next_char:
        		inc rcx
        		jmp find_body

		no_body:
        		lea rsi, [rbx]          
        		xor rdx, rdx
        		jmp do_write

		body_found:
       			lea rsi, [rbx+rcx]          ; rsi = body_ptr
       			mov rdx, r15                ; rdx = total_len
        		sub rdx, rcx                ; body_len = total_len - header_len

		do_write:
       			mov rax, 1               
        		mov rdi, r13              
        		
        		syscall

        		mov rax, 3               
        		mov rdi, r13
        		syscall

		mov rax, 1
		mov rdi, r12
		lea rsi, [rip+response]
		mov rdx, 19
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