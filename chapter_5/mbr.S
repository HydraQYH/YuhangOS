%include "boot.inc"
SECTION MBR vstart=0x7c00
    mov ax, cs  ; 全部设置为0
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

    mov byte [gs:0x0C], 'O'
    mov byte [gs:0x0D], 0xA4

    mov byte [gs:0x0E], 'S'
    mov byte [gs:0x0F], 0xA4

    mov eax, LOADER_START_SECTOR
    mov bx, LOADER_BASE_ADDR
    mov cx, 4
    ; 读取磁盘内容到LOADER_BASE_ADDR(0x900)
    call rd_disk_m_16
    jmp LOADER_BASE_ADDR + 0x300

rd_disk_m_16:
    mov esi, eax
    mov di, cx

    ; 设置读取的扇区数量
    mov dx, 0x1f2
    mov al, cl
    out dx, al
    
    mov eax, esi

    ; 设置LBA地址
    mov dx, 0x1f3
    out dx, al

    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al

    shr eax, cl
    mov dx, 0x1f5
    out dx, al

    shr eax, cl
    and al, 0x0f
    or al, 0xe0
    mov dx, 0x1f6
    out dx, al

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al  ; 写入读命令 硬盘开始工作

.not_ready:
    nop
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .not_ready  ; 轮询标志位 查看硬盘是否已经完成读取数据

    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax

    mov dx, 0x1f0
.go_on_read:
    in ax, dx
    mov [bx], ax
    add bx, 2
    loop .go_on_read
    ret

times 510-($-$$) db 0
db 0x55, 0xaa

