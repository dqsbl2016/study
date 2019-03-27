> Phaser是JDK 7新增的一个同步辅助类，在功能上跟CyclicBarrier和CountDownLatch差不多，但支持更丰富的用法。 

# 实现思想

Phaser中定义了一个阶段的概念（用phaser表示），可以增加阶段，但是不能减少。每个阶段有不同数量的分阶段（用party表示），当有足够数量的分阶段到达的时候就会进入下一阶段。

实现多个线程，每个线程中可以分阶段同步执行（全部完成一个阶段后再同时开始下一个阶段）。

# 构造函数

```java
public Phaser() {
    this(null, 0);
}
public Phaser(int parties) {
    this(null, parties);
}
public Phaser(Phaser parent) {
    this(parent, 0);
}
public Phaser(Phaser parent, int parties) {
    if (parties >>> PARTIES_SHIFT != 0)
        throw new IllegalArgumentException("Illegal number of parties");
    int phase = 0;
    this.parent = parent;
    if (parent != null) {
        final Phaser root = parent.root;
        this.root = root;
        this.evenQ = root.evenQ;
        this.oddQ = root.oddQ;
        if (parties != 0)
            phase = parent.doRegister(1);
    }
    else {
        this.root = this;
        this.evenQ = new AtomicReference<QNode>();
        this.oddQ = new AtomicReference<QNode>();
    }
    this.state = (parties == 0) ? (long)EMPTY :
    ((long)phase << PHASE_SHIFT) |
        ((long)parties << PARTIES_SHIFT) |
        ((long)parties);
}
```

构造方法主要是建立阶段(phaser),通过参数可以建立父子类的phaser。并且设置了这个阶段有多少个分阶段（parties）。

# 核心参数及方法

```java
private volatile long state;
/**
 * The parent of this phaser, or null if none
 */
private final Phaser parent;
/**
 * The root of phaser tree. Equals this if not in a tree.
 */
private final Phaser root;
//等待线程的栈顶元素，根据phase取模定义为一个奇数header和一个偶数header
private final AtomicReference<QNode> evenQ;
private final AtomicReference<QNode> oddQ;
```

**state状态说明：**
Phaser使用一个long型state值来标识内部状态：

- 低0-15位表示未到达parties数；
- 中16-31位表示等待的parties数；
- 中32-62位表示phase当前代；
- 高63位表示当前phaser的终止状态。

**注意：** Qnode是Phaser定义的内部等待队列，用于在阻塞时记录等待线程及相关信息。实现了ForkJoinPool的一个内部接口ManagedBlocker，上面已经说过，Phaser也可能被ForkJoinPool中的任务使用，这样在其他任务阻塞等待一个phase时可以保证足够的并行度来执行任务(通过内部实现方法isReleasable和block)。

 ```java
//构造方法
public Phaser() {
    this(null, 0);
}
public Phaser(int parties) {
    this(null, parties);
}
public Phaser(Phaser parent) {
    this(parent, 0);
}
public Phaser(Phaser parent, int parties)
//注册一个新的party
public int register()
//批量注册
public int bulkRegister(int parties)
//使当前线程到达phaser，不等待其他任务到达。返回arrival phase number
public int arrive() 
//使当前线程到达phaser并撤销注册，返回arrival phase number
public int arriveAndDeregister()
/*
 * 使当前线程到达phaser并等待其他任务到达，等价于awaitAdvance(arrive())。
 * 如果需要等待中断或超时，可以使用awaitAdvance方法完成一个类似的构造。
 * 如果需要在到达后取消注册，可以使用awaitAdvance(arriveAndDeregister())。
 */
public int arriveAndAwaitAdvance()
//等待给定phase数，返回下一个 arrival phase number
public int awaitAdvance(int phase)
//阻塞等待，直到phase前进到下一代，返回下一代的phase number
public int awaitAdvance(int phase) 
//响应中断版awaitAdvance
public int awaitAdvanceInterruptibly(int phase) throws InterruptedException
public int awaitAdvanceInterruptibly(int phase, long timeout, TimeUnit unit)
    throws InterruptedException, TimeoutException
//使当前phaser进入终止状态，已注册的parties不受影响，如果是分层结构，则终止所有phaser
public void forceTermination()
 ```

# 源码分析

## register()

