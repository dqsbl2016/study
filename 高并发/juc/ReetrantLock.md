> **ReentrantLock**是一个**可重入的互斥锁**，也被称为**“独占锁”**。 “独占锁”在同一个时间点只能被一个线程持有；而可重入的意思是，ReentrantLock可以被单个线程多次获取。 
>
> ReentrantLock又分为**“公平锁(fair lock)”和“非公平锁(non-fair lock)”**。它们的区别体现在获取锁的机制上：在“公平锁”的机制下，线程依次排队获取锁；而“非公平锁”机制下，如果锁是可获取状态，不管自己是不是在队列的head节点都会去尝试获取锁。 

ReentrantLock中包括3个内部类，其中一个继承AQS，而其他两个分别继承这个内部类。

# Sync 同步器

这个是一个抽象类，ReetrantLock通过AQS实现了自己的同步器`Sync` 。

# NonfairSync 非公平锁

基于Sync同步器实现得非公平锁功能。

# FairSync 公平锁

基于Sync同步器实现得公平锁功能。

# Lock

ReetrantLock 实现了 Lock接口，可以看一下Lock接口的内容

```java
public interface Lock {
    //获取锁，如果锁不可用则线程一直等待
    void lock();
    //获取锁，响应中断，如果锁不可用则线程一直等待
    void lockInterruptibly() throws InterruptedException;
    //获取锁，获取失败直接返回
    boolean tryLock();
    //获取锁，等待给定时间后如果获取失败直接返回
    boolean tryLock(long time, TimeUnit unit) throws InterruptedException;
    //释放锁
    void unlock();
    //创建一个新的等待条件
    Condition newCondition();
}
```

可以看到获取锁存在4种方式：

* `lock()` 获取失败后，线程进入等待队列自旋或休眠，直到锁可用，并且忽略中断的影响
* `lockInterruptibly()`  线程进入等待队列park后，如果线程被中断，则直接响应中断（抛出`InterruptedException`）
* `tryLock()` 获取锁失败后直接返回，不进入等待队列
*  `tryLock(long time, TimeUnit unit)` 获取锁失败等待给定的时间后返回获取结果

 >当构造时，可以通过参数来确定使用公平锁或非公平锁。
 >
 >```
 >public ReentrantLock(boolean fair) {
 >    sync = fair ? new FairSync() : new NonfairSync();
 >}
 >```
 >
 >而默认构造函数是采用的非公平所
 >
 >```
 >public ReentrantLock() {
 >    sync = new NonfairSync();
 >}
 >```

# 源码分析

## lock() 

```java
//获取锁，一直等待锁可用
public void lock() {
    sync.lock();
}
//公平锁获取
final void lock() {
    acquire(1);
}
//非公平锁获取
final void lock() {
    if (compareAndSetState(0, 1))
        setExclusiveOwnerThread(Thread.currentThread());
    else
        acquire(1);
}
```

 获取失败后，线程进入等待队列自旋或休眠，直到锁可用，并且忽略中断的影响。

公平锁中直接调用AQS中的`acquire(1)`； 内部会调用tryAcquire(1)。

非公平锁则直接通过CAS修改`state`值来获取锁，当获取失败时才会调用`acquire(1)`来获取锁。 

**公平锁的tryAcquire实现**

```java
protected final boolean tryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();//获取锁状态state
    if (c == 0) {
        if (!hasQueuedPredecessors() && //判断当前线程是否还有前节点
            compareAndSetState(0, acquires)) {//CAS修改state
            //获取锁成功，设置锁的持有线程为当前线程
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {//当前线程已经持有锁
        int nextc = c + acquires;//重入
        if (nextc < 0)
            throw new Error("Maximum lock count exceeded");
        setState(nextc);//更新state状态
        return true;
    }
    return false;
}
```

执行流程：

* 如果当前锁状态`state`为0，说明锁处于闲置状态可以被获取，首先调用`hasQueuedPredecessors`方法判断当前线程是否还有前节点(prev node)在等待获取锁。如果有，则直接返回false；如果没有，通过调用`compareAndSetState`（CAS）修改state值来标记自己已经拿到锁，CAS执行成功后调用`setExclusiveOwnerThread`设置锁的持有者为当前线程。程序执行到现在说明锁获取成功，返回true；
* 如果当前锁状态`state`不为0，但当前线程已经持有锁（`current == getExclusiveOwnerThread()`），由于锁是可重入（多次获取）的，则更新重入后的锁状态`state += acquires` 。锁获取成功返回true。（这里的锁状态只是记录是否已经有锁，或者重入次数）

 **非公平锁的tryAcquire实现**

 ```java
//非公平锁获取
protected final boolean tryAcquire(int acquires) {
    return nonfairTryAcquire(acquires);
}
final boolean nonfairTryAcquire(int acquires) {
    final Thread current = Thread.currentThread();
    int c = getState();
    if (c == 0) {
        if (compareAndSetState(0, acquires)) {//CAS修改state
            setExclusiveOwnerThread(current);
            return true;
        }
    }
    else if (current == getExclusiveOwnerThread()) {
        int nextc = c + acquires;//计算重入后的state
        if (nextc < 0) // overflow
            throw new Error("Maximum lock count exceeded");
        setState(nextc);
        return true;
    }
    return false;
}
 ```

通过对比公平锁和非公平锁`tryAcquire`的代码可以看到，非公平锁的获取略去了`!hasQueuedPredecessors()`这一操作，也就是说它不会判断当前线程是否还有前节点(prev node)在等待获取锁，而是直接去进行锁获取操作。 

## unlock()

```java
//释放锁
public void unlock() {
    sync.release(1);
}
```

释放锁，同样会调用`tryRelease`方法，这个方法在Sync抽象类中定义。公平与非公平锁都调用此方法。

```java

```

`tryRelease`用于释放给定量的资源。在ReetrantLock中每次释放量为1，也就是说，**在可重入锁中，获取锁的次数必须要等于释放锁的次数，这样才算是真正释放了锁。**在锁全部释放后（`state==0`）才可以唤醒下一个等待线程。 

 

 

 



 

 

 

 