# Low-level implementation of *Semaphore* based on x86-32
> 基于x86-32的Semaphore底层实现
## 操作系统课程设计

- 执行命令
```bash
make clean
make
make qemu
```

- 执行效果
![qemu](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/qemu1.png)
![qemu](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/qemu2.png)

- kern/sync/Semaphore.c
>![Semaphore.c](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/Semaphore.c.png)

- kern/sync/sem.c
>![sem.c](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/sem.c.png)

### 注意
#### Ubuntu 16.04上可能会因为Block Size大于500KB而无法执行qemu
