> StampedLock是JDK 8新增的读写锁，跟其他同步锁不同，它并不是由AQS实现的。它是一个基于能力(capability-based)的锁，提供了三种模式来控制 read/write 的获取，并且内部实现了自己的同步等待队列。 

**为什么要改进读写锁？**

读写锁虽然分离了读和写的功能,使得读与读之间可以完全并发,但是读和写之间依然是冲突的,读锁会完全阻塞写锁,它使用的依然是悲观的锁策略.如果有大量的读线程,他也有可能引起写线程的饥饿。

**StampedLock如何实现？**

StampedLock的内部实现是基于CLH锁的,CLH锁是一种自旋锁,它保证没有饥饿的发生,并且可以保证FIFO(先进先出)的服务顺序.  

# WNode

StampedLockd源码中的WNode就是等待链表队列，每一个WNode标识一个等待线程。

# 核心参数

```java
//获取锁失败入队之前的最大自旋次数（实际运行时并不一定是这个数）
private static final int SPINS = (NCPU > 1) ? 1 << 6 : 0;
//头节点获取锁的最大自旋次数
private static final int HEAD_SPINS = (NCPU > 1) ? 1 << 10 : 0;
//头节点再次阻塞前的最大自旋次数
private static final int MAX_HEAD_SPINS = (NCPU > 1) ? 1 << 16 : 0;
//等待自旋锁溢出的周期数
private static final int OVERFLOW_YIELD_RATE = 7; // must be power 2 - 1
//在溢出之前读线程计数用到的bit数
private static final int LG_READERS = 7;
// Values for lock state and stamp operations
private static final long RUNIT = 1L;//读锁单位
private static final long WBIT  = 1L << LG_READERS;//写状态标识 1000 0000
private static final long RBITS = WBIT - 1L;//读状态标识 111 1111
private static final long RFULL = RBITS - 1L; //读锁最大资源数 111 1110
private static final long ABITS = RBITS | WBIT; //用于获取锁状态 1111 1111
private static final long SBITS = ~RBITS; //note overlap with ABITS
//锁状态初始值
private static final long ORIGIN = WBIT << 1;
//中断标识
private static final long INTERRUPTED = 1L;
//节点状态 等待/取消
private static final int WAITING   = -1;
private static final int CANCELLED =  1;
//节点模型 读/写
private static final int RMODE = 0;
private static final int WMODE = 1;
```

```java
state & ABITS == 0L 写锁可用
state & ABITS < RFULL 读锁可用
state & ABITS == WBIT 写锁已经被其他线程获取
state & ABITS == RFULL 读锁饱和，可尝试增加额外资源数
(stamp & SBITS) == (state & SBITS) 验证stamp是否为当前已经获取的锁stamp
(state & WBIT) != 0L 当前线程已经持有写锁
(state & RBITS) != 0L 当前线程已经持有读锁
s & RBITS 读锁已经被获取的数量
```

# 核心方法

```java
//构造函数
public StampedLock() {
    state = ORIGIN;
}
//获取写锁，等待锁可用
public long writeLock()
//获取写锁，直接返回
public long tryWriteLock()
//获取写锁，等待指定的时间
public long tryWriteLock(long time, TimeUnit unit)
//获取写锁，响应中断
public long writeLockInterruptibly()
//获取读锁，等待锁可用
public long readLock()
//尝试获取读锁，直接返回
public long tryReadLock()
//获取读锁，限制等待时间
public long tryReadLock(long time, TimeUnit unit)
//获取读锁，响应中断
public long readLockInterruptibly()
//获取乐观读锁,如果写锁可用获取成功，不修改任何状态值
public long tryOptimisticRead()
//验证stamp，如果在锁发出给定的stamp之后写锁没有被获取，或者给定stamp是当前已经获取的锁stamp，则返回true。一般用在乐观读锁中，用于判断是否可继续获取读锁。
public boolean validate(long stamp)
//释放写锁
public void unlockWrite(long stamp)
//释放读锁
public void unlockRead(long stamp) 
//释放给定stamp对应的锁
public void unlock(long stamp)
//尝试升级给定stamp对应的锁为写锁
public long tryConvertToWriteLock(long stamp)
//尝试降级给定stamp对应的锁为读锁
public long tryConvertToReadLock(long stamp)
//尝试降级给定stamp对应的锁为乐观读锁
public long tryConvertToOptimisticRead(long stamp) 
//尝试释放写锁，一般用在异常复原
public boolean tryUnlockWrite()
//尝试释放读锁，一般用在异常复原
public boolean tryUnlockRead()
//写锁是否被持有
public boolean isWriteLocked()
//读锁是否被持有
public boolean isReadLocked()
//获取读锁数
public int getReadLockCount()
//返回一个ReadLock
public Lock asReadLock()
//返回一个WriteLock
public Lock asWriteLock()
//返回一个ReadWriteLock
public ReadWriteLock asReadWriteLock()
```

