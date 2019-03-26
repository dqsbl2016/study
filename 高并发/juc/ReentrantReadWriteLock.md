> ReentrantReadWriteLock维护了一对相关的锁：**共享锁readLock和独占锁writeLock。**共享锁`readLock`用于读操作，能同时被多个线程获取；独占锁`writeLock`用于写入操作，只能被一个线程持有。 

`ReentrantReadWriteLock`与`ReentrantLock`一样在内部实现了公平锁及非公平锁。另外在内部还创建了 `ReadLock`与`WriteLock`内部类

# Sync 同步器

```java
abstract static class Sync extends AbstractQueuedSynchronizer {
    private static final long serialVersionUID = 6317671515068378041L;
    // 最多支持65535(1<<16 -1)个写锁和65535个读锁；低16位表示写锁计数，高16位表示持有读锁的线程数
    static final int SHARED_SHIFT   = 16;
    // 读锁高16位，读锁个数加1，其实是状态值加 2^16
    static final int SHARED_UNIT    = (1 << SHARED_SHIFT);
    // 锁最大数量
    static final int MAX_COUNT      = (1 << SHARED_SHIFT) - 1;
    // 写锁掩码，用于标记低16位
    static final int EXCLUSIVE_MASK = (1 << SHARED_SHIFT) - 1;
    //读锁计数，当前持有读锁的线程数，c的高16位
    static int sharedCount(int c)    { return c >>> SHARED_SHIFT; }
    //写锁的计数，也就是它的重入次数,c的低16位
    static int exclusiveCount(int c) { return c & EXCLUSIVE_MASK; }

    //读锁线程数
    static int sharedCount(int c)    { return c >>> SHARED_SHIFT; }
    //写锁线程数
    static int exclusiveCount(int c) { return c & EXCLUSIVE_MASK; }
    //当前线程持有的读锁重入数量
    private transient ThreadLocalHoldCounter readHolds;
    //最近一个获取读锁成功的线程计数器
    private transient HoldCounter cachedHoldCounter;
    // 第一个获取读锁的线程
    private transient Thread firstReader = null;
    //firstReader的持有数
    private transient int firstReaderHoldCount;

    // 构造函数
    Sync() {
        readHolds = new ThreadLocalHoldCounter();
        setState(getState()); // ensures visibility of readHolds
    }

    // 持有读锁的线程计数器
    static final class HoldCounter {
        int count = 0; //持有数
        // Use id, not reference, to avoid garbage retention
        final long tid = getThreadId(Thread.currentThread());
    }

    // 本地线程计数器
    static final class ThreadLocalHoldCounter
            extends ThreadLocal<HoldCounter> {
        // 重写初始化方法，在没有进行set的情况下，获取的都是该HoldCounter值
        public HoldCounter initialValue() {
            return new HoldCounter();
        }
    }
}
```

`Sync`类内部存在两个内部类，分别为`HoldCounter`和`ThreadLocalHoldCounter`，用来记录每个线程持有的读锁数量。 

# ReadLock 读锁

```java
public static class ReadLock implements Lock, java.io.Serializable {
    private static final long serialVersionUID = -5992448646407690164L;
    //持有的AQS对象
    private final Sync sync;
    protected ReadLock(ReentrantReadWriteLock lock) {
        sync = lock.sync;
    }
    //获取共享锁
    public void lock() {
        sync.acquireShared(1);
    }
    //获取共享锁(响应中断)
    public void lockInterruptibly() throws InterruptedException {
        sync.acquireSharedInterruptibly(1);
    }
    //尝试获取共享锁
    public boolean tryLock(long timeout, TimeUnit unit)
            throws InterruptedException {
        return sync.tryAcquireSharedNanos(1, unit.toNanos(timeout));
    }
    //释放锁
    public void unlock() {
        sync.releaseShared(1);
    }
    //新建条件
    public Condition newCondition() {
        throw new UnsupportedOperationException();
    }
    public String toString() {
        int r = sync.getReadLockCount();
        return super.toString() +
                "[Read locks = " + r + "]";
    }
}
```

# WriteLock 写锁

```java
public static class WriteLock implements Lock, java.io.Serializable {
    private static final long serialVersionUID = -4992448646407690164L;
     //持有的AQS对象
    private final Sync sync;
    protected WriteLock(ReentrantReadWriteLock lock) {
        sync = lock.sync;
    }
 	//获取独占锁
    public void lock() {
        sync.acquire(1);
    }
    //获取独占锁(响应中断)
    public void lockInterruptibly() throws InterruptedException {
        sync.acquireInterruptibly(1);
    }
    //尝试获取独占锁
    public boolean tryLock( ) {
        return sync.tryWriteLock();
    }
    public boolean tryLock(long timeout, TimeUnit unit)
            throws InterruptedException {
        return sync.tryAcquireNanos(1, unit.toNanos(timeout));
    }
    //释放锁
    public void unlock() {
        sync.release(1);
    }
    //新建条件
    public Condition newCondition() {
        return sync.newCondition();
    }
    public String toString() {
        Thread o = sync.getOwner();
        return super.toString() + ((o == null) ?
                                   "[Unlocked]" :
                                   "[Locked by thread " + o.getName() + "]");
    }
    public boolean isHeldByCurrentThread() {
        return sync.isHeldExclusively();
    }
    public int getHoldCount() {
        return sync.getWriteHoldCount();
    }
}
```

# 源码分析

##  lock()

```java
public void lock() {
    sync.acquireShared(1);
}
```

`lock`方法调用了同步器`sync`的`acquireShared`， 然后调用`tryAcquireShared `,此方法在`ReentrantReadWriteLock `中有实现。

