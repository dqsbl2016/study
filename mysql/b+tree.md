# 数据库索引为什么使用B+TREE?

首先需要了解下二叉树缺点

* 数据量大时，树的高度会比较高，查询会很慢
* 每个节点只存储一个记录，一次查询会导致很多次磁盘I/O

所以在二叉树基础上升级出现了B树

## B-TREE

* 节点可存储M个元素，或叫做M叉树，所以高度大大降低。

* 叶子节点与非叶子节点都存储记录

* 中序遍历，可以获取到所有节点

* 非根节点包含的关键字个数j满足，**(┌m/2┐)-1 <= j <= m-1**，节点分裂时要满足这个条件。

* 符合局部性原理

  * ```text
    什么是局部性原理？
    
    局部性原理的逻辑是这样的：
    (1)内存读写块，磁盘读写慢，而且慢很多；
    
    (2)磁盘预读：磁盘读写并不是按需读取，而是按页预读，一次会读一页的数据，每次加载更多的数据，如果未来要读取的数据就在这一页中，可以避免未来的磁盘IO，提高效率；
    画外音：通常，一页数据是4K。
    
    (3)局部性原理：软件设计要尽量遵循“数据读取集中”与“使用到一个数据，大概率会使用其附近的数据”，这样磁盘预读能充分提高磁盘IO；
    ```

  * 如果每个节点大小设置为页大小，例如4k，这样可以充分利用预读特性，直接读取一页数据减少磁盘I/O.

## B+TREE

而在B-TREE的基础上又一步优化成B+TREE。

* 非叶子节点不再存储数据，数据只存在叶子节点上。
* 叶子之间增加了链表，范围查找定位min和max后，中间的叶子节点就是结果集，不用中序遍历。
* 叶子节点存储实际的记录行，适合大数据量磁盘存储，非叶子节点存储记录的key，用于查询加速，适合内存存储。非叶子节点，不存储实际记录，而只存储记录的KEY的话，那么在相同内存的情况下，B+树能够存储更多索引；



##  为什么m叉的B+树比二叉搜索树的高度大大大大降低？

****

大概计算一下：

(1)局部性原理，将一个节点的大小设为一页，一页4K，假设一个KEY有8字节，一个节点可以存储500个KEY，即j=500

(2)m叉树，大概m/2<= j <=m，即可以差不多是1000叉树

(3)那么：

一层树：1个节点，1*500个KEY，大小4K

二层树：1000个节点，1000*500=50W个KEY，大小1000*4K=4M

三层树：1000*1000个节点，1000*1000*500=5亿个KEY，大小1000*1000*4K=4G

可以看到，存储大量的数据（5亿），并不需要太高树的深度（高度3），索引也不是太占内存（4G）。 



## 总结

- 数据库索引用于加速查询
- 虽然哈希索引是O(1)，树索引是O(log(n))，但SQL有很多“有序”需求，故数据库使用树型索引
- InnoDB不支持哈希索引
- **数据预读**的思路是：磁盘读写并不是按需读取，而是按页预读，一次会读一页的数据，每次加载更多的数据，以便未来减少磁盘IO
- **局部性原理**：软件设计要尽量遵循“数据读取集中”与“使用到一个数据，大概率会使用其附近的数据”，这样磁盘预读能充分提高磁盘IO
- 数据库的索引最常用B+树：
  - (1)很适合磁盘存储，能够充分利用局部性原理，磁盘预读；
  - (2)很低的树高度，能够存储大量数据；
  - (3)索引本身占用的内存很小；
  - (4)能够很好的支持单点查询，范围查询，有序性查询；