# 源码分析

##  writeLock()

```java
//获取写锁，等待可用
public long writeLock() {
    long s, next;  // bypass acquireWrite in fully unlocked case only
    return ((((s = state) & ABITS) == 0L &&
             U.compareAndSwapLong(this, STATE, s, next = s + WBIT)) ?
            next : acquireWrite(false, 0L));
}
private long acquireWrite(boolean interruptible, long deadline) {
	WNode node = null, p;
    //第一个自旋，准备入队
    for (int spins = -1;;) { // spin while enqueuing
        long m, s, ns;
        if ((m = (s = state) & ABITS) == 0L) {//锁可用
            if (U.compareAndSwapLong(this, STATE, s, ns = s + WBIT))//获取锁 CAS修改锁状态
                return ns;
        }
        else if (spins < 0)
            spins = (m == WBIT && wtail == whead) ? SPINS : 0;//自旋次数
        else if (spins > 0) {
            if (LockSupport.nextSecondarySeed() >= 0)
                --spins;    //随机递减
        }
        else if ((p = wtail) == null) { // initialize queue
            WNode hd = new WNode(WMODE, null);//初始化写锁等待队列
            if (U.compareAndSwapObject(this, WHEAD, null, hd))
                wtail = hd;
        }
        else if (node == null)
            node = new WNode(WMODE, p);//创建新的等待节点
        else if (node.prev != p)
            node.prev = p;
        else if (U.compareAndSwapObject(this, WTAIL, p, node)) {//更新tail节点
            p.next = node;
            break;
        }
    }

    //第二个自旋，节点依次获取锁
    for (int spins = -1;;) {
        WNode h, np, pp; int ps;
        if ((h = whead) == p) {//当前节点是最后一个等待节点
            if (spins < 0)
                spins = HEAD_SPINS; //头结点自旋次数
            else if (spins < MAX_HEAD_SPINS)
                spins <<= 1; // spins=spins/2
            for (int k = spins;;) { // spin at head
                long s, ns;
                if (((s = state) & ABITS) == 0L) {//锁可用
                    if (U.compareAndSwapLong(this, STATE, s,
                                             ns = s + WBIT)) {//更新锁状态
                         //当前节点设置为头结点
                        whead = node;
                        node.prev = null;
                        return ns;
                    }
                }
                else if (LockSupport.nextSecondarySeed() >= 0 &&
                         --k <= 0)//随机递减
                    break;
            }
        }
        else if (h != null) { // help release stale waiters
            WNode c; Thread w;
           //头结点为读锁将栈中所有读锁线程唤醒
            while ((c = h.cowait) != null) {//有等待读的线程
                if (U.compareAndSwapObject(h, WCOWAIT, c, c.cowait) && //CAS更新头结点的cowait
                    (w = c.thread) != null)
                    U.unpark(w);
            }
        }
        if (whead == h) {
            //检查队列稳定性
            if ((np = node.prev) != p) {
                if (np != null)
                    (p = np).next = node;   // stale
            }
            else if ((ps = p.status) == 0)
                U.compareAndSwapInt(p, WSTATUS, 0, WAITING);
            else if (ps == CANCELLED) {//尾节点取消，更新尾节点的前继节点为p.prev，继续自旋
                if ((pp = p.prev) != null) {
                    node.prev = pp;
                    pp.next = node;
                }
            }
            else {
                long time; // 0 argument to park means no timeout
                if (deadline == 0L)
                    time = 0L;
                else if ((time = deadline - System.nanoTime()) <= 0L)
                    return cancelWaiter(node, node, false);//超时，取消等待
                Thread wt = Thread.currentThread();
                U.putObject(wt, PARKBLOCKER, this);
                node.thread = wt;
                if (p.status < 0 && (p != h || (state & ABITS) != 0L) &&
                    whead == h && node.prev == p)
                    U.park(false, time);  // emulate LockSupport.park
                node.thread = null;
                U.putObject(wt, PARKBLOCKER, null);
                if (interruptible && Thread.interrupted())
                    return cancelWaiter(node, node, true);//中断，取消等待
            }
        }
    }
}    
```

