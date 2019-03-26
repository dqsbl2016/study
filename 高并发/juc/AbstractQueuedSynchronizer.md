> AbstractQueuedSynchronizer，简称AQS。它提供了一个基于FIFO队列，可以用于构建锁或者其他相关同步装置的基础框架。  在基于AQS构建的同步器中，只可能在一个时刻发生阻塞，从而降低上下文切换的开销，并提高吞吐量。 

# **AbstractQueuedSynchronizer**

AbstractQueuedSynchronizer类有两个内部类，分别为Node类与ConditionObject类。 

## Node内部类

```java
static final class Node {
        // 模式，分为共享与独占
        // 共享模式
        static final Node SHARED = new Node();
        // 独占模式
        static final Node EXCLUSIVE = null;        
        // 结点状态
        // CANCELLED，值为1，表示当前的线程被取消
        // SIGNAL，值为-1，表示当前节点的后继节点包含的线程需要运行，也就是unpark
        // CONDITION，值为-2，表示当前节点在等待condition，也就是在condition队列中
        // PROPAGATE，值为-3，表示当前场景下后续的acquireShared能够得以执行
        // 值为0，表示当前节点在sync队列中，等待着获取锁
        static final int CANCELLED =  1;
        static final int SIGNAL    = -1;
        static final int CONDITION = -2;
        static final int PROPAGATE = -3;        

        // 结点状态
        volatile int waitStatus;        
        // 前驱结点
        volatile Node prev;    
        // 后继结点
        volatile Node next;        
        // 结点所对应的线程
        volatile Thread thread;        
        // 下一个等待者
        Node nextWaiter;
        
        // 结点是否在共享模式下等待
        final boolean isShared() {
            return nextWaiter == SHARED;
        }
        
        // 获取前驱结点，若前驱结点为空，抛出异常
        final Node predecessor() throws NullPointerException {
            // 保存前驱结点
            Node p = prev; 
            if (p == null) // 前驱结点为空，抛出异常
                throw new NullPointerException();
            else // 前驱结点不为空，返回
                return p;
        }
        
        // 无参构造函数
        Node() {    // Used to establish initial head or SHARED marker
        }
        
        // 构造函数
         Node(Thread thread, Node mode) {    // Used by addWaiter
            this.nextWaiter = mode;
            this.thread = thread;
        }
        
        // 构造函数
        Node(Thread thread, int waitStatus) { // Used by Condition
            this.waitStatus = waitStatus;
            this.thread = thread;
        }
    }
```

每个被阻塞的线程都会被封装成一个Node节点，放入队列。Node中会记录线程/状态等内容。



## ConditionObject内部类 

```java
 public class ConditionObject implements Condition, java.io.Serializable {
        // 版本号
        private static final long serialVersionUID = 1173984872572414699L;
        /** First node of condition queue. */
        // condition队列的头结点
        private transient Node firstWaiter;
        /** Last node of condition queue. */
        // condition队列的尾结点
        private transient Node lastWaiter;

        /**
         * Creates a new {@code ConditionObject} instance.
         */
        // 构造函数
        public ConditionObject() { }
     ...
 }
比较长，参见源码文件
```

ConditionObject类实现了Condition接口，而Condition接口中定义了条件操作规范。

```java
public interface Condition {
    // 等待，当前线程在接到信号或被中断之前一直处于等待状态
    void await() throws InterruptedException;
    // 等待，当前线程在接到信号之前一直处于等待状态，不响应中断
    void awaitUninterruptibly();
    //等待，当前线程在接到信号、被中断或到达指定等待时间之前一直处于等待状态 
    long awaitNanos(long nanosTimeout) throws InterruptedException;
    // 等待，当前线程在接到信号、被中断或到达指定等待时间之前一直处于等待状态。此方法在行为上等效于：awaitNanos(unit.toNanos(time)) > 0
    boolean await(long time, TimeUnit unit) throws InterruptedException;
    // 等待，当前线程在接到信号、被中断或到达指定最后期限之前一直处于等待状态
    boolean awaitUntil(Date deadline) throws InterruptedException;
    // 唤醒一个等待线程。如果所有的线程都在等待此条件，则选择其中的一个唤醒。在从 await 返回之前，该线程必须重新获取锁。
    void signal();
    // 唤醒所有等待线程。如果所有的线程都在等待此条件，则唤醒所有线程。在从 await 返回之前，每个线程都必须重新获取锁。
    void signalAll();
}
```

