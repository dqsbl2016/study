# 线程相关

## 进程/线程/协程

* 进程
  * 进程是线程中运行的容器，是程序的真正运行实例。
* 线程
  * 操作系统能运算调度的最小单位。
* 协程
  * 又叫做微线程，运行时可以暂停及恢复。不会发生线程切换的问题，也不需要锁的机制。

## 同步/异步/非阻塞

* 同步
  * 最常见的编程手段，是指任务发起方与执行方在同一个线程中完成。
* 异步
  * 常见的提升吞吐手段，是指任务发起方与执行方不在同一个线程中完成。
* 非阻塞
  * 一种编程模型，由通知状态被动的回调执行，同步或异步均可。

## 线程的状态 Thread.State 

* New   线程已创建，但未启动的状态
* Runnable  表示线程处于可运行状态，不代表一定执行，可能在等待系统资源。
* Blocked  被 Monitor 锁阻塞，表示当前线程在同步锁的场景运作
* Waiting  线程处于等待状态，由 Object#wait()、Thread#join() 或 LockSupport#park() 引起
* Time_Waiting  线程处于规定时间内的等待状态
* Terminated  线程执⾏行行结束

## 线程的生命周期

* 启动  Thread.start()

* ~~停止 Thread.stop()~~          

  * ```java
    废弃原因？
    stop()方法在终结一个线程时不会保证线程的资源正常释放，通常是没有给予线程完成资源释放工作的机会，
    因此会导致程序可能工作在不确定状态下。
    1.报错 
    	当一个线程获取到对象锁后正在执行任务中，其他线程（调用stop的为其他线程）中执行这个线程stop操作，会导致这个线程立刻释放所持对象的锁，而且可能这个线程还在运行中（不会因为调用stop这个线程立刻就停止），而这个时候因为锁被释放了，再运行时就会出现错误（抛出java.lang.ThreadDeath）。
    2.无法保证数据完整性
    	当执行一半的时候，被执行stop操作，会导致之前的数据不完整（对某些多个线程共有的数据的修改只改了一部分），其他线程获取到锁后在这个基础上继续执行。
    ```

* ~~暂停 Thread.suspend()~~

  * ```java
    废弃原因：
    在调用后，线程不会释放已经占有的资源（比如锁），而是占有着资源进入睡眠状态，这样容易引发死锁问题。
    这个操作是不释放锁的挂起操作，如果用户没有恢复，将导致这个锁一直被持有，会导致死锁操作。
    ```

* ~~恢复 Thread.resume()~~

  * ```java
    废弃原因：
    配合暂停的操作，同时被废弃。
    ```

* 中止 Thread.interrupt()  判断是否中止 Thread.isInterrupted()

  * ```java
    工作原理：
    首先这个中止操作，它不会立刻让线程中止，会为这个线程设置一个中断状态，即设置为true。
    如果一个线程处于了阻塞状态（如线程调用了thread.sleep、thread.join、thread.wait、1.5中的condition.await、以及可中断的通道上的 I/O 操作方法后可进入阻塞状态），则在线程在检查中断标示时如果发现中断标示为true，则会在这些阻塞方法（sleep、join、wait、1.5中的condition.await及可中断的通道上的 I/O 操作方法）调用处抛出InterruptedException异常，并且在抛出异常后立即将线程的中断标示位清除，即重新设置为false。抛出异常是为了线程从阻塞状态醒过来，并在结束线程前让程序员有足够的时间来处理中断请求。
    
    参考理解：
    https://blog.csdn.net/tianyuxingxuan/article/details/76222935
    ```

* 如何中断线程

  * ```java
    中断线程最好的，最受推荐的方式是，使用共享变量（shared variable）发出信号，告诉线程必须停止正在运行的任务。线程必须周期性的核查这一变量，然后有秩序地中止任务。
    
    线程中抛异常，只要出现异常线程将中止
    ```

## P1  Object 的wait() 与  notify()

wait和notify方法都是Object的实例方法，要执行这两个方法，有一个前提就是，当前线程必须获其对象的monitor（俗称“锁”），否则会抛出IllegalMonitorStateException异常，所以这两个方法必须在同步块代码里面调用。 

> **当线程执行wait()时，会把当前的锁释放，然后让出CPU，进入等待状态。**
>
>  **当执行notify/notifyAll方法时，会唤醒一个处于等待该 对象锁 的线程，然后继续往下执行，直到执行完退出对象锁锁住的区域（synchronized修饰的代码块）后再释放锁。**

## 线程通信

```java
Object.wait() 与 thread.join() 看起来效果一样
实际上 Thread.join方法就是 调用了Thread对象的wait()方法
```

## P2 notify 与 notifyAll 

* notify  唤醒一个线程，如果是多个线程等待唤醒，这个方法只会唤醒其中一个线程，选择哪个线程取决于操作系统对多线程管理的实现。 
* notifyAll 唤醒全部线程，多个线程等待唤醒，会全部唤醒，但是哪个会执行，取决于最后锁的获取者。

> notify只能唤醒一个线程，另外的线程会依然处于等待唤醒状态。
>
> notifyAll 唤醒全部线程，但是只要一个会获得锁，其他处于等待锁状态。

## 进程管理

### 获取PID进程ID

* java9之前

  * ```java
    RuntimeMXBean runtimeMXBean = ManagementFactory.getRuntimeMxBean();
    String name = runtimeMXBean.getName();
    String pid = name.substring(0,name.indexOf("@"))
    ```

* java9 

  * ```java
    long pid = ProcessHandle.current().pid();
    ```

* java10

  * ```java
    RuntimeMXBean runtimeMXBean = ManagementFactory.getRuntimeMxBean();
    String id = runtimeMXBean.getPid();
    ```

### 获取当前JVM启动时间

```java
RuntimeMXBean runtimeMXBean = ManagementFactory.getRuntimeMxBean();
// 启动时间
Date starttime = runtimeMXBean.getStratTime();
//上线时间
Date starttime = runtimeMXBean.getUpTime();
```

### 获取当前jvm进程数量

```java
RuntimeMXBean runtimeMXBean = ManagementFactory.getRuntimeMxBean();
// 当前jvm进程数量
Date starttime = runtimeMXBean.getThreadCount();
```

