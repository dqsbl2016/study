> CyclicBarrier是一个同步辅助类，允许一组线程互相等待，直到到达某个公共屏障点 (common barrier point)。如果一个程序中有固定的线程数，并且线程之间需要相互等待，这时候CyclicBarrier是一个很好的选择。之所以叫它cyclic，是因为在释放等待线程之后，它可以被重用。

# 实现思想

设置一个整型变量做为总数，调用await()后会进入阻塞，并且将总数-1，当多次调用await()将总数变为0后，触发设置的线程方法（如果有设置，通过调用run触发，并不是新开启线程），然后awatit()阻塞的地方将开始执行，同时将总数恢复到最初设置的数量。



CyclicBarrier并没有实现AQS，它创建了一个内部类Generation。

# Generation

```java
 private static class Generation {
        boolean broken = false;
    }
```

其中只定义了一个布尔型的变量。只要用来实现**CyclicBarrier的可重用特性**，**每一次触发tripped都会new一个新的Generation**。 

# 源码分析

## 核心方法及参数

```java
//-------------------------核心参数------------------------------
// 内部类
private static class Generation {
    boolean broken = false;
}
/** 守护barrier入口的锁 */
private final ReentrantLock lock = new ReentrantLock();
/** 等待条件，直到所有线程到达barrier */
private final Condition trip = lock.newCondition();
/** 要屏障的线程数 */
private final int parties;
/* 当线程都到达barrier，运行的 barrierCommand*/
private final Runnable barrierCommand;
/** The current generation */
private Generation generation = new Generation();
//等待到达barrier的参与线程数量，count=0 -> tripped
private int count;

//-------------------------函数列表------------------------------
//构造函数，指定参与线程数
public CyclicBarrier(int parties)
//构造函数，指定参与线程数，并在所有线程到达barrier之后执行给定的barrierAction逻辑
public CyclicBarrier(int parties, Runnable barrierAction);
//等待所有的参与者到达barrier
public int await();
//等待所有的参与者到达barrier，或等待给定的时间
public int await(long timeout, TimeUnit unit);
//获取参与等待到达barrier的线程数
public int getParties();
//查询barrier是否处于broken状态
public boolean isBroken();
//重置barrier为初始状态
public void reset();
//返回等待barrier的线程数量
public int getNumberWaiting();
```

## 构造函数

```java
 public CyclicBarrier(int parties, Runnable barrierAction) {
        if (parties <= 0) throw new IllegalArgumentException();
        this.parties = parties;
        this.count = parties;
        this.barrierCommand = barrierAction;
    }
 public CyclicBarrier(int parties) {
        this(parties, null);
    }
```

构造函数的两个参数为参与的线程个数，以及当满足触发点时调用的线程逻辑。`barrierCommand`就是在所有参与线程到达barrier触发一个自定义函数 。另外的一种不需要执行触发逻辑。

##  await()

```java
public int await() throws InterruptedException, BrokenBarrierException {
    try {
        return dowait(false, 0L);
    } catch (TimeoutException toe) {
        throw new Error(toe); // cannot happen
    }
}
//await实现
private int dowait(boolean timed, long nanos)
    throws InterruptedException, BrokenBarrierException,
           TimeoutException {
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        //当前generation
        final Generation g = generation;
        if (g.broken)
            throw new BrokenBarrierException();
        if (Thread.interrupted()) {
            breakBarrier();//线程被中断，终止Barrier，唤醒所有等待线程
            throw new InterruptedException();
        }
        int index = --count;
        if (index == 0) {  // tripped
            boolean ranAction = false;
            try {
                final Runnable command = barrierCommand;
                if (command != null)
                    command.run();//如果有barrierCommand，在所有parties到达之后运行它
                ranAction = true;
                //更新barrier状态并唤醒所有线程
                nextGeneration();
                return 0;
            } finally {
                if (!ranAction)
                    breakBarrier();
            }
        }
        // loop until tripped, broken, interrupted, or timed out
        //自旋等待 所有parties到达 | generation被销毁 | 线程中断 | 超时
        for (;;) {
            try {
                if (!timed)
                    trip.await();
                else if (nanos > 0L)
                    nanos = trip.awaitNanos(nanos);
            } catch (InterruptedException ie) {
                if (g == generation && ! g.broken) {
                    breakBarrier();
                    throw ie;
                } else {
                    // We're about to finish waiting even if we had not
                    // been interrupted, so this interrupt is deemed to
                    // "belong" to subsequent execution.
                    Thread.currentThread().interrupt();
                }
            }
            if (g.broken)
                throw new BrokenBarrierException();
            if (g != generation)
                return index;
            if (timed && nanos <= 0L) {
                breakBarrier();//超时，销毁当前barrier
                throw new TimeoutException();
            }
        }
    } finally {
        lock.unlock();
    }
}
```

`dowait()`是`await()`的实现函数，它的作用就是让当前线程阻塞，直到“有parties个线程到达barrier” 或 “当前线程被中断” 或 “超时”这3者之一发生，当前线程才继续执行。当所有parties到达barrier（`count=0`），如果`barrierCommand`不为空，则执行`barrierCommand`。然后调用`nextGeneration()`进行换代操作。
 在`for(;;)`自旋中。`timed`是用来表示当前是不是“超时等待”线程。如果不是，则通过`trip.await()`进行等待；否则，调用`awaitNanos()`进行超时等待。具体执行步骤：

* 首先构造函数会设置触发点时多少个线程，例如传入参数为2，则表示当有2个线程进入后触发。
* 第一次调用await函数后，会将总数2进行--操作，然后执行自旋等待（2种情况自旋-设置超时或未设置）。
* 当不断调用await函数后，当count数量变为0后，首先会执行是否设置了自定义触发线程，然后调用nextGeneration方法，在其中调用trip.signalAll();唤醒所有等待线程，然后将count继续恢复到构造函数执行时设置的线程数触发。等待下次使用。（可重复使用特性）

 

 `CyclicBarrier`主要通过独占锁`ReentrantLock`和`Condition`配合实现 .

# **CountDownLatch和CyclicBarrier的区别** 

* CountDownLatch的作用是允许1或N个线程等待其他线程完成执行；而CyclicBarrier则是允许N个线程相互等待。
* CountDownLatch的计数器无法被重置；CyclicBarrier的计数器可以被重置后使用，因此它被称为是循环的barrier。

 

 