获取写锁，如果锁可用(`(state & ABITS) == 0L`)则直接获取写锁并返回stamp，否则调用`acquireWrite`等待锁可用，`acquireWrite`主要由两个自旋组成。StampedLock的写锁是不可重入锁。请求该锁成功后会返回一个stamp 票据变量来表示该锁的版本 。

* 第一个自旋流程，使当前线程进入等待队列的尾节点。 
* 第二个自旋，节点依次获取写锁，直到当前线程所在节点的前继节点(prev)为头结点时，如果锁可用，则说明可以获取锁，获取成功返回stamp
* 如果在自旋中未能成功获取到锁，并且线程被中断或者等待超时，则调用`cancelWaiter`方法取消节点的等待，`cancelWaiter`后面会分析。

 ## unlockWrite() 

 ```java
/**
     * state匹配stamp则释放写锁，
     * @throws IllegalMonitorStateException  不匹配则抛出异常
     */
    public void unlockWrite(long stamp) {
        WNode h;
        //state不匹配stamp  或者 没有写锁
        if (state != stamp || (stamp & WBIT) == 0L)
            throw new IllegalMonitorStateException();
        //state += WBIT， 第8位置为0，但state & SBITS 会循环，一共有4个值
        state = (stamp += WBIT) == 0L ? ORIGIN : stamp;
        if ((h = whead) != null && h.status != 0)
            //唤醒继承者节点线程
            release(h);
    }
 ```

释放锁与加锁动作相反。将写标记位清零，如果state溢出，则退回到初始值； 

## **悲观锁readLock** 

```java
/**
 *  悲观读锁，非独占锁，为获得锁一直处于阻塞状态，直到获得锁为止
 */
public long readLock() {
    long s = state, next;  
    // 队列为空   && 没有写锁同时读锁数小于126  && CAS修改状态成功      则状态加1并返回，否则自旋获取读锁
    return ((whead == wtail && (s & ABITS) < RFULL &&
             U.compareAndSwapLong(this, STATE, s, next = s + RUNIT)) ?
            next : acquireRead(false, 0L));
}
```

是个共享锁，在没有线程获取独占写锁的情况下，同时多个线程可以获取该锁；如果已经有线程持有写锁，其他线程请求获取该锁会被阻塞，这类似ReentrantReadWriteLock 的读锁（不同在于这里的读锁是不可重入锁）。 

这里说的悲观是指在具体操作数据前，悲观的认为其他线程可能要对自己操作的数据进行修改，所以需要先对数据加锁，这是在读少写多的情况下的一种考虑，请求该锁成功后会返回一个stamp票据变量来表示该锁的版本.

