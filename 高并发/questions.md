# 多线程

## 1、线程创建

* 哪些方法创建线程？
  *  new  submit  excute
* 如何用java创建进程？
  * new Thread   new Runnable()(这个内部也是调用Thread) new Callable
* 如何销毁一个线程？

  intersupt

## 2、线程执行

* 如何通过Java API启动线程？
  * start
* 当有线程T1/T2以及T3，如何实现T1->T2->T3的执行顺序？
  * join   T2中执行t3.join  t1中执行 t2.join
* 以上问题请至少提供另外一种实现？
  * 串行调用  用锁（同步队列，公平锁等）

## 3、线程中止

* 如何停止一个线程
  * interrupt
* 为什么java要放弃Thread的stop()方法？
  * 不会释放锁，采用的是kill -9 的方式 粗暴 会造成资源问题
* 请说明Thread interrupt()/ isInterrupted()以及 interrupted()的区别以及意义？

## 4、线程异常

* 当线程遇到异常时，到底发生了什么？
* 当线程遇到异常时，如何捕获？
* 当线程遇到异常时，ThreadPoolExecutor如何捕获异常？

## 5、线程状态

* Java 线程有哪些状态，分别代表什么含义？
* 如何获取当前 JVM 所有的线程状态？
* 如何获取线程的资源消费情况？

## 6、线程同步

* 请说明 synchronized 关键字在修饰方法与代码块中的区别？
* 请说明 synchronized 关键字与 ReentrantLock 之间的区别？
* 请解释偏向锁对 synchronized 与 ReentrantLock 的价值？

## 7、线程通讯

* 为什么 wait() 和 notify() 以及 notifyAll() 方法属于 Object ，并解释它们的作用？
* 为什么 Object wait() 和 notify() 以及 notifyAll() 方法必须synchronized 之中执行？
* 请通过 Java 代码模拟实现 wait() 和 notify() 以及 notifyAll() 的语义？

## 8、线程退出

* 当主线程退出时，守候子线程会执行完毕吗？
* 请说明 ShutdownHook 线程的使用场景，以及如何触发执行？
* 如何确保在主线程退出前，所有线程执行完毕？

# Java 并发集合框架

## 1、线程安全集合

* 请在 Java 集合框架以及 J.U.C 框架中各举出 List、Set 以及 Map 的实现？
* 如何将普通 List、Set 以及 Map 转化为线程安全对象？
* 如何在 Java 9+ 实现以上问题？

## 2、线程安全 LIST

* 请说明 List、Vector 以及 CopyOnWriteArrayList 的相同点和不同点？
* 请说明 Collections#synchronizedList(List) 与 Vector 的相同点和不同点？
* Arrays#asList(Object...) 方法是线程安全的吗？如果不是的话，如何实现替代方案？

## 3、线程安全 SET

* 请至少举出三种线程安全的 Set 实现？
* 在 J.U.C 框架中，存在 HashSet 的线程安全实现？如果不存在的话，要如何实现？
* 当 Set#iterator() 方法返回 Iterator 对象后，能否在其迭代中，给Set 对象添加新的元素？

## 4、线程安全 MAP

* 请说明 Hashtable、HashMap 以及 ConcurrentHashMap 的区别？
* 请说明 ConcurrentHashMap 在不同的 JDK 中的实现？
* 请说明 ConcurrentHashMap 与 ConcurrentSkipListMap 各自的优势与不足？

## 5、线程安全 QUEUE

* 请说明 BlockingQueue 与 Queue 的区别？
* 请说明 LinkedBlockingQueue 与 ArrayBlockingQueue 的区别？
* 请说明 LinkedTransferQueue 与 LinkedBlockingQueue 的区别？

## 6、PRIORITYBLOCKINGQUEUE

请评估以下程序的运行结果？

![1554704044141](D:\study\高并发\img\question1.png)

## 7、SYNCHRONOUSQUEUE

请评估以下程序的运行结果？

![1554704110099](D:\study\高并发\img\question2.png)

## 8、BLOCKINGQUEUE OFFER()

请评估以下程序的运行结果？

![1554704154629](D:\study\高并发\img\question3.png)

# Java 并发框架

## 1、锁 LOCK

* 请说明 ReentrantLock 与 ReentrantReadWriteLock 的区别？
* 请解释 ReentrantLock 为什么命名为重进入？
* 请说明 Lock#lock() 与 Lock#lockInterruptibly() 的区别？

## 2、条件变量 CONDITION

* 请举例说明 Condition 使用场景？
* 请使用 Condition 实现“生产者-消费者问题”？
* 请解释 Condition await() 和 single() 与 Object wait() 和notify() 的相同与差异？

## 3、屏障 BARRIERS

* 请说明 CountDownLatch 与 CyclicBarrier 的区别？
* 请说明 Semaphore 的使用场景？
* 请通过 Java 1.4 的语法实现一个 CountDownLatch ？

## 4、线程池 THREAD POOL

* 请问 J.U.C 中内建了几种 ExecutorService 实现？
* 请分别解释 ThreadPoolExecutor 构造器参数在运行时的作用？
* 如何获取 ThreadPoolExecutor 正在运行的线程？

## 5、FUTURE

* 如何获取 Future 对象？
* 请举例 Future get() 以及 get(long,TimeUnit) 方法的使用场景？
* 如何利用 Future 优雅地取消一个任务的执行？

## 6、VOLATILE 变量

* 在 Java 中，volatile 保证的是可见性还是原子性？
* 在 Java 中，volatile long 和 double 是线程安全的吗？
* 在 Java 中，volatile 的底层实现是基于什么机制？

## 7、原子操作 ATOMIC

* 为什么 AtomicBoolean 内部变量使用 int 实现，而非 boolean？
* 在变量原子操作时，Atomic* CAS 操作比 synchronized 关键字那个更重？
* Atomic* CAS 的底层是如何实现的？