## 数据结构

基于`Node`与`ConditionObject`，`AbstractQueuedSynchronizer`的内部实现了两种队列。

* `同步队列（Sync Queue）` -- 排队申请同步状态
  * 基于Node的双向链表，使用prev前指向，next后指向，在线程获取资源失败后，进入同步队列队尾保持自旋等待状态， 在同步队列中的线程在自旋时会判断其前节点是否为head节点，如果为head节点则不断尝试获取资源/锁，获取成功则退出同步队列。当线程执行完逻辑后，会释放资源/锁，释放后唤醒其后继节点。 
* `条件队列 (Condition Queue)` --等待队列
  * 基于Node与ConditionObject的单向链表，使用nextWaiter后指向，为Lock实现的一个基础同步器，并且一个线程可能会有多个条件队列，只有在使用了Condition才会存在条件队列。 

> 当调用了await()系列的方法后（类似于Object中wait()等待方法），就会在将当前线程节点从同步队列中取出，然后放入条件等待队列尾部插入这个节点，通知唤醒的时候会把这个节点从等待队列转移到同步队列。 

## 主要变量

```java
// 模式，分为共享与独占
// 共享模式
static final Node SHARED = new Node();
// 独占模式
static final Node EXCLUSIVE = null;        
// 结点状态
// CANCELLED，值为1，表示当前的线程被取消
// SIGNAL，值为-1，表示当前节点的后继节点包含的线程需要运行，也就是unpark
// CONDITION，值为-2，表示当前节点在等待condition，也就是在condition队列中
// PROPAGATE，值为-3，表示当前场景下后续的acquireShared能够得以执行
// 值为0，表示当前节点在sync队列中，等待着获取锁
static final int CANCELLED =  1;
static final int SIGNAL    = -1;
static final int CONDITION = -2;
static final int PROPAGATE = -3;       
```

## 主要方法

### acquire(int)

```java
//独占模式获取资源
public final void acquire(int arg) {
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```

独占模式下获取资源/锁，忽略中断的影响。

* `tryAcquire()` 尝试直接获取资源，如果成功则直接返回，失败进入第二步；
* `addWaiter()` 获取资源失败后，将当前线程加入等待队列的尾部，并标记为独占模式；
* `acquireQueued()` 使线程在等待队列中自旋等待获取资源，一直获取到资源后才返回。如果在等待过程中被中断过，则返回true，否则返回false。
* 如果线程在等待过程中被中断(interrupt)是不响应的，在获取资源成功之后根据返回的中断状态调用`selfInterrupt()`方法再把中断状态补上。

### tryAcquire(int)

```java
//尝试获取锁   无实现，具体实现在自定义的同步器中实现
protected boolean tryAcquire(int arg) {
    throw new UnsupportedOperationException();
}
```

### addWaiter(Node)

```java
//添加等待节点到尾部
private Node addWaiter(Node mode) {
    Node node = new Node(Thread.currentThread(), mode);
    // Try the fast path of enq; backup to full enq on failure
    //尝试快速入队
    Node pred = tail;
    if (pred != null) {
        node.prev = pred;
        if (compareAndSetTail(pred, node)) {
            pred.next = node;
            return node;
        }
    }
    enq(node);
    return node;
}
//插入给定节点到队尾
private Node enq(final Node node) {
    for (;;) {
        Node t = tail;
        if (t == null) { // Must initialize
            if (compareAndSetHead(new Node()))
                tail = head;
        } else {
            node.prev = t;
            if (compareAndSetTail(t, node)) {
                t.next = node;
                return t;
            }
        }
    }
}
```

