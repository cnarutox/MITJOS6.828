#ifndef __KERN_SYNC_SEM_H__
#define __KERN_SYNC_SEM_H__

#include <defs.h>
#include <atomic.h>
#include <wait.h>

typedef struct {
    int value;
    wait_queue_t wait_queue;
} Semaphore;

void sem_init(Semaphore *sem, int value);
void up(Semaphore *sem);
void down(Semaphore *sem);
bool try_down(Semaphore *sem);

#endif
