#include "print.h"
#include "init.h"
#include "thread.h"
#include "interrupt.h"

void k_thread_a(void* arg);
void k_thread_b(void* arg);

int main(void) {
    put_str("I am kernel\n");
    init_all();

    thread_start("k_thread_a", 31, k_thread_a, "argA ");
    thread_start("k_thread_a", 8, k_thread_b, "argB ");

    intr_enable();

    while (1) {
        put_str("Main ");
    }
    return 0;
}

void k_thread_a(void* arg) {
    char* para = arg;
    while (1) {
        put_str(para);
    }    
}

void k_thread_b(void* arg) {
    char* para = arg;
    while (1) {
        put_str(para);
    }    
}

