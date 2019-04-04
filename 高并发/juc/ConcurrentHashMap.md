> ConcurrentHashMap 在JDK 7之前是通过Lock和Segment（分段锁）实现并发安全，JDK 8之后改为CAS+synchronized来保证并发安全（为了序列化兼容，JDK 8的代码中还是保留了Segment的部分代码） 。
>
> 
>
> ConcurrentHashMap 是一个支持并发检索和并发更新的线程安全的HashMap（但不允许空key或value）。 

# ConcurrentHashMap、HashMap和HashTable的区别

* HashMap 是非线程安全的哈希表，常用于单线程程序中。
* Hashtable 是线程安全的哈希表，由于是通过内置锁 synchronized 来保证线程安全，在资源争用比较高的环境下，Hashtable 的效率比较低。
* ConcurrentHashMap 是一个支持并发操作的线程安全的HashMap，但是他不允许存储空key或value。使用CAS+synchronized来保证并发安全，在并发访问时不需要阻塞线程，所以效率是比Hashtable 要高的。

 # 数据结构

ConcurrentHashMap 是通过Node来存储K-V的， 数据结构采用数组加链表的方式。

1.  **Node<K, V>：** 保存k-v值,k的`hash`值和链表的 next 节点引用，其中 V 和 next 用`volatile`修饰，保证多线程环境下的可见性。
2.  **TreeNode<K, V>：** 红黑树节点类,当链表长度>=8且数组长度>=64时，Node 会转为 TreeNode，但它不是直接转为红黑树，而是把这些 TreeNode 节点放入TreeBin 对象中，由 TreeBin 完成红黑树的封装。
3.  **TreeBin<K, V>：** 封装了 TreeNode，红黑树的根节点，也就是说在 ConcurrentHashMap 中红黑树存储的是 TreeBin 对象。
4.  **ForwardingNode<K, V>：** 在节点转移时用于连接两个 table（table和nextTable）的节点类。包含一个 nextTable 指针，用于指向下一个table。而且这个节点的 k-v 和 next 指针全部为 null，hash 值为-1。只有在扩容时发挥作用，作为一个占位节点放在 table 中表示当前节点已经被移动。
5.  **ReservationNode<K,V>：** 在`computeIfAbsent`和`compute`方法计算时当做一个占位节点，表示当前节点已经被占用，在`compute`或`computeIfAbsent`的 function 计算完成后插入元素。hash值为-3。

 # 核心参数

```java
//最大容量
private static final int MAXIMUM_CAPACITY = 1 << 30;
//初始容量
private static final int DEFAULT_CAPACITY = 16;
//数组最大容量
static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;
//默认并发度，兼容1.7及之前版本
private static final int DEFAULT_CONCURRENCY_LEVEL = 16;
//加载/扩容因子，实际使用n - (n >>> 2)
private static final float LOAD_FACTOR = 0.75f;
//链表转红黑树的节点数阀值
static final int TREEIFY_THRESHOLD = 8;
//红黑树转链表的节点数阀值
static final int UNTREEIFY_THRESHOLD = 6;
//当数组长度还未超过64,优先数组的扩容,否则将链表转为红黑树
static final int MIN_TREEIFY_CAPACITY = 64;
//扩容时任务的最小转移节点数
private static final int MIN_TRANSFER_STRIDE = 16;
//sizeCtl中记录stamp的位数
private static int RESIZE_STAMP_BITS = 16;
//帮助扩容的最大线程数
private static final int MAX_RESIZERS = (1 << (32 - RESIZE_STAMP_BITS)) - 1;
//size在sizeCtl中的偏移量
private static final int RESIZE_STAMP_SHIFT = 32 - RESIZE_STAMP_BITS;

//存放Node元素的数组,在第一次插入数据时初始化
transient volatile Node<K,V>[] table;
//一个过渡的table表,只有在扩容的时候才会使用
private transient volatile Node<K,V>[] nextTable;
//基础计数器值(size = baseCount + CounterCell[i].value)
private transient volatile long baseCount;
//控制table初始化和扩容操作
private transient volatile int sizeCtl;
//节点转移时下一个需要转移的table索引
private transient volatile int transferIndex;
//元素变化时用于控制自旋
private transient volatile int cellsBusy;
// 保存table中的每个节点的元素个数 2的幂次方
// size = baseCount + CounterCell[i].value
private transient volatile CounterCell[] counterCells;
```