获取独占锁失败后，将当前线程加入等待队列的尾部，并标记为独占模式。返回插入的等待节点。 

### acquireQueued(Node,int)

```java
//自旋等待获取资源
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();//获取前继节点
            //前继节点为head，说明可以尝试获取资源
            if (p == head && tryAcquire(arg)) {
                setHead(node);//获取成功，更新head节点
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            //检查是否可以park
            if (shouldParkAfterFailedAcquire(p, node) && parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}

//获取资源失败后，检查并更新等待状态
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
    int ws = pred.waitStatus;
    if (ws == Node.SIGNAL)
        /*
         * This node has already set status asking a release
         * to signal it, so it can safely park.
         */
        return true;
    if (ws > 0) {
        /*
         * Predecessor was cancelled. Skip over predecessors and
         * indicate retry.
         */
        //如果前节点取消了，那就一直往前找到一个等待状态的节点，并排在它的后边
        do {
            node.prev = pred = pred.prev;
        } while (pred.waitStatus > 0);
        pred.next = node;
    } else {
        /*
         * waitStatus must be 0 or PROPAGATE.  Indicate that we
         * need a signal, but don't park yet.  Caller will need to
         * retry to make sure it cannot acquire before parking.
         */
        //此时前节点状态为0或PROPAGATE，表示我们需要一个唤醒信号，但是不立即park,在park前调用者需要重试来确认它不能获取资源。
        compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    }
    return false;
}
//阻塞当前线程，返回中断状态
private final boolean parkAndCheckInterrupt() {
    LockSupport.park(this);
    return Thread.interrupted();
}
```

线程进入等待队列后，在等待队列中自旋等待获取资源。如果在整个等待过程中被中断过，则返回true，否则返回false。 

* 获取当前等待节点的前继节点，如果前继节点为head，说明可以尝试获取锁；
* 调用`tryAcquire`获取锁，成功后更新`head`为当前节点；
* 获取资源失败，调用`shouldParkAfterFailedAcquire`方法检查并更新等待状态。如果前继节点状态为`SIGNAL`，说明当前节点可以进入waiting状态等待唤醒；被唤醒后，继续自旋重复上述步骤。
* 获取资源成功后返回中断状态。

 当前线程通过`parkAndCheckInterrupt()`阻塞之后进入waiting状态，此状态下可以通过下面两种途径唤醒线程：

* 前继节点释放资源后，通过`unparkSuccessor()`方法unpark当前线程；
* 当前线程被中断。

 ### release(int)

```jav
/**独占模式释放资源*/
public final boolean release(int arg) {
    if (tryRelease(arg)) {//尝试释放资源
        Node h = head;//头结点
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);//唤醒head的下一个节点
        return true;
    }
    return false;
}
```

独占模式下释放指定量的资源，成功释放后调用`unparkSuccessor`唤醒head的下一个节点。 

 ### tryRelease(int)

```java
//尝试释放资源   无实现，具体实现在自定义的同步器中实现
protected boolean tryRelease(int arg) {
    throw new UnsupportedOperationException();
}
```

### unparkSuccessor(Node)

```java
private void unparkSuccessor(Node node) {
    int ws = node.waitStatus;
    if (ws < 0)//当前节点没有被取消,更新waitStatus为0。
        compareAndSetWaitStatus(node, ws, 0);

    Node s = node.next;//找到下一个需要唤醒的结点
    if (s == null || s.waitStatus > 0) {
        s = null;
        //next节点为空，从tail节点开始向前查找有效节点
        for (Node t = tail; t != null && t != node; t = t.prev)
            if (t.waitStatus <= 0)
                s = t;
    }
    if (s != null)
        LockSupport.unpark(s.thread);
}
```

成功获取到资源后，调用此方法唤醒head的下一个节点。因为当前节点已经释放掉资源，下一个等待的线程可以被唤醒继续获取资源。 

### acquireShared(int)

