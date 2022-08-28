#include "print.h"
#include "init.h"
#include "debug.h"
#include "memory.h"
#include "interrupt.h"

int main(void) {
    put_str("I am kernel\n");
    init_all();

    // enum intr_status itr_status = intr_enable();
    // if (itr_status == INTR_OFF) {
    //     put_str("Interrupt On.");
    // }
    // int i = 0;
    // for (; i < 0x00FFFFFF; i++);
    // ASSERT(1 == 2);

    void* addr = get_kernel_pages(3);
    put_str("\n get_kernel_page start vaddr is ");
    put_int((uint32_t)addr);
    put_str("\n");
    while (1);
    return 0;
}