**table**：Node数组，在第一次插入元素的时候初始化，默认初始大小为16，用来存储Node节点数据，扩容时大小总是2的幂次方。

**nextTable**：默认为null，扩容时生成的新的数组，其大小为原数组的两倍。

**sizeCtl**  ：默认为0，用来控制table的初始化和扩容操作，在不同的情况下有不同的涵义：

- -1 代表table正在初始化
- -N 表示有N-1个线程正在进行扩容操作
- 初始化数组或扩容完成后,将`sizeCtl`的值设为0.75*n
- 在扩容操作在进行节点转移前，`sizeCtl`改为`(hash << RESIZE_STAMP_SHIFT) + 2`，这个值为负数，并且每有一个线程参与扩容操作`sizeCtl`就加1

**transferIndex**：扩容时用到，初始时为`table.length`，表示从索引 0 到`transferIndex`的节点还未转移 。

**counterCells**： ConcurrentHashMap的特定计数器，实现方法跟`LongAdder`类似。这个计数器的机制避免了在更新时的资源争用，但是如果并发读取太频繁会导致缓存超负荷，为了避免读取太频繁，只有在添加了两个以上节点时才可以尝试扩容操作。在统一hash分配的前提下，发生这种情况的概率在13%左右，也就是说只有大约1/8的put操作才会检查扩容（并且在扩容后会更少）。

**hash计算公式**：`hash = (key.hashCode ^ (key.hashCode >>> 16)) & HASH_BITS`
 **索引计算公式**：`(table.length-1)&hash`

 

# 源码分析

##  put(K, V)

```java
public V put(K key, V value) {
    return putVal(key, value, false);
}

/** Implementation for put and putIfAbsent */
final V putVal(K key, V value, boolean onlyIfAbsent) {
    if (key == null || value == null) throw new NullPointerException();
    //计算hash值
    int hash = spread(key.hashCode());
    int binCount = 0;
    for (Node<K,V>[] tab = table;;) {//自旋
        //f:索引节点; n:tab.length; i:新节点索引 (n - 1) & hash; fh:f.hash
        Node<K,V> f; int n, i, fh;
        if (tab == null || (n = tab.length) == 0)
            //初始化
            tab = initTable();
        else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {//索引i节点为空，直接插入
            //cas插入节点,成功则跳出循环
            if (casTabAt(tab, i, null,
                         new Node<K,V>(hash, key, value, null)))
                break;                   // no lock when adding to empty bin
        }
        //当前节点处于移动状态-其他线程正在进行节点转移操作
        else if ((fh = f.hash) == MOVED)
            //帮助转移
            tab = helpTransfer(tab, f);
        else {
            V oldVal = null;
            synchronized (f) {
                if (tabAt(tab, i) == f) {//check stable
                    //f.hash>=0,说明f是链表的头结点
                    if (fh >= 0) {
                        binCount = 1;//记录链表节点数，用于后面是否转换为红黑树做判断
                        for (Node<K,V> e = f;; ++binCount) {
                            K ek;
                            //key相同 修改
                            if (e.hash == hash &&
                                ((ek = e.key) == key ||
                                 (ek != null && key.equals(ek)))) {
                                oldVal = e.val;
                                if (!onlyIfAbsent)
                                    e.val = value;
                                break;
                            }
                            Node<K,V> pred = e;
                            //到这里说明已经是链表尾，把当前值作为新的节点插入到队尾
                            if ((e = e.next) == null) {
                                pred.next = new Node<K,V>(hash, key,
                                                          value, null);
                                break;
                            }
                        }
                    }
                    //红黑树节点操作
                    else if (f instanceof TreeBin) {
                        Node<K,V> p;
                        binCount = 2;
                        if ((p = ((TreeBin<K,V>)f).putTreeVal(hash, key,
                                                       value)) != null) {
                            oldVal = p.val;
                            if (!onlyIfAbsent)
                                p.val = value;
                        }
                    }
                }
            }
            if (binCount != 0) {
                //如果链表中节点数binCount >= TREEIFY_THRESHOLD(默认是8)，则把链表转化为红黑树结构
                if (binCount >= TREEIFY_THRESHOLD)
                    treeifyBin(tab, i);
                if (oldVal != null)
                    return oldVal;
                break;
            }
        }
    }
    //更新新元素个数
    addCount(1L, binCount);
    return null;
}
```

