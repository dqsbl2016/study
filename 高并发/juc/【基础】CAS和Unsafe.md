# CAS理论

> **CAS（Compare-and-Swap）  比较并替换**
>
> CAS有三个参数：需要读写的内存位值（V）、进行比较的预期原值（A）和拟写入的新值(B)。当且仅当V的值等于A时，CAS才会通过原子方式用新值B来更新V的值，否则不会执行任何操作。

```java
例子：class AtomicInteger 中

public final boolean compareAndSet(int expect, int update) {
        return unsafe.compareAndSwapInt(this, valueOffset, expect, update);
}

valueOffset表示的是value值的偏移地址.。这个可以在静态初始化代码块中查看（通过反射的方式）。
因为Unsafe就是根据内存偏移地址获取数据的原值的, 偏移量可以简单理解为指针指向该变量的内存地址。

传入的参数为该变量的值，与想修改的值。
```

# ABA问题

> **ABA问题是一种异常现象**
>
> 如果有两个线程x和y，如果x初次从内存中读取变量值为A；线程y对它进行了一些操作使其变成B，然后再改回A，那么线程x进行CAS的时候就会误认为这个值没有被修改过。 
>
> 具体例子：
>
> 如果有一个单向链表A B组成的栈，栈顶为A，线程T1准备执行CAS操作`head.compareAndSet(A,B)`，在执行之前线程T2介入，T2将A、B出栈，然后又把C、A放入栈，T2执行完毕；切回线程T1，T1发现栈顶元素依然为A，也会成功执行CAS将栈顶元素修改为B，但因为B.next为null，所以栈结构就会丢弃C元素。
>
> **T2线程修改后为  A->C (A的next指向C) 当将A替换为B后C将失去了指向。**

针对这种情况，有一种简单的解决方案：不是更新某个引用的值，而是更新两个值，包括一个引用和一个和版本号，即这个值由A变为B，然后又变成A，版本号也将是不同的。Java中提供了`AtomicStampedReference`和`AtomicMarkableReference`来解决ABA问题。他们支持在两个变量上执行原子的条件更新。`AtomicStampedReference`将更新一个“对象-引用”二元组，通过在引用上加上“版本号”，从而避免ABA问题。 类似地，`AtomicMarkableReference`将更新一个“对象引用-布尔值”二元组，在某些算法中将通过这种二元组使节点保存在链表中同时又将其标记为“已删除的节点”。**不过目前来说，这两个类比较鸡肋，大部分情况下的ABA问题不会影响程序并发的正确性，如果需要解决ABA问题，改用传统的互斥同步可能会比原子类更高效。**

 # Unsafe具体实现

>Unsafe是实现CAS的核心类，Java无法直接访问底层操作系统，而是通过本地（native）方法来访问。Unsafe类提供了硬件级别的原子操作。 

看到Unsafe.java中可以发现大部分内容都是本地方法，使用C语言实现的。

首先看这里面的方法大部分都是两种模式(重写)，例如：

```java
//参数为 对象 与对象的偏移地址，从给定对象的偏移地址取值。
public native int getInt(Object var1, long var2);
//参数为内存地址  直接从指定内存地址取值
public native int getInt(long var1);
```

另外一些常用方法

* `arrayBaseOffset`：操作数组，用于获取数组的第一个元素的偏移地址
* `arrayIndexScale`：操作数组，用于获取数组元素的增量地址，也就是说每个元素的占位数。打个栗子：如果有一个数组{1,2,3,4,5,6}，它第一个元素的偏移地址为16，每个元素的占位是4，如果我们要获取数组中“5”这个数字，那么它的偏移地址就是16+4*4。
*  `putOrderedObject`：putOrderedObject 是 lazySet 的实现，适用于低延迟代码。它能够实现非堵塞写入，避免指令重排序，这样它使用快速的存储-存储(store-store) barrier,而不是较慢的存储-加载(store-load) barrier, 后者总是用在volatile的写操作上。这种性能提升是有代价的，也就是写后结果并不会被其他线程看到，甚至是自己的线程，通常是几纳秒后被其他线程看到。类似的方法还有`putOrderedInt、putOrderedLong`。
* `loadFence`、`storeFence`、`fullFence`：这三个方法是1.8新增，主要针对内存屏障定义，也是为了避免重排序
  * loadFence() 表示该方法之前的所有load操作在内存屏障之前完成。
  * storeFence()表示该方法之前的所有store操作在内存屏障之前完成。
  * fullFence()表示该方法之前的所有load、store操作在内存屏障之前完成。

 

 

 

 

 

 

 

 