```java
protected final int tryAcquireShared(int unused) {
    //获取当前线程
    Thread current = Thread.currentThread();
    int c = getState();
    //持有写锁的线程可以获取读锁，如果获取锁的线程不是current线程；则返回-1。
    if (exclusiveCount(c) != 0 &&
        getExclusiveOwnerThread() != current)
        return -1;
    int r = sharedCount(c);//获取读锁数量
    if (!readerShouldBlock() &&
        r < MAX_COUNT &&
        compareAndSetState(c, c + SHARED_UNIT)) {
        if (r == 0) {//首次获取读锁,初始化firstReader和firstReaderHoldCount
            firstReader = current;
            firstReaderHoldCount = 1;
        } else if (firstReader == current) {//当前线程是首个获取读锁的线程
            firstReaderHoldCount++;
        } else {
            //更新cachedHoldCounter
            HoldCounter rh = cachedHoldCounter;
            if (rh == null || rh.tid != getThreadId(current))
                cachedHoldCounter = rh = readHolds.get();
            else if (rh.count == 0)
                readHolds.set(rh);
            rh.count++;//更新获取的读锁数量
        }
        return 1;
    }
    return fullTryAcquireShared(current);
}
```

`tryAcquireShared()`的作用是尝试获取“读锁/共享锁”。函数流程如下：

* 如果“写锁”已经被持有，这时候可以继续获取读锁，但如果持有写锁的线程不是当前线程，直接返回-1（表示获取失败）；
* 如果在尝试获取锁时不需要阻塞等待（由公平性决定），并且读锁的共享计数小于最大数量`MAX_COUNT`，则直接通过CAS函数更新读取锁的共享计数，最后将当前线程获取读锁的次数+1。
* 如果第二步执行失败，则调用`fullTryAcquireShared`尝试获取读锁，源码如下：

 ```java
final int fullTryAcquireShared(Thread current) {
    HoldCounter rh = null;
    for (;;) {//自旋
        int c = getState();
        //持有写锁的线程可以获取读锁，如果获取锁的线程不是current线程；则返回-1。
        if (exclusiveCount(c) != 0) {
            if (getExclusiveOwnerThread() != current)
                return -1;
            // else we hold the exclusive lock; blocking here
            // would cause deadlock.
        } else if (readerShouldBlock()) {//需要阻塞
            // Make sure we're not acquiring read lock reentrantly
            //当前线程如果是首个获取读锁的线程，则继续往下执行。
            if (firstReader == current) {
                // assert firstReaderHoldCount > 0;
            } else {
                //更新锁计数器
                if (rh == null) {
                    rh = cachedHoldCounter;
                    if (rh == null || rh.tid != getThreadId(current)) {
                        rh = readHolds.get();
                        if (rh.count == 0)
                            readHolds.remove();//当前线程持有读锁数为0，移除计数器
                    }
                }
                if (rh.count == 0)
                    return -1;
            }
        }
        if (sharedCount(c) == MAX_COUNT)//超出最大读锁数量
            throw new Error("Maximum lock count exceeded");
        if (compareAndSetState(c, c + SHARED_UNIT)) {//CAS更新读锁数量
            if (sharedCount(c) == 0) {//首次获取读锁
                firstReader = current;
                firstReaderHoldCount = 1;
            } else if (firstReader == current) {//当前线程是首个获取读锁的线程，更新持有数
                firstReaderHoldCount++;
            } else {
                //更新锁计数器
                if (rh == null)
                    rh = cachedHoldCounter;
                if (rh == null || rh.tid != getThreadId(current))
                    rh = readHolds.get();//更新为当前线程的计数器
                else if (rh.count == 0)
                    readHolds.set(rh);
                rh.count++;
                cachedHoldCounter = rh; // cache for release
            }
            return 1;
        }
    }
}
 ```

`fullTryAcquireShared`是获取读锁的完整版本，用于处理CAS失败、阻塞等待和重入读问题。相对于`tryAcquireShared`来说，执行流程上都差不多，不同的是，它增加了重试机制和对“持有读锁数的延迟读取”的处理。

如果`tryAcquireShared`获取读锁失败返回-1，则调用`doAcquireShared`将当前线程加入等待队列尾部等待唤醒，成功获取资源后返回。

 ## unlock()

```java
public void unlock() {
    sync.releaseShared(1);
}
```

 `unlock`方法调用了同步器`sync`的`releaseShared` ,然后调用`tryReleaseShared `，在`ReentrantReadWriteLock `中有其实现。

```java
protected final boolean tryReleaseShared(int unused) {
    Thread current = Thread.currentThread();
    if (firstReader == current) {//当前为第一个获取读锁的线程
        // assert firstReaderHoldCount > 0;
        //更新线程持有数
        if (firstReaderHoldCount == 1)
            firstReader = null;
        else
            firstReaderHoldCount--;
    } else {
        HoldCounter rh = cachedHoldCounter;
        if (rh == null || rh.tid != getThreadId(current))
            rh = readHolds.get();//获取当前线程的计数器
        int count = rh.count;
        if (count <= 1) {
            readHolds.remove();
            if (count <= 0)
                throw unmatchedUnlockException();
        }
        --rh.count;
    }
    for (;;) {//自旋
        int c = getState();
        int nextc = c - SHARED_UNIT;//获取剩余资源/锁
        if (compareAndSetState(c, nextc))
            // Releasing the read lock has no effect on readers,
            // but it may allow waiting writers to proceed if
            // both read and write locks are now free.
            return nextc == 0;
    }
}
```

在`releaseShared`中，首先调用`tryReleaseShared`尝试释放锁，方法流程很简单，主要包括两步：

* 更新当前线程计数器的锁计数；
* CAS更新释放锁之后的state，这里使用了自旋，在state争用的时候保证了CAS的成功执行。

 

 

 

 

 

 

 