```java
　/**
     * @param interruptible 是否允许中断
     * @param 标识超时限时（0代表不限时），然后进入循环。
     * @return next state, or INTERRUPTED
     */
    private long acquireRead(boolean interruptible, long deadline) {
        WNode node = null, p;
        //自旋
        for (int spins = -1;;) {
            WNode h;
            //判断队列为空
            if ((h = whead) == (p = wtail)) {
                //定义 long m,s,ns,并循环
                for (long m, s, ns;;) {
                    //将state超过 RFULL=126的值放到readerOverflow字段中
                    if ((m = (s = state) & ABITS) < RFULL ?
                        U.compareAndSwapLong(this, STATE, s, ns = s + RUNIT) :
                        (m < WBIT && (ns = tryIncReaderOverflow(s)) != 0L))
                        //获取锁成功返回
                        return ns;
                    //state高8位大于0，那么说明当前锁已经被写锁独占，那么我们尝试自旋  + 随机的方式来探测状态
                    else if (m >= WBIT) {
                        if (spins > 0) {
                            if (LockSupport.nextSecondarySeed() >= 0)
                                --spins;
                        }
                        else {
                            if (spins == 0) {
                                WNode nh = whead, np = wtail;
                                //一直获取锁失败，或者有线程入队列了退出内循环自旋，后续进入队列
                                if ((nh == h && np == p) || (h = nh) != (p = np))
                                    break;
                            }
                            //自旋 SPINS 次
                            spins = SPINS;
                        }
                    }
                }
            }
            if (p == null) { 
                //初始队列
                WNode hd = new WNode(WMODE, null);
                if (U.compareAndSwapObject(this, WHEAD, null, hd))
                    wtail = hd;
            }
            //当前节点为空则构建当前节点，模式为RMODE，前驱节点为p即尾节点。
            else if (node == null)
                node = new WNode(RMODE, p);
            //当前队列为空即只有一个节点（whead=wtail）或者当前尾节点的模式不是RMODE，那么我们会尝试在尾节点后面添加该节点作为尾节点，然后跳出外层循环
            else if (h == p || p.mode != RMODE) {
                if (node.prev != p)
                    node.prev = p;
                else if (U.compareAndSwapObject(this, WTAIL, p, node)) {
                    p.next = node;
                    //入队列成功，退出自旋
                    break;
                }
            }
            //队列不为空并且是RMODE模式， 添加该节点到尾节点的cowait链（实际上构成一个读线程stack）中
            else if (!U.compareAndSwapObject(p, WCOWAIT,
                                             node.cowait = p.cowait, node))
                //失败处理
                node.cowait = null;
            else {
                //通过CAS方法将该节点node添加至尾节点的cowait链中，node成为cowait中的顶元素，cowait构成了一个LIFO队列。
                //循环
                for (;;) {
                    WNode pp, c; Thread w;
                    //尝试unpark头元素（whead）的cowait中的第一个元素,假如是读锁会通过循环释放cowait链
                    if ((h = whead) != null && (c = h.cowait) != null &&
                        U.compareAndSwapObject(h, WCOWAIT, c, c.cowait) &&
                        (w = c.thread) != null) 

                        U.unpark(w);
                    //node所在的根节点p的前驱就是whead或者p已经是whead或者p的前驱为null
                    if (h == (pp = p.prev) || h == p || pp == null) {
                        long m, s, ns;
                        do {
                            //根据state再次积极的尝试获取锁
                            if ((m = (s = state) & ABITS) < RFULL ?
                                U.compareAndSwapLong(this, STATE, s,
                                                     ns = s + RUNIT) :
                                (m < WBIT &&
                                 (ns = tryIncReaderOverflow(s)) != 0L))
                                return ns;
                        } while (m < WBIT);//条件为读模式
                    }
                    if (whead == h && p.prev == pp) {
                        long time;
                        if (pp == null || h == p || p.status > 0) {
                            //这样做的原因是被其他线程闯入夺取了锁，或者p已经被取消
                            node = null; // throw away
                            break;
                        }
                        if (deadline == 0L)
                            time = 0L;
                        else if ((time = deadline - System.nanoTime()) <= 0L)
                            return cancelWaiter(node, p, false);
                        Thread wt = Thread.currentThread();
                        U.putObject(wt, PARKBLOCKER, this);
                        node.thread = wt;
                        if ((h != pp || (state & ABITS) == WBIT) &&
                            whead == h && p.prev == pp)
                            U.park(false, time);
                        node.thread = null;
                        U.putObject(wt, PARKBLOCKER, null);
                        //出现的中断情况下取消当前节点的cancelWaiter操作
                        if (interruptible && Thread.interrupted())
                            return cancelWaiter(node, p, true);
                    }
                }
            }
        }

        for (int spins = -1;;) {
            WNode h, np, pp; int ps;
            if ((h = whead) == p) {
                if (spins < 0)
                    spins = HEAD_SPINS;
                else if (spins < MAX_HEAD_SPINS)
                    spins <<= 1;
                for (int k = spins;;) { // spin at head
                    long m, s, ns;
                    if ((m = (s = state) & ABITS) < RFULL ?
                        U.compareAndSwapLong(this, STATE, s, ns = s + RUNIT) :
                        (m < WBIT && (ns = tryIncReaderOverflow(s)) != 0L)) {
                        WNode c; Thread w;
                        whead = node;
                        node.prev = null;
                        while ((c = node.cowait) != null) {
                            if (U.compareAndSwapObject(node, WCOWAIT,
                                                       c, c.cowait) &&
                                (w = c.thread) != null)
                                U.unpark(w);
                        }
                        return ns;
                    }
                    else if (m >= WBIT &&
                             LockSupport.nextSecondarySeed() >= 0 && --k <= 0)
                        break;
                }
            }
            else if (h != null) {
                WNode c; Thread w;
                while ((c = h.cowait) != null) {
                    if (U.compareAndSwapObject(h, WCOWAIT, c, c.cowait) &&
                        (w = c.thread) != null)
                        U.unpark(w);
                }
            }
            if (whead == h) {
                if ((np = node.prev) != p) {
                    if (np != null)
                        (p = np).next = node;   // stale
                }
                else if ((ps = p.status) == 0)
                    U.compareAndSwapInt(p, WSTATUS, 0, WAITING);
                else if (ps == CANCELLED) {
                    if ((pp = p.prev) != null) {
                        node.prev = pp;
                        pp.next = node;
                    }
                }
                else {
                    long time;
                    if (deadline == 0L)
                        time = 0L;
                    else if ((time = deadline - System.nanoTime()) <= 0L)
                        return cancelWaiter(node, node, false);
                    Thread wt = Thread.currentThread();
                    U.putObject(wt, PARKBLOCKER, this);
                    node.thread = wt;
                    if (p.status < 0 &&
                        (p != h || (state & ABITS) == WBIT) &&
                        whead == h && node.prev == p)
                        U.park(false, time);
                    node.thread = null;
                    U.putObject(wt, PARKBLOCKER, null);
                    if (interruptible && Thread.interrupted())
                        return cancelWaiter(node, node, true);
                }
            }
        }
    }
```