```java
//注册一个新的party
public int register() {
    return doRegister(1);
}
private int doRegister(int registrations) {
    // adjustment to state
    long adjust = ((long)registrations << PARTIES_SHIFT) | registrations;
    final Phaser parent = this.parent;
    int phase;
    for (;;) {
        long s = (parent == null) ? state : reconcileState();
        int counts = (int)s;
        int parties = counts >>> PARTIES_SHIFT;//获取已注册parties数
        int unarrived = counts & UNARRIVED_MASK;//未到达数
        if (registrations > MAX_PARTIES - parties)
            throw new IllegalStateException(badRegister(s));
        phase = (int)(s >>> PHASE_SHIFT);//获取当前代
        if (phase < 0)
            break;
        if (counts != EMPTY) {                  // not 1st registration
            if (parent == null || reconcileState() == s) {
                if (unarrived == 0)             // wait out advance
                    root.internalAwaitAdvance(phase, null);//等待其他任务到达
                else if (UNSAFE.compareAndSwapLong(this, stateOffset,
                                                   s, s + adjust))//更新注册的parties数
                    break;
            }
        }
        else if (parent == null) {              // 1st root registration
            long next = ((long)phase << PHASE_SHIFT) | adjust;
            if (UNSAFE.compareAndSwapLong(this, stateOffset, s, next))//更新phase
                break;
        }
        else {
            //分层结构，子phaser首次注册用父节点管理
            synchronized (this) {               // 1st sub registration
                if (state == s) {               // recheck under lock
                    phase = parent.doRegister(1);//分层结构，使用父节点注册
                    if (phase < 0)
                        break;
                    // finish registration whenever parent registration
                    // succeeded, even when racing with termination,
                    // since these are part of the same "transaction".
                    //由于在同一个事务里，即使phaser已终止，也会完成注册
                    while (!UNSAFE.compareAndSwapLong
                           (this, stateOffset, s,
                            ((long)phase << PHASE_SHIFT) | adjust)) {//更新phase
                        s = state;
                        phase = (int)(root.state >>> PHASE_SHIFT);
                        // assert (int)s == EMPTY;
                    }
                    break;
                }
            }
        }
    }
    return phase;
}
```

**说明：** `register`方法为phaser添加一个新的party，如果`onAdvance`正在运行，那么这个方法会等待它运行结束再返回结果。如果当前phaser有父节点，并且当前phaser上没有已注册的party，那么就会交给父节点注册。
 `register`和`bulkRegister`都由doRegister实现，大概流程如下：

* 如果当前操作不是首次注册，那么直接在当前phaser上更新注册parties数
* 如果是首次注册，并且当前phaser没有父节点，说明是root节点注册，直接更新phase
* 如果当前操作是首次注册，并且当前phaser由父节点，则注册操作交由父节点，并更新当前phaser的phase

子Phaser的phase在没有被真正使用之前，允许滞后于它的root节点。非首次注册时，如果Phaser有父节点，则调用`reconcileState()`方法解决root节点的phase延迟传递问题， 

 ```java
private long reconcileState() {
    final Phaser root = this.root;
    long s = state;
    if (root != this) {
        int phase, p;
        // CAS to root phase with current parties, tripping unarrived
        while ((phase = (int)(root.state >>> PHASE_SHIFT)) !=
               (int)(s >>> PHASE_SHIFT) &&
               !UNSAFE.compareAndSwapLong
               (this, stateOffset, s,
                s = (((long)phase << PHASE_SHIFT) |
                     ((phase < 0) ? (s & COUNTS_MASK) :
                      (((p = (int)s >>> PARTIES_SHIFT) == 0) ? EMPTY :
                       ((s & PARTIES_MASK) | p))))))
            s = state;
    }
    return s;
}
 ```

当root节点的phase已经advance到下一代，但是子节点phaser还没有，这种情况下它们必须通过更新未到达parties数 完成它们自己的advance操作(如果parties为0，重置为`EMPTY`状态)。