在 ConcurrentHashMap 中，put 方法几乎涵盖了所有内部的函数操作。所以，我们将从put函数开始逐步向下分析。
 首先说一下put的流程，后面再详细分析每一个流程的具体实现（阅读时请结合源码）：

1. 计算当前key的hash值，根据hash值计算索引 i `（i=(table.length - 1) & hash）`；
2. 如果当前`table`为null，说明是第一次进行put操作，调用`initTable()`初始化`table`；
3. 如果索引 i 位置的节点 f 为空，则直接把当前值作为新的节点直接插入到索引 i 位置；
4. 如果节点 f 的`hash`为-1（`f.hash == MOVED` ），说明当前节点处于移动状态（或者说是其他线程正在对 f 节点进行转移/扩容操作），此时调用`helpTransfer(tab, f)`帮助转移/扩容；
5. 如果不属于上述条件，说明已经有元素存储到索引 i 处，此时需要对索引 i 处的节点 f 进行 put or update 操作，首先使用内置锁 `synchronized` 对节点 f 进行加锁：

- 如果`f.hash>=0`，说明 i 位置是一个链表，并且节点 f 是这个链表的头节点，则对 f 节点进行遍历，此时分两种情况：
   --如果链表中某个节点e的hash与当前key的hash相同，则对这个节点e的value进行修改操作。
   --如果遍历到链表尾都没有找到与当前key的hash相同的节点，则把当前K-V作为一个新的节点插入到这个链表尾部。
- 如果节点 f 是`TreeBin`节点(`f instanceof TreeBin`)，说明索引 i 位置的节点是一个红黑树，则调用`putTreeVal`方法找到一个已存在的节点进行修改，或者是把当前K-V放入一个新的节点（put or update）。

1. 完成插入后，如果索引 i 处是一个链表，并且在插入新的节点后节点数>8，则调用`treeifyBin`把链表转换为红黑树。
2. 最后，调用`addCount`更新元素数量

## initTable()

 ```java
/**
 * Initializes table, using the size recorded in sizeCtl.
 */
private final Node<K,V>[] initTable() {
    Node<K,V>[] tab; int sc;
    while ((tab = table) == null || tab.length == 0) {
        if ((sc = sizeCtl) < 0)//其他线程正在进行初始化或转移操作，让出CPU执行时间片，继续自旋
            Thread.yield(); // lost initialization race; just spin
        else if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) {//CAS设置sizectl为-1 表示当前线程正在进行初始化
            try {
                if ((tab = table) == null || tab.length == 0) {
                    int n = (sc > 0) ? sc : DEFAULT_CAPACITY;
                    @SuppressWarnings("unchecked")
                    Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                    table = tab = nt;
                    sc = n - (n >>> 2);//0.75*n 设置扩容阈值
                }
            } finally {
                sizeCtl = sc;//初始化sizeCtl=0.75*n
            }
            break;
        }
    }
    return tab;
}
 ```

初始化操作，ConcurrentHashMap的初始化在第一次插入数据的时候(判断table是否为null)，注意初始化操作为单线程操作（如果有其他线程正在进行初始化，则调用Thread.yield()让出CPU时间片，自旋等待table初始完成）。 

 ## helpTransfer(Node<K,V>[], Node<K,V>)

```java
//帮助其他线程进行转移操作
final Node<K,V>[] helpTransfer(Node<K,V>[] tab, Node<K,V> f) {
    Node<K,V>[] nextTab; int sc;
    if (tab != null && (f instanceof ForwardingNode) &&
        (nextTab = ((ForwardingNode<K,V>)f).nextTable) != null) {
        //计算操作栈校验码
        int rs = resizeStamp(tab.length);
        while (nextTab == nextTable && table == tab &&
               (sc = sizeCtl) < 0) {
            if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                sc == rs + MAX_RESIZERS || transferIndex <= 0)//不需要帮助转移，跳出
                break;
            if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1)) {//CAS更新帮助转移的线程数
                transfer(tab, nextTab);
                break;
            }
        }
        return nextTab;
    }
    return table;
}
```

 如果索引到的节点的 hash 为-1，说明当前节点处于移动状态（或者说是其他线程正在对 f 节点进行转移操作。这里主要是靠 ForwardingNode 节点来检测，在`transfer`方法中，被转移后的节点会改为ForwardingNode，它是一个占位节点，并且hash=MOVED（-1），也就是说，我们可以通过判断hash是否为MOVED来确定当前节点的状态），此时调用`helpTransfer(tab, f)`帮助转移，主要操作就是更新帮助转移的线程数（sizeCtl+1），然后调用`transfer`方法进行转移操作，`transfer`后面我们会详细分析。

 ## treeifyBin(Node<K,V>[] , index)

