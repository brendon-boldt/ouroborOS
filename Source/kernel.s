%define VIDMEM 0xb8000

    bits 32

        jmp     _main

times   0x400   db  0

ClearScreen:
        pusha
        mov     dx, 0x3d4
        mov     al, 0xe
        out     dx, al
        xor     al, al
        inc     dx
        out     dx, al
        mov     dx, 0x3d4
        mov     al, 0xf
        out     dx, al
        xor     al, al
        inc     dx
        out     dx, al

        mov     ah, 0xa
        mov     al, 221
    .two:
        mov     edi, VIDMEM ; Define this
        mov     ecx, 2000
        rep     stosw

;jmp .comment

        inc     ah
    .one:
        ;rep     stosw
        inc     ah
        and     ah, 0xf
        stosw
        loop    .one

        mov     ecx, 0;0xfffff
    .nop:
        nop
        loop    .nop
        jmp     .two

.comment:

        popa
        ret

_main:
        call    ClearScreen

        hlt

times   ($-$$)% 4    db  0