```java
public final void acquireShared(int arg) {
    if (tryAcquireShared(arg) < 0)
        doAcquireShared(arg);
}
```

共享模式下获取资源/锁，忽略中断的影响。内部主要调用了两个个方法，其中`tryAcquireShared`需要自定义同步器实现。后面会对各个方法进行详细分析。`acquireShared`方法流程如下：

*  `tryAcquireShared(arg)` 尝试获取共享资源。**成功获取并且还有可用资源返回正数；成功获取但是没有可用资源时返回0；获取资源失败返回一个负数。** 
* 获取资源失败后调用`doAcquireShared`方法进入等待队列，获取资源后返回。

 ### tryAcquireShared(int arg)

```java
//共享模式下获取资源  无具体实现  在具体同步器中是实现
protected int tryAcquireShared(int arg) {
    throw new UnsupportedOperationException();
}
```

尝试获取共享资源，需同步器自定义实现。有三个类型的返回值：

- 正数：成功获取资源，并且还有剩余可用资源，可以唤醒下一个等待线程；
- 负数：获取资源失败，准备进入等待队列；
- 0：获取资源成功，但没有剩余可用资源。

### doAcquireShared(int)

```java
//获取共享锁
private void doAcquireShared(int arg) {
    final Node node = addWaiter(Node.SHARED);//添加一个共享模式Node到队列尾
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();//获取前节点
            if (p == head) {
                int r = tryAcquireShared(arg);//前节点为head，尝试获取资源
                if (r >= 0) {
                    //获取资源成功，设置head为自己，如果有剩余资源可以在唤醒之后的线程
                    setHeadAndPropagate(node, r);
                    p.next = null; // help GC
                    if (interrupted)
                        selfInterrupt();
                    failed = false;
                    return;
                }
            }
            if (shouldParkAfterFailedAcquire(p, node) &&  //检查获取失败后是否可以阻塞
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
//设置head，如果有剩余资源可以再唤醒之后的线程
private void setHeadAndPropagate(Node node, int propagate) {
    Node h = head; // Record old head for check below
    setHead(node);
    /*
     * 如果满足下列条件可以尝试唤醒下一个节点：
     *  调用者指定参数(propagate>0)，并且后继节点正在等待或后继节点为空
     */
    if (propagate > 0 || h == null || h.waitStatus < 0 ||
        (h = head) == null || h.waitStatus < 0) {
        Node s = node.next;
        if (s == null || s.isShared())
            doReleaseShared();
    }
}
```

将当前线程加入等待队列尾部等待唤醒，成功获取资源后返回。在阻塞结束后成功获取到资源时，如果还有剩余资源，就调用`setHeadAndPropagate`方法继续唤醒之后的线程 。

### releaseShared(int)

```java
/**共享模式释放资源*/
public final boolean releaseShared(int arg) {
    if (tryReleaseShared(arg)) {
        doReleaseShared();//释放锁，并唤醒后继节点
        return true;
    }
    return false;
}
```

共享模式下释放给定量的资源，如果成功释放，唤醒等待队列的后继节点。`tryReleaseShared`需要自定义同步器去实现。方法执行流程：`tryReleaseShared(int)`尝试释放给定量的资源，成功释放后调用`doReleaseShared()`唤醒后继线程。 

### tryReleaseShared(int)

```java
/**共享模式释放资源*/
protected boolean tryReleaseShared(int arg) {
    throw new UnsupportedOperationException();
}
```

### doReleaseShared(int)

```java
//释放共享资源-唤醒后继线程并保证后继节点的资源传播
private void doReleaseShared() {
    //自旋，确保释放后唤醒后继节点
    for (;;) {
        Node h = head;
        if (h != null && h != tail) {
            int ws = h.waitStatus;
            if (ws == Node.SIGNAL) {
                if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
                    continue;            // loop to recheck cases
                unparkSuccessor(h);//唤醒后继节点
            }
            else if (ws == 0 &&
                     !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))  //waitStatus为0，CAS修改为PROPAGATE
                continue;                // loop on failed CAS
        }
        if (h == head)                   // loop if head changed
            break;
    }
}
```