* 回到register方法的第一步，如果当前未到达数为0，说明上一代phase正在进行到达操作，此时调用`internalAwaitAdvance()`方法等待其他任务完成到达操作，

 ```java
//阻塞等待phase到下一代
private int internalAwaitAdvance(int phase, QNode node) {
    // assert root == this;
    releaseWaiters(phase-1);          // ensure old queue clean
    boolean queued = false;           // true when node is enqueued
    int lastUnarrived = 0;            // to increase spins upon change
    int spins = SPINS_PER_ARRIVAL;
    long s;
    int p;
    while ((p = (int)((s = state) >>> PHASE_SHIFT)) == phase) {
        if (node == null) {           // spinning in noninterruptible mode
            int unarrived = (int)s & UNARRIVED_MASK;//未到达数
            if (unarrived != lastUnarrived &&
                (lastUnarrived = unarrived) < NCPU)
                spins += SPINS_PER_ARRIVAL;
            boolean interrupted = Thread.interrupted();
            if (interrupted || --spins < 0) { // need node to record intr
                //使用node记录中断状态
                node = new QNode(this, phase, false, false, 0L);
                node.wasInterrupted = interrupted;
            }
        }
        else if (node.isReleasable()) // done or aborted
            break;
        else if (!queued) {           // push onto queue
            AtomicReference<QNode> head = (phase & 1) == 0 ? evenQ : oddQ;
            QNode q = node.next = head.get();
            if ((q == null || q.phase == phase) &&
                (int)(state >>> PHASE_SHIFT) == phase) // avoid stale enq
                queued = head.compareAndSet(q, node);
        }
        else {
            try {
                ForkJoinPool.managedBlock(node);//阻塞给定node
            } catch (InterruptedException ie) {
                node.wasInterrupted = true;
            }
        }
    }

    if (node != null) {
        if (node.thread != null)
            node.thread = null;       // avoid need for unpark()
        if (node.wasInterrupted && !node.interruptible)
            Thread.currentThread().interrupt();
        if (p == phase && (p = (int)(state >>> PHASE_SHIFT)) == phase)
            return abortWait(phase); // possibly clean up on abort
    }
    releaseWaiters(phase);
    return p;
}
 ```

第二个参数node，如果不为空，则说明等待线程需要追踪中断状态或超时状态。以`doRegister`中的调用为例，不考虑线程争用，`internalAwaitAdvance`大概流程如下：

* 首先调用`releaseWaiters`唤醒上一代所有等待线程，确保旧队列中没有遗留的等待线程。
* 循环`SPINS_PER_ARRIVAL`指定的次数或者当前线程被中断，创建node记录等待线程及相关信息。
* 继续循环调用ForkJoinPool.managedBlock运行被阻塞的任务
* 继续循环，阻塞任务运行成功被释放，跳出循环
* 最后唤醒当前phase的线程

## arrive()

 ```java
//使当前线程到达phaser，不等待其他任务到达。返回arrival phase number
public int arrive() {
    return doArrive(ONE_ARRIVAL);
}

private int doArrive(int adjust) {
    final Phaser root = this.root;
    for (;;) {
        long s = (root == this) ? state : reconcileState();
        int phase = (int)(s >>> PHASE_SHIFT);
        if (phase < 0)
            return phase;
        int counts = (int)s;
        //获取未到达数
        int unarrived = (counts == EMPTY) ? 0 : (counts & UNARRIVED_MASK);
        if (unarrived <= 0)
            throw new IllegalStateException(badArrive(s));
        if (UNSAFE.compareAndSwapLong(this, stateOffset, s, s-=adjust)) {//更新state
            if (unarrived == 1) {//当前为最后一个未到达的任务
                long n = s & PARTIES_MASK;  // base of next state
                int nextUnarrived = (int)n >>> PARTIES_SHIFT;
                if (root == this) {
                    if (onAdvance(phase, nextUnarrived))//检查是否需要终止phaser
                        n |= TERMINATION_BIT;
                    else if (nextUnarrived == 0)
                        n |= EMPTY;
                    else
                        n |= nextUnarrived;
                    int nextPhase = (phase + 1) & MAX_PHASE;
                    n |= (long)nextPhase << PHASE_SHIFT;
                    UNSAFE.compareAndSwapLong(this, stateOffset, s, n);
                    releaseWaiters(phase);//释放等待phase的线程
                }
                //分层结构，使用父节点管理arrive
                else if (nextUnarrived == 0) { //propagate deregistration
                    phase = parent.doArrive(ONE_DEREGISTER);
                    UNSAFE.compareAndSwapLong(this, stateOffset,
                                              s, s | EMPTY);
                }
                else
                    phase = parent.doArrive(ONE_ARRIVAL);
            }
            return phase;
        }
    }
}
 ```