```java
private final void treeifyBin(Node<K,V>[] tab, int index) {
 Node<K,V> b; int n, sc;
 if (tab != null) { //当数组长度还未超过64,优先数组的扩容,否则将链表转为红黑树
     if ((n = tab.length) < MIN_TREEIFY_CAPACITY)
         tryPresize(n << 1); //两倍扩容 
 else if ((b = *tabAt*(tab, index)) != null && b.hash >= 0) { 
     synchronized (b) {
         if (*tabAt*(tab, index) == b) {//check stable
             //hd：节点头
             TreeNode<K,V> hd = null, tl = null; 
             //遍历转换节点 
             for (Node<K,V> e = b; e != null; e = e.next) {
                 TreeNode<K,V> p = new TreeNode<K,V>(e.hash, e.key, e.val, null, null);
                 if ((p.prev = tl) == null)
                     hd = p;
                 else
                     tl.next = p; 
                 tl = p; 
             }
             setTabAt(tab, index, new TreeBin<K,V>(hd)); }
	 	  }
	    }
	}
}
```

**说明：** 在put操作完成后，如果当前节点为一个链表，并且链表长度>=TREEIFY_THRESHOLD(8)，此时就需要调用`treeifyBin`方法来把当前链表转为一个红黑树。`treeifyBin`主要进行两步操作：

1. 如果当前table长度还未超过`MIN_TREEIFY_CAPACITY(64)`，则优先对数组进行扩容操作，容量为原来的2倍(n<<1)。
2. 否则就对当前节点进行转换操作（注意这个操作是单线程完成的）。遍历链表节点，把Node转换为TreeNode，然后在通过TreeBin来构造红黑树（红黑树的构造这里就不在详细介绍了）。

 ## tryPresize(int size)

```java
private final void tryPresize(int size) {
        int c = (size >= (MAXIMUM_CAPACITY >>> 1)) ? MAXIMUM_CAPACITY :
            tableSizeFor(size + (size >>> 1) + 1);
        int sc;
        while ((sc = sizeCtl) >= 0) {
            Node<K,V>[] tab = table; int n;
            if (tab == null || (n = tab.length) == 0) {
                n = (sc > c) ? sc : c;
                if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) {
                    try {
                        if (table == tab) {
                            @SuppressWarnings("unchecked")
                            Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                            table = nt;
                            sc = n - (n >>> 2);
                        }
                    } finally {
                        sizeCtl = sc;
                    }
                }
            }
            else if (c <= sc || n >= MAXIMUM_CAPACITY)
                break;
            else if (tab == table) {
                int rs = resizeStamp(n);
                if (sc < 0) {
                    Node<K,V>[] nt;
                    if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                        sc == rs + MAX_RESIZERS || (nt = nextTable) == null ||
                        transferIndex <= 0)
                        break;
                    if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1))
                        transfer(tab, nt);
                }
                else if (U.compareAndSwapInt(this, SIZECTL, sc,
                                             (rs << RESIZE_STAMP_SHIFT) + 2))
                    transfer(tab, null);
            }
        }
    }
```

当table容量不足时，需要对其进行两倍扩容。`tryPresize`方法很简单，主要就是用来检查扩容前的必要条件（比如是否超过最大容量），真正的扩容其实也可以叫**“节点转移”**，主要是通过`transfer`方法完成。 

 ##  transfer(Node<K,V> tab, Node<K,V> nextTab)

