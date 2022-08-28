#include "process.h"
#include "thread.h"
#include "memory.h"
#include "global.h"
#include "debug.h"
#include "tss.h"
#include "console.h"
#include "string.h"
#include "interrupt.h"
#include "list.h"

extern void int_exit(void);
extern struct list thread_ready_list;
extern struct list thread_all_list;

void start_process(void* filename_) {
    // start_process是由switch_to调用的
    // 它在整个进程的生命周期中仅仅调用一次
    // 调用start_process时，PCB中的self_kstack指向thread_stack（不过此时esp已经跳过thread_stack指向intr_stack）
    void* function = filename_;
    struct task_struct* cur = running_thread();
    cur->self_kstack += sizeof(struct thread_stack);
    struct intr_stack* proc_stack = (struct intr_stack*)cur->self_kstack;
    proc_stack->edi = 0;
    proc_stack->esi = 0;
    proc_stack->ebp = 0;
    proc_stack->esp_dummy = 0;
    proc_stack->ebx = 0;
    proc_stack->edx = 0;
    proc_stack->ecx = 0;
    proc_stack->eax = 0;
    proc_stack->gs = 0;
    proc_stack->ds = SELECTOR_U_DATA;
    proc_stack->eip = function;
    proc_stack->cs = SELECTOR_U_CODE;
    proc_stack->eflags = (EFLASG_IOPL_0 | EFLAGS_MBS | EFLAGS_IF_1);
    proc_stack->esp = (void*)((uint32_t)get_a_page(PF_USER, USER_STACK3_VADDR) + PG_SIZE);
    proc_stack->ss = SELECTOR_U_DATA;
    // 将esp指向intr_stack并jmp到中断返回过程返回
    asm volatile ("movl %0, %%esp\n jmp intr_exit" : : "g" (proc_stack) : "memory");
}

void page_dir_activate(struct task_struct* p_thread) {
    uint32_t pagedir_phy_addr = 0x100000;
    if (p_thread->pgdir != NULL) {
        pagedir_phy_addr = addr_v2p((uint32_t)p_thread->pgdir);
    }
    asm volatile ("movl %0, %%cr3" : : "r" (pagedir_phy_addr) : "memory");
}

void process_activate(struct task_struct* p_thread) {
    ASSERT(p_thread != NULL);
    page_dir_activate(p_thread);    // 无论是用户进程还是内核线程都需要切换到对应的页表上
    if (p_thread->pgdir) {
        update_tss_esp(p_thread);   // 更新0特权级下的栈
        // tss中的0特权级栈仅在从3特权级进入0特权级时使用
        // 若将被调度执行的用户进程本就处于内核态下处理某些任务
        // 更新tss也不会影响它所使用的0特权级栈指针esp
    }
}

uint32_t* create_page_dir(void) {
    uint32_t* page_dir_vaddr = get_kernel_pages(1);
    if (page_dir_vaddr == NULL) {
        console_put_str("create_page_dir: get_kernel_page failed!");
        return NULL;
    }

    memcpy((uint32_t*)((uint32_t)page_dir_vaddr + 0x300 * 4),
    (uint32_t*)(0xfffff000 + 0x300 * 4), 1024);

    uint32_t new_page_dir_phy_addr = addr_v2p((uint32_t)page_dir_vaddr);
    page_dir_vaddr[1023] = new_page_dir_phy_addr| PG_US_U | PG_RW_W | PG_P_1;
    return page_dir_vaddr;
}

void create_user_vaddr_bitmap(struct task_struct* user_prog) {
    user_prog->userprog_vaddr.vaddr_start = USER_VADDR_START;
    // (0xc0000000 - USER_VADDR_START) 虚拟地址空间总大小
    // (0xc0000000 - USER_VADDR_START) / PG_SIZE 虚拟地址空间总页数
    // (0xc0000000 - USER_VADDR_START) / PG_SIZE / 8 表示虚拟地址空间的bitmap的大小（以字节为单位）
    uint32_t bitmap_pg_cnt = DIV_ROUND_UP((0xc0000000 - USER_VADDR_START) / PG_SIZE / 8, PG_SIZE);

    user_prog->userprog_vaddr.vaddr_bitmap.bits = get_kernel_pages(bitmap_pg_cnt);
    user_prog->userprog_vaddr.vaddr_bitmap.btmp_bytes_len = (0xc0000000 - USER_VADDR_START) / PG_SIZE / 8;

    bitmap_init(&user_prog->userprog_vaddr.vaddr_bitmap);
}

void process_execute(void* filename, char* name) {
    struct task_struct* pcb = get_kernel_pages(1);  // 申请用户进程PCB存储空间
    
    init_thread(pcb, name, default_prio);   // 填写PCB信息

    create_user_vaddr_bitmap(pcb);

    thread_create(pcb, start_process, filename);    // 调度时，通过switch_to调用start_process

    pcb->pgdir = create_page_dir();

    enum intr_status old_status = intr_disable();

    ASSERT(!elem_find(&thread_ready_list, &pcb->general_tag));
    list_append(&thread_ready_list, &pcb->general_tag);

    ASSERT(!elem_find(&thread_all_list, &pcb->all_list_tag));
    list_append(&thread_all_list, &pcb->all_list_tag);

    intr_set_status(old_status);
}
