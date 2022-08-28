[bits 32]
%define ERROE_CODE nop
%define ZERO push 0

extern idt_table

section .data
global intr_entry_table
intr_entry_table:

%macro VECTOR 2
section .text
intr%1entry:

    %2
    push ds
    push es
    push fs
    push gs
    pushad
    ; 手动结束中断
    mov al, 0x20
    out 0xa0, al
    out 0x20, al

    push %1
    call [idt_table + %1 * 4]
    jmp intr_exit

section .data
    dd intr%1entry

%endmacro

section .text
global intr_exit
intr_exit:
    add esp, 4  ; 跳过压入栈中的中断向量
    popad
    pop gs
    pop fs
    pop es
    pop ds
    add esp, 4  ; 跳过ERROR_CODE或0
    iret

VECTOR 0x00,ZERO
VECTOR 0x01,ZERO
VECTOR 0x02,ZERO
VECTOR 0x03,ZERO
VECTOR 0x04,ZERO
VECTOR 0x05,ZERO
VECTOR 0x06,ZERO
VECTOR 0x07,ZERO
VECTOR 0x08,ERROE_CODE
VECTOR 0x09,ZERO
VECTOR 0x0A,ERROE_CODE
VECTOR 0x0B,ERROE_CODE
VECTOR 0x0C,ERROE_CODE
VECTOR 0x0D,ERROE_CODE
VECTOR 0x0E,ERROE_CODE
VECTOR 0x0F,ZERO
VECTOR 0x10,ZERO
VECTOR 0x11,ERROE_CODE
VECTOR 0x12,ZERO
VECTOR 0x13,ZERO
VECTOR 0x14,ZERO
VECTOR 0x15,ZERO
VECTOR 0x16,ZERO
VECTOR 0x17,ZERO
VECTOR 0x18,ZERO
VECTOR 0x19,ZERO
VECTOR 0x1A,ZERO
VECTOR 0x1B,ZERO
VECTOR 0x1C,ZERO
VECTOR 0x1D,ZERO
VECTOR 0x1E,ERROE_CODE
VECTOR 0x1F,ZERO
VECTOR 0x20,ZERO
