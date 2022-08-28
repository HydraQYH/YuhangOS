%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

; Create GDT
GDT_BASE:
    dd 0x00000000
    dd 0x00000000   ; 第一个段描述符为无效描述符
CODE_DESC:
    dd 0x0000FFFF
    dd DESC_CODE_HIGH4
DATA_STACK_DESC:
    dd 0x0000FFFF
    dd DESC_DATA_HIGH4
VIDEO_DESC:
    dd 0x80000007
    dd DESC_VIDEO_HIGH4

GDT_SIZE equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1
times 60 dq 0   ; 预留60个段描述符的空间
SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0

; 前面64个段描述符 512字节 0x200
total_mem_bytes:
    dd 0    ; 地址0x900 + 0x200 = 0xb00

gdt_ptr:
    dw GDT_LIMIT
    dd GDT_BASE

ards_buf:
    times 244 db 0
ards_nr:
    dw 0

; 地址 0xb00 + 4(total_mem_bytes) + 2(GDT_LIMIT) + 4(GDT_BASE) + 244(ards_buf) + 2(ards_nr)
; 0xb00 + 0x100 = 0xc00
loader_start:
    xor ebx, ebx    ; ebx清零
    mov edx, 0x534d4150
    mov di, ards_buf
.e820_mem_get_loop:
    mov eax, 0x0000e820
    mov ecx, 20  ; ards描述符大小为20字节
    int 0x15
    ; TODO: 判断flag 进行跳转
    ; 当前默认该BIOS中断可以成功
    add di, cx
    inc word [ards_nr]
    cmp ebx, 0
    jnz .e820_mem_get_loop

    ; 获取了所有的ards结构
    mov cx, [ards_nr]
    mov ebx, ards_buf
    xor edx, edx    ; edx用来存储最大值
.find_max_mem_area:
    mov eax, [ebx]  ; 基址
    add eax, [ebx + 8]  ; 界限
    add ebx, 20
    cmp edx, eax
    jge .next_ards  ; edx >= eax时跳转 不会将eax值赋给edx
    mov edx, eax
.next_ards:
    loop .find_max_mem_area

.mem_get_ok:
    mov [total_mem_bytes], edx

; CPU进入保护模式
    in al, 0x92
    or al, 00000010b
    out 0x92, al
    ; 加载gdt到gdt寄存器
    lgdt [gdt_ptr]
    ; cr0
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start
[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

    mov byte [gs:160], 'P'  ; 验证进入了保护模式
    
    ; 将内核文件加载至0x70000处
    mov eax, KERNEL_START_SECTOR
    mov ebx, KERNEL_BIN_BASE_ADDR
    mov ecx, 200
    call rd_disk_m_32

    call setup_page ; 设置页目录表和部分页表

    sgdt [gdt_ptr]

    mov ebx, [gdt_ptr + 2]  ; ebx为GDT起始地址
    or dword [ebx + 0x18 + 4], 0xc0000000   ; 定位到第4个段描述符的高4字节

    add dword [gdt_ptr + 2], 0xc0000000 ; 将GDT基址设置为虚拟地址空间中的对应位置

    add esp, 0xc0000000

    mov eax, PAGE_DIR_TABLE_POS
    mov cr3, eax

    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    lgdt [gdt_ptr]

    jmp SELECTOR_CODE:enter_kernel  ; 强制再次刷新CPU流水线

enter_kernel:
    mov byte [gs:162], 'V'  ; 验证开启了页表
    mov byte [gs:240], 'K'
    mov byte [gs:242], 'e'
    mov byte [gs:244], 'r'
    mov byte [gs:246], 'n'
    mov byte [gs:248], 'e'
    mov byte [gs:250], 'l'
    call kernel_init
    mov esp, 0xc009f000
    jmp KERNEL_ENTRY_POINT

setup_page:
; 将页目录表的存储空间清零
    mov ecx, 4096
    mov esi, 0
.clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS + esi], 0
    inc esi
    loop .clear_page_dir

; 创建页目录项
.create_pde:
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x1000   ; 第一个页表的物理地址
    mov ebx, eax

    or eax, PG_US_U | PG_RW_W | PG_P    ; 设置第一个页表的属性
    mov [PAGE_DIR_TABLE_POS], eax   ; 第1项映射到第一个页表
    mov [PAGE_DIR_TABLE_POS + 0xc00], eax   ; 第768项映射到第一个页表

    sub eax, 0x1000 ; eax为页目录表地址
    mov [PAGE_DIR_TABLE_POS + 4092], eax

; 创建页表项 第一个页表前256项 对应物理地址0-1MB
    mov ecx, 256
    mov esi, 0
    mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
    mov [ebx + esi * 4], edx
    add edx, 4096
    inc esi
    loop .create_pte

; 内核空间占用0-4GB的高1GB的地址空间 将高1GB的地址空间对应的页目录表项提前创建好
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x2000 ; 第二个页表的地址
    or eax, PG_US_U | PG_RW_W | PG_P
    mov ebx, PAGE_DIR_TABLE_POS
    mov ecx, 254
    mov esi, 769
.create_kernel_pde:
    mov [ebx + esi * 4], eax
    inc esi
    add eax, 0x1000
    loop .create_kernel_pde
    ret


; 保护模式的硬盘读取函数
rd_disk_m_32:
    mov esi, eax
    mov di, cx

    mov dx, 0x1f2
    mov al, cl
    out dx, al

    mov eax, esi

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
    out dx, al

.not_ready:
    nop
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .not_ready

    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax
    mov dx, 0x1f0

.go_on_read:
    in ax, dx
    mov [ebx], ax
    add ebx, 2
    loop .go_on_read
    ret

kernel_init:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

    mov dx, [KERNEL_BIN_BASE_ADDR + 42] ; 每个segment header的大小
    mov ebx, [KERNEL_BIN_BASE_ADDR + 28]    ; segment header数组的偏移地址
    add ebx, KERNEL_BIN_BASE_ADDR
    mov cx, [KERNEL_BIN_BASE_ADDR + 44] ; segment header的数量

.each_segment:
    cmp byte [ebx + 0], PT_NULL
    je .PTNULL

    push dword [ebx + 16]   ; segment的大小

    mov eax, [ebx + 4]  ; segment在文件中偏移
    add eax, KERNEL_BIN_BASE_ADDR   ; segment在内存中的地址
    push eax

    push dword [ebx + 8]    ; 目标地址

    call mem_cpy

    add esp, 12

.PTNULL:
    add ebx, edx
    loop .each_segment
    ret


mem_cpy:
    cld
    push ebp
    mov ebp, esp
    push ecx

    mov edi, [ebp + 8]
    mov esi, [ebp + 12]
    mov ecx, [ebp + 16]
    rep movsb

    pop ecx
    pop ebp
    ret

