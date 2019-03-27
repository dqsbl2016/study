> CountDownLatch是一个同步辅助类，通过AQS实现的一个闭锁。在其他线程完成它们的操作之前，允许一个多个线程等待。简单来说，CountDownLatch中有一个锁计数，在计数到达0之前，线程会一直等待。 

# 实现思想

设置一个整数变量做为总数，执行await()后进入阻塞，每当执行countDown()时总数-1，当总数未0时，await()阻塞的地方会开始执行。

# Sync

其中也是创建一个内部类通过继承AQS来实现一个同步计数器。

```java
private static final class Sync extends AbstractQueuedSynchronizer {
        private static final long serialVersionUID = 4982264981922014374L;
        Sync(int count) {
            setState(count);
        }
        int getCount() {
            return getState();
        }
        protected int tryAcquireShared(int acquires) {
            return (getState() == 0) ? 1 : -1;
        }
        protected boolean tryReleaseShared(int releases) {
            // Decrement count; signal when transition to zero
            for (;;) {
                int c = getState();
                if (c == 0)
                    return false;
                int nextc = c-1;
                if (compareAndSetState(c, nextc))
                    return nextc == 0;
            }
        }
    }
```

继承后的重写方法可以看到，CountDownLatch是一个“共享锁” 。实现了`tryAcquireShared`和`tryReleaseShared`两个方法。需要注意的是，**CountDownLatch中的锁是响应中断的，如果线程在对锁进行操作期间发生中断，会直接抛出InterruptedException。** 

# 源码分析

## 构造函数

```java
public CountDownLatch(int count) {
        if (count < 0) throw new IllegalArgumentException("count < 0");
        this.sync = new Sync(count);
}
Sync(int count) {
     setState(count);
}
```

执行构造函数需要传入一个整型变量，然后传入创建的同步器中，在同步器中会将这个变量直接放入状态中。业务处理时会判断当状态值为0时开始执行队列任务。通过countDown方法调用会将状态值-1.从构造函数中可以看出，CountDownLatch的“锁计数”本质上就是AQS的资源数`state`。 

## await()

```java
public void await() throws InterruptedException {
    sync.acquireSharedInterruptibly(1);
}

//AQS中acquireSharedInterruptibly(1)的实现
public final void acquireSharedInterruptibly(int arg)
        throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    if (tryAcquireShared(arg) < 0)
        doAcquireSharedInterruptibly(arg);
}

//tryAcquireShared在CountDownLatch中的实现
protected int tryAcquireShared(int acquires) {
    return (getState() == 0) ? 1 : -1;
}
```

`await()`的实现 首先会判断当前线程是否已经中止，则抛出异常，否则如果当前state不等于0的情况下，将线程放入等待队列阻塞。 

## countDown()

```java
public void countDown() {
    sync.releaseShared(1);
}

//AQS中releaseShared(1)的实现
public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        doReleaseShared();//唤醒后续节点
        return true;
    }
    return false;
}

//tryReleaseShared在CountDownLatch中的实现
protected boolean tryReleaseShared(int releases) {
    // Decrement count; signal when transition to zero
    for (;;) {
        int c = getState();
        if (c == 0)
            return false;
        int nextc = c-1;
        if (compareAndSetState(c, nextc))
            return nextc == 0;
    }
}
```

`countDown()`作用就是将state的值-1，如果当前state的值-1后为0则唤醒队列开始执行。如果释放资源后`state==0`,说明已经到达latch，此时就可以调用`doReleaseShared`唤醒等待的线程。 