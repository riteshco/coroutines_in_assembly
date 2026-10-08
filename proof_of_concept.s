format ELF64 executable

SYS_read = 0
SYS_write = 1
SYS_exit = 60

STDIN = 0
STDOUT = 1
STDERR = 2

COROUTINES_CAPACITY = 10
STACK_CAPACITY = 1024

segment executable
;; rdi - as input
print:
    mov    r9, -3689348814741910323
    sub    rsp, 40
    mov    BYTE [rsp+31], 10
    lea    rcx, [rsp+30]
.loop:
    mov    rax, rdi
    lea    r8, [rsp+32]
    mul    r9
    mov    rax, rdi
    sub    r8, rcx
    shr    rdx, 3
    lea    rsi, [rdx+rdx*4]
    add    rsi, rsi
    sub    rax, rsi 
    add    eax, 48
    mov    BYTE [rcx], al
    mov    rax, rdi
    mov    rdi, rdx
    mov    rdx, rcx
    sub    rcx, 1
    cmp    rax, 9
    ja     .loop
    lea    rax, [rsp+32]
    mov    edi, 1
    sub    rdx, rax
    xor    eax, eax
    lea    rsi, [rsp+32+rdx]
    mov    rdx, r8
    mov    rax, 1 
    syscall
    add    rsp, 40
    ret

;; rdi - as input
counter:
    push   rbp
    mov    rbp, rsp
    sub    rsp, 8

    mov    QWORD [rbp - 8], 0
    ;;mov    r10, 10

.again:
    cmp    QWORD [rbp - 8], 10
    jge    .over
    mov    rdi, [rbp - 8]
    call   print

    call   coroutine_yield

    inc    QWORD [rbp - 8]
    jmp    .again

.over:
    add    rsp, 8
    pop    rbp
    ret

;; rdi - procedure to start in a new coroutine
coroutine_go:
    cmp    QWORD [ctx_count], COROUTINES_CAPACITY
    jge    overflow_fk
    
    mov    rbx, [ctx_count] ;; rbx contains idx of the curr ctx just allocated
    inc    QWORD [ctx_count]

    mov    rax, [stacks_end] ;; rax contains the rsp of the new routine

    sub    QWORD [stacks_end], STACK_CAPACITY
    sub    rax, 8
    mov    QWORD [rax], coroutine_finish

    mov    [ctx_rsp+rbx*8], rax
    mov    QWORD [ctx_rbp+rbx*8], 0
    mov    [ctx_rip+rbx*8], rdi

    ret

overflow_fk:
    mov    rax, SYS_write
    mov    rdi, STDERR
    mov    rsi, coroutines_overflow_msg
    mov    rdx, coroutines_overflow_msg_len
    syscall

    mov    rax, SYS_exit
    mov    rdi, 69
    syscall

coroutine_yield:
    mov    rbx, [ctx_curr] 
    
    pop    rax                          ;; return addr is in rax now
    mov    [ctx_rsp+rbx*8], rsp
    mov    [ctx_rbp+rbx*8], rbp
    mov    [ctx_rip+rbx*8], rax

    inc    rbx
    xor    rcx, rcx
    cmp    rbx, [ctx_count]
    cmovge rbx, rcx
    mov    [ctx_curr], rbx

    mov    rsp, [ctx_rsp+rbx*8]
    mov    rbp, [ctx_rbp+rbx*8]
    jmp    QWORD [ctx_rip+rbx*8]        ;; as we can't set the instruction pointer (rip) so the equivalent to that is just directing jumping at the address

    ;;ret                               ;; so no need of ret due to the jump instruction above

coroutine_init:
    cmp QWORD [ctx_count], COROUTINES_CAPACITY
    jge overflow_fk

    mov rbx, [ctx_count]                ;; rbx contains idx of the curr ctx just allocated
    inc QWORD [ctx_count]

    pop rax                             ;; return address is in rax now

    mov [ctx_rsp+rbx*8], rax
    mov [ctx_rbp+rbx*8], rbp
    mov [ctx_rip+rbx*8], rax

    jmp rax

coroutine_finish:
    mov    rax, SYS_write
    mov    rdi, STDOUT
    mov    rsi, finish_msg
    mov    rdx, finish_msg_len
    syscall

    mov    rax, SYS_exit
    mov    rdi, 0
    syscall

entry _start
_start:
    call coroutine_init

    mov rdi, counter
    call coroutine_go

    mov rdi, counter
    call coroutine_go

    ;;mov    rax, SYS_write
    ;;mov    rdi, STDOUT
    ;;mov    rsi, ok
    ;;mov    rdx, ok_len
    ;;syscall

.forever:
    call   coroutine_yield
    jmp .forever
    
    mov    rdi, [ctx_count]
    call   print

    ;;mov    rdi, 10
    ;;call   counter
    ;;mov    rdi, 5 
    ;;call   counter
   
    mov    rax, SYS_exit
    mov    rdi, 0 
    syscall

segment readable
coroutines_overflow_msg: db "nahhh! Too many coroutines bruh", 0, 10
coroutines_overflow_msg_len = $-coroutines_overflow_msg
ok: db "ok", 0, 10
ok_len = $-ok
finish_msg: db "TODO: Coroutine finish not implemented!", 0, 10
finish_msg_len = $-finish_msg

segment readable writable
ctx_curr:   dq 0
stacks_end: dq stacks+COROUTINES_CAPACITY*STACK_CAPACITY 
stacks:     rb COROUTINES_CAPACITY*STACK_CAPACITY
ctx_rsp:    rq COROUTINES_CAPACITY
ctx_rbp:    rq COROUTINES_CAPACITY
ctx_rip:    rq COROUTINES_CAPACITY
ctx_count:  rq 1
