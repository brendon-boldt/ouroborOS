ouroborOS
=========

Assembly Bootloader

This is a FAT12 bootsector/bootloader pair written using NASM. Currently there is a kernel stub for the sake giving the bootloader something to load. Nota bene, code for enabling the A20 line is in place, but has not been tested due to the emulator used (Bochs).

Software Used:
- NASM
- Bochs
- Virtual Floppy Disk
- dd Clone (for Windows users)
