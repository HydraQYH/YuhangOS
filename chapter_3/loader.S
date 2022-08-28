%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR

    mov byte [gs:0x10], '-'
    mov byte [gs:0x11], 0xA4

    mov byte [gs:0x12], 'L'
    mov byte [gs:0x13], 0xA4

    mov byte [gs:0x14], 'o'
    mov byte [gs:0x15], 0xA4

    mov byte [gs:0x16], 'a'
    mov byte [gs:0x17], 0xA4

    mov byte [gs:0x18], 'd'
    mov byte [gs:0x19], 0xA4

    mov byte [gs:0x1A], 'e'
    mov byte [gs:0x1B], 0xA4

    mov byte [gs:0x1C], 'r'
    mov byte [gs:0x1D], 0xA4

    jmp $