```java
private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
    int n = tab.length, stride;
    // 将 length / 8 然后除以 CPU核心数。如果得到的结果小于 16，那么就使用 16。
    // 这里的目的是让每个 CPU 处理的桶一样多，避免出现转移任务不均匀的现象，如果桶较少的话，默认一个 CPU（一个线程）处理 16 个桶
    if ((stride = (NCPU > 1) ? (n >>> 3) / NCPU : n) < MIN_TRANSFER_STRIDE)
        stride = MIN_TRANSFER_STRIDE; // subdivide range 细分范围 stridea：TODO
    // 新的 table 尚未初始化
    if (nextTab == null) {            // initiating
        try {
            // 扩容  2 倍
            Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n << 1];
            // 更新
            nextTab = nt;
        } catch (Throwable ex) {      // try to cope with OOME
            // 扩容失败， sizeCtl 使用 int 最大值。
            sizeCtl = Integer.MAX_VALUE;
            return;// 结束
        }
        // 更新成员变量
        nextTable = nextTab;
        // 更新转移下标，就是 老的 tab 的 length
        transferIndex = n;
    }
    // 新 tab 的 length
    int nextn = nextTab.length;
    // 创建一个 fwd 节点，用于占位。当别的线程发现这个槽位中是 fwd 类型的节点，则跳过这个节点。
    ForwardingNode<K,V> fwd = new ForwardingNode<K,V>(nextTab);
    // 首次推进为 true，如果等于 true，说明需要再次推进一个下标（i--），反之，如果是 false，那么就不能推进下标，需要将当前的下标处理完毕才能继续推进
    boolean advance = true;
    // 完成状态，如果是 true，就结束此方法。
    boolean finishing = false; // to ensure sweep before committing nextTab
    // 死循环,i 表示下标，bound 表示当前线程可以处理的当前桶区间最小下标
    for (int i = 0, bound = 0;;) {
        Node<K,V> f; int fh;
        // 如果当前线程可以向后推进；这个循环就是控制 i 递减。同时，每个线程都会进入这里取得自己需要转移的桶的区间
        while (advance) {
            int nextIndex, nextBound;
            // 对 i 减一，判断是否大于等于 bound （正常情况下，如果大于 bound 不成立，说明该线程上次领取的任务已经完成了。那么，需要在下面继续领取任务）
            // 如果对 i 减一大于等于 bound（还需要继续做任务），或者完成了，修改推进状态为 false，不能推进了。任务成功后修改推进状态为 true。
            // 通常，第一次进入循环，i-- 这个判断会无法通过，从而走下面的 nextIndex 赋值操作（获取最新的转移下标）。其余情况都是：如果可以推进，将 i 减一，然后修改成不可推进。如果 i 对应的桶处理成功了，改成可以推进。
            if (--i >= bound || finishing)
                advance = false;// 这里设置 false，是为了防止在没有成功处理一个桶的情况下却进行了推进
            // 这里的目的是：1. 当一个线程进入时，会选取最新的转移下标。2. 当一个线程处理完自己的区间时，如果还有剩余区间的没有别的线程处理。再次获取区间。
            else if ((nextIndex = transferIndex) <= 0) {
                // 如果小于等于0，说明没有区间了 ，i 改成 -1，推进状态变成 false，不再推进，表示，扩容结束了，当前线程可以退出了
                // 这个 -1 会在下面的 if 块里判断，从而进入完成状态判断
                i = -1;
                advance = false;// 这里设置 false，是为了防止在没有成功处理一个桶的情况下却进行了推进
            }// CAS 修改 transferIndex，即 length - 区间值，留下剩余的区间值供后面的线程使用
            else if (U.compareAndSwapInt
                     (this, TRANSFERINDEX, nextIndex,
                      nextBound = (nextIndex > stride ?
                                   nextIndex - stride : 0))) {
                bound = nextBound;// 这个值就是当前线程可以处理的最小当前区间最小下标
                i = nextIndex - 1; // 初次对i 赋值，这个就是当前线程可以处理的当前区间的最大下标
                advance = false; // 这里设置 false，是为了防止在没有成功处理一个桶的情况下却进行了推进，这样对导致漏掉某个桶。下面的 if (tabAt(tab, i) == f) 判断会出现这样的情况。
            }
        }// 如果 i 小于0 （不在 tab 下标内，按照上面的判断，领取最后一段区间的线程扩容结束）
        //  如果 i >= tab.length(不知道为什么这么判断)
        //  如果 i + tab.length >= nextTable.length  （不知道为什么这么判断）
        if (i < 0 || i >= n || i + n >= nextn) {
            int sc;
            if (finishing) { // 如果完成了扩容
                nextTable = null;// 删除成员变量
                table = nextTab;// 更新 table
                sizeCtl = (n << 1) - (n >>> 1); // 更新阈值
                return;// 结束方法。
            }// 如果没完成
            if (U.compareAndSwapInt(this, SIZECTL, sc = sizeCtl, sc - 1)) {// 尝试将 sc -1. 表示这个线程结束帮助扩容了，将 sc 的低 16 位减一。
                if ((sc - 2) != resizeStamp(n) << RESIZE_STAMP_SHIFT)// 如果 sc - 2 不等于标识符左移 16 位。如果他们相等了，说明没有线程在帮助他们扩容了。也就是说，扩容结束了。
                    return;// 不相等，说明没结束，当前线程结束方法。
                finishing = advance = true;// 如果相等，扩容结束了，更新 finising 变量
                i = n; // 再次循环检查一下整张表
            }
        }
        else if ((f = tabAt(tab, i)) == null) // 获取老 tab i 下标位置的变量，如果是 null，就使用 fwd 占位。
            advance = casTabAt(tab, i, null, fwd);// 如果成功写入 fwd 占位，再次推进一个下标
        else if ((fh = f.hash) == MOVED)// 如果不是 null 且 hash 值是 MOVED。
            advance = true; // already processed // 说明别的线程已经处理过了，再次推进一个下标
        else {// 到这里，说明这个位置有实际值了，且不是占位符。对这个节点上锁。为什么上锁，防止 putVal 的时候向链表插入数据
            synchronized (f) {
                // 判断 i 下标处的桶节点是否和 f 相同
                if (tabAt(tab, i) == f) {
                    Node<K,V> ln, hn;// low, height 高位桶，低位桶
                    // 如果 f 的 hash 值大于 0 。TreeBin 的 hash 是 -2
                    if (fh >= 0) {
                        // 对老长度进行与运算（第一个操作数的的第n位于第二个操作数的第n位如果都是1，那么结果的第n为也为1，否则为0）
                        // 由于 Map 的长度都是 2 的次方（000001000 这类的数字），那么取于 length 只有 2 种结果，一种是 0，一种是1
                        //  如果是结果是0 ，Doug Lea 将其放在低位，反之放在高位，目的是将链表重新 hash，放到对应的位置上，让新的取于算法能够击中他。
                        int runBit = fh & n;
                        Node<K,V> lastRun = f; // 尾节点，且和头节点的 hash 值取于不相等
                        // 遍历这个桶
                        for (Node<K,V> p = f.next; p != null; p = p.next) {
                            // 取于桶中每个节点的 hash 值
                            int b = p.hash & n;
                            // 如果节点的 hash 值和首节点的 hash 值取于结果不同
                            if (b != runBit) {
                                runBit = b; // 更新 runBit，用于下面判断 lastRun 该赋值给 ln 还是 hn。
                                lastRun = p; // 这个 lastRun 保证后面的节点与自己的取于值相同，避免后面没有必要的循环
                            }
                        }
                        if (runBit == 0) {// 如果最后更新的 runBit 是 0 ，设置低位节点
                            ln = lastRun;
                            hn = null;
                        }
                        else {
                            hn = lastRun; // 如果最后更新的 runBit 是 1， 设置高位节点
                            ln = null;
                        }// 再次循环，生成两个链表，lastRun 作为停止条件，这样就是避免无谓的循环（lastRun 后面都是相同的取于结果）
                        for (Node<K,V> p = f; p != lastRun; p = p.next) {
                            int ph = p.hash; K pk = p.key; V pv = p.val;
                            // 如果与运算结果是 0，那么就还在低位
                            if ((ph & n) == 0) // 如果是0 ，那么创建低位节点
                                ln = new Node<K,V>(ph, pk, pv, ln);
                            else // 1 则创建高位
                                hn = new Node<K,V>(ph, pk, pv, hn);
                        }
                        // 其实这里类似 hashMap 
                        // 设置低位链表放在新链表的 i
                        setTabAt(nextTab, i, ln);
                        // 设置高位链表，在原有长度上加 n
                        setTabAt(nextTab, i + n, hn);
                        // 将旧的链表设置成占位符
                        setTabAt(tab, i, fwd);
                        // 继续向后推进
                        advance = true;
                    }// 如果是红黑树
                    else if (f instanceof TreeBin) {
                        TreeBin<K,V> t = (TreeBin<K,V>)f;
                        TreeNode<K,V> lo = null, loTail = null;
                        TreeNode<K,V> hi = null, hiTail = null;
                        int lc = 0, hc = 0;
                        // 遍历
                        for (Node<K,V> e = t.first; e != null; e = e.next) {
                            int h = e.hash;
                            TreeNode<K,V> p = new TreeNode<K,V>
                                (h, e.key, e.val, null, null);
                            // 和链表相同的判断，与运算 == 0 的放在低位
                            if ((h & n) == 0) {
                                if ((p.prev = loTail) == null)
                                    lo = p;
                                else
                                    loTail.next = p;
                                loTail = p;
                                ++lc;
                            } // 不是 0 的放在高位
                            else {
                                if ((p.prev = hiTail) == null)
                                    hi = p;
                                else
                                    hiTail.next = p;
                                hiTail = p;
                                ++hc;
                            }
                        }
                        // 如果树的节点数小于等于 6，那么转成链表，反之，创建一个新的树
                        ln = (lc <= UNTREEIFY_THRESHOLD) ? untreeify(lo) :
                            (hc != 0) ? new TreeBin<K,V>(lo) : t;
                        hn = (hc <= UNTREEIFY_THRESHOLD) ? untreeify(hi) :
                            (lc != 0) ? new TreeBin<K,V>(hi) : t;
                        // 低位树
                        setTabAt(nextTab, i, ln);
                        // 高位数
                        setTabAt(nextTab, i + n, hn);
                        // 旧的设置成占位符
                        setTabAt(tab, i, fwd);
                        // 继续向后推进
                        advance = true;
                    }
                }
            }
        }
    }
}
```