获取读锁，同样也是2个自旋。

* 第一个自旋，使当前线程进入等待队列的尾节点。注意这里跟获取写锁时的区别，**在获取写锁时，把当前线程所在的节点直接放入队尾；但是在获取读锁时，是把当前线程所在的节点放入尾节点的cowait节点里**。
* 第二个自旋，节点依次获取读锁。直到当前线程所在节点的前继节点(prev)为头结点时，如果有可用资源，则说明可以获取锁，获取成功返回stamp
* 如果在自旋中未能成功获取到锁，并且线程被中断或者等待超时，则调用`cancelWaiter`方法取消节点的等待。

 ## 乐观读锁 tryOptimisticRead

```java
/**
* 获取乐观读锁，返回邮票stamp
*/
public long tryOptimisticRead() {
    long s;  //有写锁返回0.   否则返回256
    return (((s = state) & WBIT) == 0L) ? (s & SBITS) : 0L;
}
```

 是相对于悲观锁来说的，在操作数据前并没有通过 CAS 设置锁的状态，仅仅是通过位运算测试；如果当前没有线程持有写锁，则简单的返回一个非 0 的 stamp 版本信息，

获取该 stamp 后在具体操作数据前还需要调用 validate 验证下该 stamp 是否已经不可用，也就是看当调用 tryOptimisticRead 返回 stamp 后，到当前时间是否有其它线程持有了写锁，如果是那么 validate 会返回 0，

否者就可以使用该 stamp 版本的锁对数据进行操作。由于 tryOptimisticRead 并没有使用 CAS 设置锁状态，所以不需要显示的释放该锁。

该锁的一个特点是适用于读多写少的场景，因为获取读锁只是使用位操作进行检验，不涉及 CAS 操作，所以效率会高很多，但是同时由于没有使用真正的锁，在保证数据一致性上需要拷贝一份要操作的变量到方法栈，并且在操作数据时候可能其它写线程已经修改了数据，

