# 索引

## 什么是索引

索引是一种数据结构，类似于图书馆中的图书目录与图书实际位置的关系，存储这个关系的数据结构。

可以使存储引擎更快速的查询记录。

## 为什么能更快查找？索引的作用

* 索引大大减少服务器需要扫描的数据量
* 索引可以帮助服务器避免排序和临时表
* 索引可以将随机I/O变为顺序I/O

# 聚簇索引

聚簇索引即主键索引，规则为默认使用主键作为索引，如果未设置主键则会按找到的第一个唯一且非空字段做为索引，如果未找到会隐式的创建一个主键id做为索引，一个表只能有一个聚簇索引。

## 聚簇索引数据存储方式

聚簇索引在B+TREE中的数据存放方式为叶子节点存储索引值和数据记录，非叶子节点只存储索引值。（InnoDB中存在聚簇索引，所以这个也是InnoDB的B+TREE存储方式）。

# 覆盖索引

如果一个索引可以包含（覆盖）所需要查询的字段的值，则称为覆盖索引。

```mysql
例如：
表中存在一个多列索引（aid,bid）.

select aid.bid from table
```

## 覆盖索引好处

* 直接通过读取索引就可以完成查询，极大减少访问数据量。
* 由于InnoDB采用聚簇索引，如果二级主键能够覆盖索引，则可以避免对主键索引的二次查询。

# 索引扫描做排序

Mysql有两种操作用来生成有序结果。

* **排序操作**：将查询出来的结果使用排序算法进行排序。
* **按索引顺序扫描**： 需要的结果顺序就是按索引查出来的记录顺序。

## 注意内容

按照索引顺序扫描的好处是不言而喻的，因为查找出来的结果就是有序结果而无需执行额外的排序操作，这样执行的速度就会相对较快。但是，不是什么时候按照索引扫描的执行速都会是最快的。虽然扫描索引的速度是非常快的，但是如果索引不能覆盖到查询所需要的所有数据列的话，这种情况下每扫描一个索引就必须相对应地回表一次，这样的IO几乎是随机IO，如此一来虽然索引扫描无需执行一次排序算法，但是随机IO操作会大大拖慢执行速度，导致按照索引扫描的执行速度反而要比排序操作要慢。因此，在考虑使用按照索引扫描的方式去获得有序结果，那么设计索引时必须要考虑索引覆盖的情况。

## 什么时候会使用

当索引的列顺序和ORDER BY子句的顺序完全一致，并且所有列的排序方向都一样时，Mysql才会使用索引对结果做排序。如果查询关联多张表，则只有当ORDER BY子句引用的字段全部为第一张表时，才能使用索引做排序。

```mysql
例如：

select CREATE TABLE rental{
    ...
    PRIMARY KEY(rental_id),
    UNIQUE KEY rental_date(rental_date, inventory_id, customer_id),
    KEY idx_fk_inventory_id(inventory_id),
    KEY idx_fk_customer_id(customer_id),
    KEY idx_fk_staff_id(staff_id),
    ...
};

SELECT rental_id, staff_id FROM sakila.rental 
-> WHERE rental_date = '2005-05-5'
-> ORDER BY inventory_id, customer_id\G
//满足

SELECT * FROM sakila.rental 
-> WHERE rental_date = '2005-05-5'
-> ORDER BY inventory_id, customer_id\G
//这中也会满足，但是没有实现覆盖索引，所以数据量大时性能会变的不理想

SELECT rental_id, staff_id FROM sakila.rental 
-> WHERE rental_date > '2005-05-5'
-> ORDER BY rental_date, inventory_id, customer_id\G
//也可以满足，因为order BY中满足最左前缀原则。

...WHERE rental_date > '2005-05-5' ORDER BY rental_date DESC, inventory_id ASC 
//不满足，因为排序方向不一致。
...WHERE rental_date = '2005-05-5' ORDER BY rental_date , staff_id 
//不满足，因为使用了一个不在索引中的列。
...WHERE rental_date > '2005-05-5' ORDER BY inventory_id 
//不满足，因为不满足最左前缀索引
```



