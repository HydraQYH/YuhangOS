TI_GDT equ 0
RPL0 equ 0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0

[bits 32]
section .data
put_int_buffer dq 0

section .text   ; 代码段
global put_char ; 导出put_char作为全局符号
put_char:
    pushad
    mov ax, SELECTOR_VIDEO
    mov gs, ax  ; 发生特权级检查
; 获取光标位置
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    in al, dx  ; 读取高8位放在al内部
    mov ah, al  ; 将高8位移到ah中

    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    in al, dx  ; 读取低8位放在al内部
; 此时ax为光标地址
    mov bx, ax
    mov ecx, [esp + 36] ; 将待打印内容放到cl中
    ; TODO 条件判断 一处理常规字符和控制字符

    cmp cl, 0xd
    jz .is_carriage_return

    cmp cl, 0xa
    jz .is_line_feed

    cmp cl, 0x8
    jz .is_backspace

    jmp .put_other


.is_backspace:
    dec bx  ; 光标坐标-1
    shl bx, 1
    mov byte [gs:bx], 0x20
    inc bx
    mov byte [gs:bx], 0x07
    shr bx, 1
    jmp .set_cursor

.put_other:
    shl bx, 1
    mov byte [gs:bx], cl
    inc bx
    mov byte [gs:bx], 0x07
    shr bx, 1
    inc bx
    cmp bx, 2000
    jl .set_cursor

.is_line_feed:
.is_carriage_return:
    xor dx, dx
    mov ax, bx
    mov si, 80
    div si
    ; 此时dx为余数
    sub bx, dx  ; 此时光标位置为当前行行首
.is_carriage_return_end:
    add bx, 80  ; 将光标移动到下一行行首
    cmp bx, 2000
.is_line_feed_end:
    jl .set_cursor


.roll_screen:
    ; cld
    mov ecx, 960
    mov esi, 0xc00b80a0
    mov edi, 0xc00b8000
.roll_screen_loop:
; 将1~24行移动到0~23行
    ; mov eax, [esi]
    ; mov [edi], eax
    ; add esi, 4
    ; add edi, 4
    ; loop .roll_screen_loop
    rep movsd

    mov ebx, 3840   ; 3840是最后一行的缓冲区地址
    mov ecx, 80
.cls:
    mov word [gs:ebx], 0x0720
    add ebx, 2
    loop .cls
    mov bx, 1920

put_char.set_cursor:
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    mov al, bh
    out dx, al  ; 光标坐标高8位

    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    mov al, bl
    out dx, al  ; 光标坐标高8位
.put_char_done:
    popad
    ret

global put_str
put_str:
    push ebx
    push ecx
    xor ecx, ecx
    mov ebx, [esp + 12]
.goon:
    mov cl, [ebx]   ; cl中存储待打印字符
    cmp cl, 0
    jz .str_over
    push ecx
    call put_char
    add esp, 4  ; 由调用者清理栈空间(push ecx占4字节)
    inc ebx
    jmp .goon

.str_over:
    pop ecx
    pop ebx
    ret

global put_int
put_int:
    pushad
    mov ebp, esp    ; 更新栈帧指针
    mov eax, [ebp + 4 * 8 + 4]  ; 8个寄存器外加一个返回地址
    mov edx, eax
    mov edi, 7
    mov ecx, 8
    mov ebx, put_int_buffer

.based_4bits:
    and edx, 0x0000000F ; 取低4位

    cmp edx, 9
    jg .is_A2F
    add edx, '0'    ; 0~9
    jmp .store

.is_A2F:
    sub edx, 10
    add edx, 'A'

.store:
    mov [ebx + edi], dl
    dec edi
    shr eax, 4
    mov edx, eax
    loop .based_4bits

.ready_to_print:
    ; .based_4bits循环结束时 edi位-1(0xFFFFFFFF)
    inc edi
.skip_prefix_0:
    cmp edi, 8
    je .full0

.go_on_skip:
    mov cl, [ebx + edi]  ; 也可以直接用ebx代替put_int_buffer
    inc edi
    cmp cl, '0'
    je .skip_prefix_0
    dec edi
    jmp .put_each_num

.full0:
    mov cl, '0'

.put_each_num:
    push ecx
    call put_char
    add esp, 4
    inc edi
    mov cl, [ebx + edi]
    cmp edi, 8
    jl .put_each_num
    popad
    ret

