global movLoop
global nop3x1Loop
global nop1x3Loop
global nop1xNLoop
global cmpLoop
global decLoop
global jumpyLoop

section .text

movLoop:
    xor rax, rax
.loop:
    mov [rdx + rax], al
    inc rax
    cmp rax, rcx
    jb .loop
    ret

nop3x1Loop:
    xor rax, rax
.loop:
    db 0x0f, 0x1f, 0x00 ; 3-byte nop
    inc rax
    cmp rax, rcx
    jb .loop
    ret

nop1x3Loop:
    xor rax, rax
.loop:
    nop
    nop
    nop
    inc rax
    cmp rax, rcx
    jb .loop
    ret

nop1xNLoop:
    xor rax, rax
.loop:
    ; 12 1-byte nops here
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc rax
    cmp rax, rcx
    jb .loop
    ret

cmpLoop:
    xor rax, rax
.loop:
    inc rax
    cmp rax, rcx
    jb .loop
    ret

decLoop:
.loop:
    dec rcx
    jnz .loop
    ret

jumpyLoop:
    xor rax, rax
.loop:
    mov bl, [rdx + rax]
    test bl, bl
    jz .skip
    nop
    nop
    nop
.skip:
    inc rax
    cmp rax, rcx
    jb .loop
    ret