`arrive`方法手动调整到达数，使当前线程到达phaser。`arrive`和`arriveAndDeregister`都调用了`doArrive`实现，大概流程如下：

* 首先更新`state(state - adjust)`；
* 如果当前不是最后一个未到达的任务，直接返回phase
* 如果当前是最后一个未到达的任务：
  * 如果当前是root节点，判断是否需要终止phaser，`CAS`更新phase，最后释放等待的线程；
  * 如果是分层结构，并且已经没有下一代未到达的parties，则交由父节点处理`doArrive`逻辑，然后更新state为`EMPTY`。

 ## arriveAndAwaitAdvance()

```java
public int arriveAndAwaitAdvance() {
    // Specialization of doArrive+awaitAdvance eliminating some reads/paths
    final Phaser root = this.root;
    for (;;) {
        long s = (root == this) ? state : reconcileState();
        int phase = (int)(s >>> PHASE_SHIFT);
        if (phase < 0)
            return phase;
        int counts = (int)s;
        int unarrived = (counts == EMPTY) ? 0 : (counts & UNARRIVED_MASK);//获取未到达数
        if (unarrived <= 0)
            throw new IllegalStateException(badArrive(s));
        if (UNSAFE.compareAndSwapLong(this, stateOffset, s,
                                      s -= ONE_ARRIVAL)) {//更新state
            if (unarrived > 1)
                return root.internalAwaitAdvance(phase, null);//阻塞等待其他任务
            if (root != this)
                return parent.arriveAndAwaitAdvance();//子Phaser交给父节点处理
            long n = s & PARTIES_MASK;  // base of next state
            int nextUnarrived = (int)n >>> PARTIES_SHIFT;
            if (onAdvance(phase, nextUnarrived))//全部到达，检查是否可销毁
                n |= TERMINATION_BIT;
            else if (nextUnarrived == 0)
                n |= EMPTY;
            else
                n |= nextUnarrived;
            int nextPhase = (phase + 1) & MAX_PHASE;//计算下一代phase
            n |= (long)nextPhase << PHASE_SHIFT;
            if (!UNSAFE.compareAndSwapLong(this, stateOffset, s, n))//更新state
                return (int)(state >>> PHASE_SHIFT); // terminated
            releaseWaiters(phase);//释放等待phase的线程
            return nextPhase;
        }
    }
}
```

使当前线程到达phaser并等待其他任务到达，等价于`awaitAdvance(arrive())`。如果需要等待中断或超时，可以使用`awaitAdvance`方法完成一个类似的构造。如果需要在到达后取消注册，可以使用`awaitAdvance(arriveAndDeregister())`。效果类似于`CyclicBarrier.await`。大概流程如下：

* 更新state(state - 1)；
* 如果未到达数大于1，调用`internalAwaitAdvance`阻塞等待其他任务到达，返回当前phase
* 如果为分层结构，则交由父节点处理`arriveAndAwaitAdvance`逻辑
* 如果未到达数<=1，判断phaser终止状态，CAS更新phase到下一代，最后释放等待当前phase的线程，并返回下一代phase。

 ##  awaitAdvance(int phase)

```java
public int awaitAdvance(int phase) {
    final Phaser root = this.root;
    long s = (root == this) ? state : reconcileState();
    int p = (int)(s >>> PHASE_SHIFT);
    if (phase < 0)
        return phase;
    if (p == phase)
        return root.internalAwaitAdvance(phase, null);
    return p;
}
//响应中断版awaitAdvance
public int awaitAdvanceInterruptibly(int phase)
    throws InterruptedException {
    final Phaser root = this.root;
    long s = (root == this) ? state : reconcileState();
    int p = (int)(s >>> PHASE_SHIFT);
    if (phase < 0)
        return phase;
    if (p == phase) {
        QNode node = new QNode(this, phase, true, false, 0L);
        p = root.internalAwaitAdvance(phase, node);
        if (node.wasInterrupted)
            throw new InterruptedException();
    }
    return p;
}
```

`awaitAdvance`用于阻塞等待线程到达，直到phase前进到下一代，返回下一代的phase number。方法很简单，不多赘述。`awaitAdvanceInterruptibly`方法是响应中断版的awaitAdvance，不同之处在于，调用阻塞时会记录线程的中断状态。 



> 使用 https://www.jianshu.com/p/ce81b6736e01

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 