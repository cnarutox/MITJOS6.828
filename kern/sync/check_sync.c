#include <stdio.h>
#include <proc.h>
#include <sem.h>
#include <assert.h>

#define N 10
#define LEFT (i-1+N)%N
#define RIGHT (i+1)%N
#define THINKING 0
#define HUNGRY 1
#define EATING 2
#define TIMES  4
#define SLEEP_TIME 50

int state[N];
Semaphore mutex;
Semaphore s[N];

struct proc_struct *philosopher_proc[N];

void test(i)
{ 
    if(state[i]==HUNGRY && state[LEFT] != EATING
            && state[RIGHT] != EATING)
    {
        state[i]=EATING;
        up(&s[i]);
    }
}

void take_forks(int i)
{ 
        down(&mutex);
        state[i]=HUNGRY;
        test(i);
        up(&mutex);
        down(&s[i]);
}

void put_forks(int i)
{ 
        down(&mutex);
        state[i]=THINKING;
        test(LEFT);
        test(RIGHT);
        up(&mutex);
}

int philosopher(void * arg)
{
    int i, iter=0;
    i=(int)arg;
    cprintf("我是第%d个哲学家\n",i);
    while(iter++<TIMES)
    {
        cprintf("Iter %d, 第%d个哲学家正在思考\n",iter,i);
        do_sleep(SLEEP_TIME);
        take_forks(i); 
        cprintf("Iter %d, 第%d个哲学家正在进餐\n",iter,i);
        do_sleep(SLEEP_TIME);
        put_forks(i);
		}
		cprintf("第%d个哲学家吃完离开\n",i);
		return 0;
	}


void philosophers(void){

    int i;
    sem_init(&mutex, 1);
    for(i=0;i<N;i++){
        sem_init(&s[i], 0);
        int pid = kernel_thread(philosopher, (void *)i, 0);
        if (pid <= 0) {
            panic("创建第%d个哲学家失败\n");
        }
        philosopher_proc[i] = find_proc(pid);
    }
}
