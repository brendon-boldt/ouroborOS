    bits 16
    ; Use the dd utility as follows to write to usb drive.
    ; dd if=c:\my files\boot.bin of=\\.\z: bs=512 count=1
    org     0x7c00

start:
    jmp     main

;TIMES 0xb-$+start db 0

bpbOEM                  db 'B. Boldt'
bpbBytesPerSector:  	dw 512
bpbSectorsPerCluster: 	db 1
bpbReservedSectors: 	dw 1
bpbNumberOfFATs: 	    db 2
bpbRootEntries: 	    dw 224
bpbTotalSectors: 	    dw 2880
bpbMedia: 	            db 0xf0
bpbSectorsPerFAT: 	    dw 9
bpbSectorsPerTrack: 	dw 18
bpbHeadsPerCylinder: 	dw 2
bpbHiddenSectors:       dd 0
bpbTotalSectorsBig:     dd 0
bsDriveNumber: 	        db 0
bsUnused: 	            db 0
bsExtBootSignature: 	db 0x29
bsSerialNumber:	        dd 0x160C7E75
bsVolumeLabel: 	        db 'oOS Floppy '
bsFileSystem: 	        db 'FAT12   '

ImageName:
    db 'OKLDR   SYS',0
FATAddress:
    dw  0
DataSector:
    dw  0
SplashStr:
    db 'Searching for image',0x2e,0x2e,0x2e,0xa,0xd,0
PanicStr:
    db '\(;',0x27,'^',0x27,')/',0xa,0xd,0
Cylinder:
    db  0
Head:
    db  0
Sector:
    db  0
ImageCluster:
    dw  0
ImageAddress:
    dw  0

Print:
        push    si
        push    ax
    .loop:
        lodsb
        cmp     al, 0
        je      .done
        mov     ah, 0xe
        int     0x10
        jmp     .loop
    .done:
        pop     ax
        pop     si
        ret

Panic:
        mov     si, PanicStr
        call    Print
        cli
        hlt

; Take LBA in cx, put it into CHS for int 0x13(0x2) ;
LBAtoCHS:
        pusha
        mov     ax, word [bpbHeadsPerCylinder]
        mul     word [bpbSectorsPerTrack]
        mov     bx, ax
        mov     ax, cx
        mul     byte [bpbSectorsPerCluster]
        xor     dx, dx
        div     bx
        mov     [Cylinder], al ; Was ax
        mov     ax, dx
        xor     dx, dx
        div     word [bpbSectorsPerTrack]
        mov     [Head], al ; Was ax
        add     dx, 1 ; Remember, sectors are 1-based
        mov     [Sector], dl ; Was dx
        popa
        mov     ch, byte [Cylinder]
        mov     dh, byte [Head]
        mov     cl, byte [Sector]
        ret

ReadSectors:
        push    di
        mov     di, 5
    .loop:
        call    LBAtoCHS
        mov     ah, 0x0
        mov     dl, 0x0 ; drive 0
        int     0x13
        mov     ah, 0x2 ; int 0x13 function 0x2
        int     0x13
        dec     di
        jz      .done
        jc      .loop
    .done:
        pop     di
        ret

; Convert FAT cluster in cx to LBA in cx for Read Sectors ;
ClustertoLBA:
        push    ax
        mov     ax, cx
        sub     ax, 0x2
        ;imul   byte [bpbSectorsPerCluster] ; Remove if SpC neq 1
        add     ax, word [DataSector]
        mov     cx, ax
        pop     ax
        ret

main:
        xor     ax, ax
        mov     es, ax
        mov     ds, ax

        mov     si, SplashStr
        call    Print

LoadRoot:
        xor     ax, ax
        mov     al, byte [bpbNumberOfFATs]
        mul     word [bpbSectorsPerFAT]
        add     ax, word [bpbReservedSectors]
        mov     cx, ax
        ;       cx contains the LBA
        mov     ax, 0x20
        mul     word [bpbRootEntries]
        div     word [bpbBytesPerSector]
        ;       al(ax) contains how many sectors to read
        ; Staring Address of Data Section ;
        mov     word [DataSector], ax
        add     word [DataSector], cx
        mov     bx, 0x7e00 ; Where the root will be loaded
        call    ReadSectors
        and     ax, 0xff
        mul     word [bpbBytesPerSector]
        add     bx, ax
        mov     word [FATAddress], bx


FindImage:
        mov     cx, word [bpbRootEntries]
        mov     di, 0x7e00 ; Where the root is loaded
    .loop:
        push    cx
        mov     cx, 11
        mov     si, ImageName
        push    di
        repe    cmpsb
        pop     di
        je      LoadFAT
        pop     cx
        add     di, 0x20
        loop    .loop
        jmp     Panic

LoadFAT:
        mov     ax, [di + 0x1a] ; Bytes 26-27 --> First cluster
        mov     word [ImageCluster], ax
        ;       Bytes 28-31 --> File size

        ;mov     ax, 0x20
        ;mul     word [bpbRootEntries]
        ;add     bx, ax

        mov     ax, word [bpbSectorsPerFAT]
        mul     byte [bpbNumberOfFATs]
        mov     cx, word [bpbReservedSectors]
        call    ReadSectors


        mul     word [bpbBytesPerSector]
        mov     bx, 0x500

LoadCluster:
        push    di ; Will hold linked list values
        mov     cx, word [ImageCluster]
        mov     di, cx
        call    ClustertoLBA
        mov     al, 1
        call    ReadSectors
    .loop:
        mov     ax, di
        xor     dx, dx
        mov     cx, 0x3
        mul     cx
        mov     cx, 0x2
        div     cx
        push    bx
        ;add     ax, 0x7e00
        add     ax, word [FATAddress]
        mov     bx, ax
        mov     cx, [bx]
        pop     bx
        test    di, 0x1
        jnz      .odd
    .even:
        and     cx, 0x0fff
        jmp     .done
    .odd:
        shr     cx, 0x4
    .done:
        cmp     cx, 0xff0
        ja      Exit
        mov     di, cx
        call    ClustertoLBA
        mov     al, 1
        add     bx, 0x200
        call    ReadSectors
        jmp     .loop
Exit:
        pop     di
        mov     ax, word [FATAddress]
        mov     bx, word [DataSector]
        jmp     0x500


    times   510-($-$$)  db  0
    dw      0xaa55
