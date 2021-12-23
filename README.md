# Low-level implementation of *Semaphore* based on x86-32
> 基于x86-32的Semaphore底层实现

### OS Design Project

- 执行命令
```bash
make clean
make
make qemu
```

- 执行效果
![qemu](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/qemu1.png?raw=true)
![qemu](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/qemu2.png?raw=true)

- kern/sync/Semaphore.c

![Semaphore.c](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/Semaphore.c.png?raw=true)

- kern/sync/sem.c

![sem.c](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/sem.c.png?raw=true)

### 注意
#### Ubuntu 16.04上可能会因为Block Size大于500KB而无法执行qemu

![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_01.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_02.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_03.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_04.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_05.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_06.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_07.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_08.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_09.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_10.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_11.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_12.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_13.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_14.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_15.png?raw=true)
![img](https://github.com/cnarutox/MITJOS6.828/blob/finalwork/img/x86-32%20Semaphore_页面_16.png?raw=true)
