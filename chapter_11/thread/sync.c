#include "sync.h"
#include "debug.h"
#include "interrupt.h"

void sema_init(struct semaphore* psema, uint8_t value) {
    psema->value = value;
    list_init(&psema->waiters);
}

void lock_init(struct lock* plock) {
    plock->holder = NULL;
    plock->holder_repreat_nr = 0;
    sema_init(&plock->semaphore, 1);    // 初始化二元信号量
}

void sema_down(struct semaphore* psema) {
    enum intr_status old_status = intr_disable();
    while (psema->value == 0) {
        ASSERT(!elem_find(&psema->waiters, &(running_thread()->general_tag)));
        list_append(&psema->waiters, &(running_thread()->general_tag));
        thread_block(TASK_BLOCKED);
    }
    psema->value--;
    ASSERT(psema->value == 0);
    intr_set_status(old_status);
    // intr_enable();
}

void sema_up(struct semaphore* psema) {
    enum intr_status old_status = intr_disable();
    ASSERT(psema->value == 0);
    if (!list_empty(&psema->waiters)) {
        struct task_struct* thread_blocked = elem2entry(struct task_struct, general_tag, list_pop(&psema->waiters));
        thread_unblock(thread_blocked);
    }
    psema->value++;
    ASSERT(psema->value == 1);
    intr_set_status(old_status);
    // intr_enable();
}

void lock_acquire(struct lock* plock) {
    struct task_struct* cur = running_thread();
    if (plock->holder != cur) {
        sema_down(&plock->semaphore);
        plock->holder = cur;
        ASSERT(plock->holder_repreat_nr == 0);
        plock->holder_repreat_nr = 1;
    } else {
        plock->holder_repreat_nr++;
    }
}

void lock_release(struct lock* plock) {
    ASSERT(plock->holder == running_thread());
    if (plock->holder_repreat_nr > 1) {
        plock->holder_repreat_nr--;
        return;
    }
    ASSERT(plock->holder_repreat_nr == 1);
    plock->holder = NULL;
    plock->holder_repreat_nr = 0;
    sema_up(&plock->semaphore);
}