而我们操作的是方法栈里面的数据，也就是一个快照，所以最多返回的不是最新的数据，但是一致性还是得到保障的。

 ## 锁转换

StamedLock还支持这三种锁在一定条件下进行相互转换，例如long tryConvertToWriteLock(long stamp)期望把stamp标示的锁升级为写锁，这个函数会在下面几种情况下返回一个有效的 stamp（也就是晋升写锁成功）：　

* 当前锁已经是写锁模式了。
* 当前锁处于读锁模式，并且没有其他线程是读锁模式
* 当前处于乐观读模式，并且当前写锁可用。

 ```java
/**
     * state匹配stamp时, 执行下列操作之一. 
     *   1、stamp 已经持有写锁，直接返回.  
     *   2、读模式，但是没有更多的读取者，并返回一个写锁stamp.
     *   3、有一个乐观读锁，只在即时可用的前提下返回一个写锁stamp
     *   4、其他情况都返回0
     */
    public long tryConvertToWriteLock(long stamp) {
        long a = stamp & ABITS, m, s, next;
        //state匹配stamp
        while (((s = state) & SBITS) == (stamp & SBITS)) {
            //没有锁
            if ((m = s & ABITS) == 0L) {
                if (a != 0L)
                    break;
                //CAS修改状态为持有写锁，并返回
                if (U.compareAndSwapLong(this, STATE, s, next = s + WBIT))
                    return next;
            }
            //持有写锁
            else if (m == WBIT) {
                if (a != m)
                    //其他线程持有写锁
                    break;
                //当前线程已经持有写锁
                return stamp;
            }
            //有一个读锁
            else if (m == RUNIT && a != 0L) {
                //释放读锁，并尝试持有写锁
                if (U.compareAndSwapLong(this, STATE, s,
                                         next = s - RUNIT + WBIT))
                    return next;
            }
            else
                break;
        }
        return 0L;
    }
 ```

```java
/**
    *   state匹配stamp时, 执行下列操作之一.
        1、stamp 表示持有写锁，释放写锁，并持有读锁
stamp 表示持有读锁 ，返回该读锁
有一个乐观读锁，只在即时可用的前提下返回一个读锁stamp
        4、其他情况都返回0，表示失败
     *
     */
    public long tryConvertToReadLock(long stamp) {
        long a = stamp & ABITS, m, s, next; WNode h;
        //state匹配stamp
        while (((s = state) & SBITS) == (stamp & SBITS)) {
            //没有锁
            if ((m = s & ABITS) == 0L) {
                if (a != 0L)
                    break;
                else if (m < RFULL) {
                    if (U.compareAndSwapLong(this, STATE, s, next = s + RUNIT))
                        return next;
                }
                else if ((next = tryIncReaderOverflow(s)) != 0L)
                    return next;
            }
            //写锁
            else if (m == WBIT) {
                //非当前线程持有写锁
                if (a != m)
                    break;
                //释放写锁持有读锁
                state = next = s + (WBIT + RUNIT);
                if ((h = whead) != null && h.status != 0)
                    release(h);
                return next;
            }
            //持有读锁
            else if (a != 0L && a < WBIT)
                return stamp;
            else
                break;
        }
        return 0L;
    }
```

## cancelWaiter(WNode node, WNode group, boolean interrupted)

