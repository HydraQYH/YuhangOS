[bits 32]
section .text
global switch_to
switch_to:
    push esi
    push edi
    push ebx
    push ebp

    mov eax, [esp + 20]  ; cur PCB
    mov [eax], esp  ; cur PCB.self_kstack

    mov eax, [esp + 24]  ; next PCB
    mov esp, [eax]  ; 切换到next的self_kstack
    pop ebp
    pop ebx
    pop edi
    pop esi
    ret
