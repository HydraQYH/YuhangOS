#ifndef _KERNEL_INTERRUPT_H_
#define _KERNEL_INTERRUPT_H_

typedef void* intr_handler;

void idt_init();

#endif