在`tryReleaseShared`成功释放资源后，调用此方法唤醒后继线程并保证后继节点的release传播（通过设置head节点的`waitStatus`为`PROPAGATE`）。 

 ## Condition 等待条件函数列表

 ### await()

```java
//使当前线程在被唤醒或被中断之前一直处于等待状态。
public final void await() throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException();
    Node node = addConditionWaiter();//添加并返回一个新的条件节点
    int savedState = fullyRelease(node);//释放全部资源
    int interruptMode = 0;
    while (!isOnSyncQueue(node)) {
        //当前线程不在等待队列，park阻塞
        LockSupport.park(this);
        if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
            //线程被中断，跳出循环
            break;
    }
    if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
        interruptMode = REINTERRUPT;
    if (node.nextWaiter != null) // clean up if cancelled
        unlinkCancelledWaiters();//解除条件队列中已经取消的等待节点的链接
    if (interruptMode != 0)
        reportInterruptAfterWait(interruptMode);//等待结束后处理中断
}
```

 `await()`方法相当于Object的`wait()`。把当前线程添加到条件队列中调用`LockSupport.park()`阻塞，直到被唤醒或中断。函数流程如下：

* 首先判断线程是否被中断，如果是，直接抛出`InterruptedException`，否则进入下一步；
* 添加当前线程到条件队列中，然后释放全部资源/锁;
* 如果当前节点不在等待队列中，调用`LockSupport.park()`阻塞当前线程，直到被`unpark`或被中断。这里先简单说一下`signal`方法，在线程接收到signal信号后，unpark当前线程，并把当前线程转移到等待队列中（sync queue）。所以，在当前方法中，如果线程被解除阻塞（unpark），也就是说当前线程被转移到等待队列中，就会跳出`while`循环，进入下一步；
* 线程进入等待队列后，调用`acquireQueued`方法获取锁；
* 调用`unlinkCancelledWaiters`方法检查条件队列中已经取消的节点，并解除它们的链接（这些取消的节点在随后的垃圾收集中被回收掉）；
* 逻辑处理结束，最后处理中断（抛出`InterruptedException`或把忽略的中断补上）。

 ### signal()

```java
//唤醒线程
public final void signal() {
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    Node first = firstWaiter;
    if (first != null)
        doSignal(first);//唤醒条件队列的首节点线程
}

//从条件队列中移除给定节点，并把它转移到等待队列
private void doSignal(Node first) {
    do {
        if ( (firstWaiter = first.nextWaiter) == null)
            lastWaiter = null;
        first.nextWaiter = null; //解除首节点链接
    } while (!transferForSignal(first) && //接收到signal信号后，把节点转入等待队列
             (first = firstWaiter) != null);
}

//接收到signal信号后，把节点转入等待队列
final boolean transferForSignal(Node node) {
    /*
     * If cannot change waitStatus, the node has been cancelled.
     */
    if (!compareAndSetWaitStatus(node, Node.CONDITION, 0))
        //CAS修改状态失败，说明节点被取消，直接返回false
        return false;

    Node p = enq(node);//添加节点到等待队列，并返回节点的前继节点(prev)
    int ws = p.waitStatus;
    if (ws > 0 || !compareAndSetWaitStatus(p, ws, Node.SIGNAL))
        //如果前节点被取消，说明当前为最后一个等待线程，unpark唤醒当前线程
        LockSupport.unpark(node.thread);
    return true;
}
```

 `signal`方法用于发送唤醒信号。在不考虑线程争用的情况下，执行流程如下：

* 获取条件队列的首节点，解除首节点的链接（`first.nextWaiter = null;`）；
* 调用`transferForSignal`把条件队列的首节点转移到等待队列的尾部。在`transferForSignal`中，转移节点后，转移的节点没有前继节点，说明当前最后一个等待线程，直接调用`unpark()`唤醒当前线程。

 

 

 

 

 

 

 

 

 

 

 

 

 