```java
//取消给定节点
private long cancelWaiter(WNode node, WNode group, boolean interrupted) {
    if (node != null && group != null) {
        Thread w;
        node.status = CANCELLED;//修改节点状态
        // unsplice cancelled nodes from group
        //依次解除已经取消的cowait节点的链接
        for (WNode p = group, q; (q = p.cowait) != null;) {
            if (q.status == CANCELLED) {
                U.compareAndSwapObject(p, WCOWAIT, q, q.cowait);
                p = group; // restart
            }
            else
                p = q;
        }
        if (group == node) {
            //依次唤醒节点上的未取消的cowait节点线程
            for (WNode r = group.cowait; r != null; r = r.cowait) {
                if ((w = r.thread) != null)
                    U.unpark(w);       // wake up uncancelled co-waiters
            }
            //
            for (WNode pred = node.prev; pred != null; ) { // unsplice
                WNode succ, pp;        // find valid successor
                while ((succ = node.next) == null ||
                       succ.status == CANCELLED) { //后继节点为空或者已经取消，则去查找一个有效的后继节点
                    WNode q = null;    // find successor the slow way
                    //从尾节点开始往前查找距离node节点最近的一个有效节点q
                    for (WNode t = wtail; t != null && t != node; t = t.prev)
                        if (t.status != CANCELLED)
                            q = t;     // don't link if succ cancelled
                    if (succ == q ||   // ensure accurate successor
                            //运行到这里说明从node到“距离node最近的一个有效节点q”之间可能存在已经取消的节点
                            // CAS替换node的后继节点为“距离node最近的一个有效节点”，也就是说解除了“所有已经取消但是还存在在链表上的无效节点”的链接
                        U.compareAndSwapObject(node, WNEXT,
                                               succ, succ = q)) {
                        if (succ == null && node == wtail) {
                            //运行到这里说明node为尾节点，
                            //利用CAS先修改尾节点为node的前继有效节点，后面再解除node的链接
                            U.compareAndSwapObject(this, WTAIL, node, pred);
                        }
                        break;
                    }
                }
                //解除node节点的链接
                if (pred.next == node) // unsplice pred link
                    U.compareAndSwapObject(pred, WNEXT, node, succ);
                //唤醒后继节点的线程
                if (succ != null && (w = succ.thread) != null) {
                    succ.thread = null;
                    U.unpark(w);       // wake up succ to observe new pred
                }
                //如果前继节点已经取消，向前查找一个有效节点继续循环，如果这个节点为空则直接跳出循环
                if (pred.status != CANCELLED || (pp = pred.prev) == null)
                    break;
                node.prev = pp;        // repeat if new pred wrong/cancelled
                U.compareAndSwapObject(pp, WNEXT, pred, succ);
                pred = pp;
            }
        }
    }
    //检查是否可唤醒head节点的后继节点线程
    WNode h; // Possibly release first waiter
    while ((h = whead) != null) {
        long s; WNode q; // similar to release() but check eligibility
        if ((q = h.next) == null || q.status == CANCELLED) {
            //从尾节点向前查找一个未取消的节点，作为头节点的next节点
            for (WNode t = wtail; t != null && t != h; t = t.prev)
                if (t.status <= 0)
                    q = t;
        }
        if (h == whead) {
            if (q != null && h.status == 0 &&
                ((s = state) & ABITS) != WBIT && // waiter is eligible
                (s == 0L || q.mode == RMODE))//锁可用，或者后继节点是读线程
                release(h);//可以唤醒头节点的后继节点线程
            break;
        }
    }
    return (interrupted || Thread.interrupted()) ? INTERRUPTED : 0L;
}
```

如果节点线程被中断或者等待超时，需要取消节点的链接。大概的操作就是首先修改节点为取消状态，然后解除它在等待队列中的链接，并且唤醒节点上所有等待读的线程(也就是cowait节点)；最后如果锁可用，帮助唤醒头节点的后继节点的线程 .

**重点介绍一下cancelWaiter的前两个参数node和group：**

* 如果`node!=group`，说明node节点是group节点上的一个cowait节点（如果不明白请见上面代码中对`acquireRead`方法中的`U.compareAndSwapObject(p, WCOWAIT,node.cowait = p.cowait, node)`这一行代码的注释），这种情况下首先修改node节点的状态(`node.status = CANCELLED`)，然后直接操作group节点，依次解除group节点上已经取消的cowait节点的链接。最后如果锁可用，帮助唤醒头节点的后继节点的线程。
* 如果`node==group`，说明在node节点之前的节点为写线程节点，这时需要进行以下操作：
  *  依次唤醒node节点上的未取消的cowait节点线程
  * 解除node节点和一段节点（node节点到“距离node最近的一个有效节点”）的链接
  * 最后如果锁可用，帮助唤醒头节点的后继节点的线程。

 

 

 

 

 

 

 

 

 

 