`transfer`方法是table扩容的核心实现。由于 ConcurrentHashMap 的扩容是新建一个table，所以主要问题就是如何把旧table的元素转移到新的table上。所以，扩容问题就演变成了“节点转移”问题。首先总结一下需要转移节点（调用transfer）的几个条件：

1. 对table进行扩容时
2. 在更新元素数目时(addCount方法)，元素总数>=sizeCtl（sizeCtl=0.75n，达到扩容阀值），此时也需要扩容
3. 在put操作时，发现索引节点正在转移(hash==MOVED)，此时需要帮助转移

在进行节点转移之前，首先要做的就是重新初始化`sizeCtl`的值（`sizeCtl = (hash << RESIZE_STAMP_SHIFT) + 2`），这个值是一个负值，用于标识当前table正在进行转移操作，并且每有一个线程参与转移，`sizeCtl`就加1。`transfer`执行步骤如下（请结合源码注释阅读）：

1. 计算转移幅度`stride`（或者说是当前线程需要转移的节点数），最小为16；
2. 创建一个相当于当前 table 两倍容量的 Node 数组，转移完成后用作新的 table；
3. 从`transferIndex`（初始为`table.length`，也就是 table 的最后一个节点）开始，依次向前处理`stride`个节点。前面介绍过，table 的每个节点都可能是一个链表结构，因为在 put 的时候是根据`(table.length-1)&hash`计算出的索引，当插入新值时，如果通过 key 计算出的索引已经存在节点，那么这个新值就放在这个索引位节点的尾部(Node.next)。所以，在进行节点转移后，由于 table.length 变为原来的两倍，所以相应的索引也会改变，这时候就需要对链表进行分割，我们来看一下这个分割算法：

