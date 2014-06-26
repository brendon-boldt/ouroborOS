%define VIDMEM 0xb8000

    org     0x500
    jmp     _main

%include 'fat12.si'

    bits 16

GDTptr:
    dw      0x0 ; Size of GDT - 1
    dd      0x0 ; Base address of GDT
GDT:
    ; Null Descriptor ;
    dd      0x0 ; Why not dq 0x0?
    dd      0x0
    ; Kernel Code Descriptor ;
    dw      0xffff      ; Limit low
    dw      0x0         ; Base low
    db      0x0         ; Base Middle
    db      0b10011010  ; Access
    db      0b11001111  ; Granularity
    db      0x0         ; Base High
    ; Kernel Data Descriptor ;
    dw      0xffff      ; Limit Low
    dw      0x0         ; Base Low
    db      0x0         ; Base Middle
    db      0b10010010  ; Access ; To make R3 0b11110010
    db      0b11001111  ; Granularity
    db      0x0         ; Base High
GDTend:

ImageName:
    db  'KERNEL  SYS'
LdrString:
    db  'Loading kernel',0x2e,0x2e,0x2e,0xa,0xd,0
ImageAddress:
    dw  0
KernelSize:
    dd  0

RealPrint:
        pusha
    .loop:
        lodsb
        cmp     al, 0
        je      .done
        mov     ah, 0xe
        int     0x10
        jmp     .loop
    .done:
        popa
        ret

ClearScreen:
    bits 32
        push    edi
        push    eax
        push    ecx
        mov     edi, VIDMEM
        mov     al, 0x20
        mov     ecx, 25*80
        rep     stosw
        pop     ecx
        pop     eax
        pop     edi
        ret
    bits 16


WaitInput:
        in      al, 0x64
        test    al, 0x1
        jz      WaitInput
        ret

_main:
        mov     word [FATAddress], ax
        mov     word [DataSector], bx

        ; Do I need to cli here?
        cli
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ax, 0x9000
        mov     ss, ax
        mov     sp, 0xffff

        mov     si, LdrString
        call    RealPrint

        mov     di, 0x7e00 ; Where the root is loaded
        mov     si, ImageName
        call    FindImage
        mov     eax, dword [di+0x1c]
        mov     dword [KernelSize], eax

        xor     ax, ax
        mov     al, byte [bpbNumberOfFATs]
        mul     word [bpbSectorsPerFAT]
        mul     word [bpbBytesPerSector]
        add     ax, word [FATAddress]
        mov     word [ImageAddress], ax
        mov     bx, ax

        call    LoadFile


SetGDT:
        xor     eax, eax
        add     eax, GDT
        mov     [GDTptr+0x2], eax
        mov     eax, GDTend
        sub     eax, GDT
        sub     eax, 1
        mov     [GDTptr], ax

        cli
        lgdt    [GDTptr]

SetProtected:
        mov     eax, cr0
        or      eax, 0x1
        mov     cr0, eax
        jmp     0x8:FarJump

FarJump:

    bits 32

        mov     ax, 0x10
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     esp, 0x90000

EnableA20:
        mov     al, 0xdd
        out     0x64, al
        ; This should enable A20, but I cannot figure out if it does. ;

; Copy Kernel to 1 MiB ;
CopyKernel:
        xor     edx, edx
        mov     esi, edx
        mov     si, word [ImageAddress]
        mov     eax, 0x10000
        mov     edi, eax
        mov     eax, dword [KernelSize]
        mov     ebx, 4
        div     ebx
        mov     ecx, eax
        inc     ecx
    .loop:
        lodsd
        stosd
        loop    .loop

ExecuteKernel:
        jmp     0x10000
        hlt
