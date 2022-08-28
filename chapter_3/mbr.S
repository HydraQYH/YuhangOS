SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax  ; 设置显存段基址

; 清屏
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0
    mov dx, 0x184f

    int 0x10

; 获取光标
    mov ah, 3
    mov bh, 0

    int 0x10

; 打印字符串
    mov byte [gs:0x00], 'Y'
    mov byte [gs:0x01], 0xA4

    mov byte [gs:0x02], 'u'
    mov byte [gs:0x03], 0xA4

    mov byte [gs:0x04], 'H'
    mov byte [gs:0x05], 0xA4

    mov byte [gs:0x06], 'a'
    mov byte [gs:0x07], 0xA4

    mov byte [gs:0x08], 'n'
    mov byte [gs:0x09], 0xA4

    mov byte [gs:0x0A], 'g'
    mov byte [gs:0x0B], 0xA4

; CPU 悬挂
    jmp $

    times 510-($-$$) db 0
    db 0x55, 0xaa