- 假设当前处理的节点 table[i]=f，并且它是一个链表结构，原table容量为 n=2x，索引计算公式为`i=(n - 1)&hash`。在表扩张后，由于容量 n 变为 2*n，所以索引计算就变为`i=(2*n - 1)&hash`。如果 hash 的 x 位为0，则 hash&2x=0，此时 hash&(2x-1)== hash&((2x+1)-1)，索引位 i 不变；如果 hash 的 x 位为1，则 hash&2x=2x == n，在扩容后 x 变为 x+1，此时需要加上 x 位的值，即 hash&(2x-1) + hash&2x，也就是 i+n。举个栗子：设 n=100000 (25)，x=5，hash 为100101。n-1=011111，那么i=hash&(n-1)=000101；扩容后容量变为m=1000000(26)，m-1=0111111，那么 i 就变成了 hash&(m-1)=100101，此时就需要加上 x 位的值，也就是 hash&n。
- 如果当前节点为红黑树结构，也是利用这个算法进行分割，不同的是，在分割完成之后，如果这两个新的树节点<=6，则调用`untreeify`方法把树结构转为链表结构。

1. 最后把操作过的节点都设为 ForwardingNode 节点（hash= MOVED，这样别的线程就可以检测到）。

> https://www.jianshu.com/p/2829fe36a8dd   详细讲解
>
> https://blog.csdn.net/wohaqiyi/article/details/81448176 扩容后索引位置



 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 