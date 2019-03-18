# 锁

研究锁之前需要先研究数据库的事务ACID的隔离级别。

事务隔离级别分为四个级别：

* 读取未提交
* 读取已提交
* 可重复读
* 串行化

他们影响的内容包括：

* 脏读
* 不可重复读
* 幻读



Mysql中默认的隔离级别时RR可重复读，默认这个级别下：

* 不会存在脏读，即其他未提交的数据
* 同一个事务中，相同的连续读，得到的结果应该是相同的； 
* 可能会出现幻读

```text
例如：
假设有数据表：

t(id int PK, name);

假设目前的记录是：

10, shenjian

20, zhangsan

30, lisi

Case 1

事务A先执行，并且处于未提交状态：

update t set name=’a’ where id=10;

事务B后执行：

update t set name=’b’ where id=10;

因为事务A在PK id=10上加了行锁，因此事务B会阻塞。

Case 2

事务A先执行，并且处于未提交状态：

delete from t where id=40;

事务A想要删除一条不存在的记录。

事务B后执行：

insert into t values(40, ‘c’);

事务B想要插入一条主键不冲突的记录。


问题1：事务B是否阻塞？  会

问题2：如果事务B阻塞，锁如何加在一条不存在的记录上呢？  记录锁

问题3：事务的隔离级别，索引类型，是否对问题1和问题2有影响呢？  会
```



## 共享锁与排他锁（行锁）

* 共享锁（**S**hare Locks，记为S锁），读取数据时加S锁  
  * 共享锁之间不互斥， 读读可以并行操作
  * 加锁方式： select * from table where id = 1 LOCK IN SHARE MODE;
* 排他锁（e**X**clusive Locks，记为X锁），修改数据时加X锁 
  * 与任何锁互斥，写读，写写无法并行操作
  * 加锁方式：
    * delete / update / insert 默认加上X锁
    * SELECT * FROM table_name WHERE ... FOR UPDATE

## 注意

如果不是通过索引条件进行数据检索，InnoDB会使用表锁，否则会使用行锁。

因为InnoDB的行锁的实现是通过给索引上的索引项加锁来实现的。

## 意向共享锁与意向排它锁（表锁）

* **意向共享锁(IS)**

  * 表示事务准备给数据行加入共享锁，即一个数据行加共享锁前必须先取得该表的IS锁，
    意向共享锁之间是可以相互兼容的

* **意向排它锁(IX)**

  * 表示事务准备给数据行加入排他锁，即一个数据行加排他锁前必须先取得该表的IX锁，
    意向排它锁之间是可以相互兼容的

意向锁(IS 、IX) 是InnoDB 数据操作之前 自动加的，不需要用户干预
意义：
当事务想去进行锁表时，可以先判断意向锁是否存在，存在时则可快速返回该表不能启用表锁。

## 自增锁（表锁）

自增锁是一种特殊的**表级别锁**（table-level lock），专门针对事务插入AUTO_INCREMENT类型的列。最简单的情况，如果一个事务正在往表中插入记录，所有其他事务的插入必须等待，以便第一个事务插入的行，是连续的主键值。 

## 记录锁（行锁的算法）

**锁住具体索引项** 

当sql执行按照唯一性（Primary key、Unique key）索引进行数据的检索时，查询条件等值匹配且查询的数据是存在，这时SQL语句加上的锁即为记录锁Record locks。

```myql
select * from t where id=1 for update;
它会在id=1的索引记录上加锁，以阻止其他事务插入，更新，删除id=1的这一行。
```

## 间隙锁（行锁的算法）

**锁住数据不存在的区间（左开右开）**

当sql执行按照索引进行数据的检索时，查询条件的数据不存在，这时SQL语句加上的锁即为Gap locks， 锁住索引不存在的区间（左开右开）

```mysql
t(id PK, name KEY, sex, flag);

表中有四条记录：
1, shenjian, m, A
3, zhangsan, m, A
5, lisi, m, A
9, wangwu, f, B

PK上潜在的间隙锁为
(-infinity, 1)
(1, 3)
(3, 5)
(5, 9)
(9, +infinity)

select * from t where id between 6 and 8 for update;
会封锁区间（5，9）

select * from t where id = 11 for update;
会锁住(9, +infinity)
 
间隙锁的主要目的，就是为了防止其他事务在间隔中插入数据，以导致“不可重复读”。
如果把事务的隔离级别降级为读提交(Read Committed, RC)，间隙锁则会自动失效。
```

## 临键锁（行锁的算法）

**锁住记录+ 区间（左开右闭）**
当sql执行按照索引进行数据的检索时,查询条件为范围查找（between and、<、>等）并有数据命中则此时SQL语句加上的锁为Next-key locks， 锁住索引的记录+ 区间（左开右闭）。

```mysql
t(id PK, name KEY, sex, flag);

表中有四条记录：
1, shenjian, m, A
3, zhangsan, m, A
5, lisi, m, A
9, wangwu, f, B

PK上潜在的临键锁为：
(-infinity, 1]
(1, 3]
(3, 5]
(5, 9]
(9, +infinity]
 
 select * from t where id between 8 and 15 for update;
 此时会锁住(5，9](9,infinity]

临键锁的主要目的，也是为了避免幻读(Phantom Read)。如果把事务的隔离级别降级为RC，临键锁则也会失效。
```



## InnoDB中临键锁/间隙锁/记录锁是如何使用的

> 临键锁，记录锁的目的是为了防止幻读等情况，所以如果执行的语句不会造成这个问题，将不会阻塞，例如删除一条不存在的记录，或对不存在记录进行修改。

innoDB中行锁的算法默认使用临键锁。 而当查询的记录不存在时，才会退化成间隙锁，而当唯一性索引精准匹配时，才会退化为记录锁。

```mysql
例子：
t(id PK, name KEY, sex, flag);

表中有四条记录：
1, shenjian, m, A
3, zhangsan, m, A
5, lisi, m, A
9, wangwu, f, B

select * from t where id between 8 and 15 for update;
范围查时，表中存在记录，将会执行临键锁。

select * from t where id between 6 and 8 for update;
select * from t where id= 7 for update;
查询时，查询的记录不存在，会退化成间隙锁

select * from t where id = 9 for update;
唯一性（主键/唯一）索引，条件精准匹配，将会退化成记录锁
```

## InnoDB 如何实现事务隔离级别

InnoDB使用不同的锁策略(Locking Strategy)来实现不同的隔离级别。

### 读取未提交

这个隔离级别下，不加锁就是这种隔离级别。

### 串行化

这种事务的隔离级别下，所有select语句都会被隐式的转化为select ... in share mode.

这可能导致，如果有未提交的事务正在修改某些行，所有读取这些行的select都会被阻塞住。

### 可重复读

这个是InnoDB的默认隔离级别。

* 普通的select使用快照读，这个是不加锁的一致性读，采用MVCC（多版本控制）实现，具体看MVCC。
* 加锁的select（select ... in share mode / select ... for update ）update, delete等语句 。
  * **在唯一索引上使用唯一的查询条件**，会使用记录锁(record lock)，而不会封锁记录之间的间隔，即不会使用间隙锁(gap lock)与临键锁(next-key lock) 
  * **范围查询条件**，会使用间隙锁与临键锁，锁住索引记录之间的范围，避免范围间插入记录，以避免产生幻影行记录，以及避免不可重复的读 ，通过临键锁会解决此隔离级别出现幻读的情况

### 读取已提交

* 普通读是快照读；
* 加锁的select, update, delete等语句，除了在外键约束检查(foreign-key constraint checking)以及重复键检查(duplicate-key checking)时会封锁区间，其他时刻都只使用记录锁；此时，其他事务的插入依然可以执行，就可能导致，读取到幻影记录。

## 死锁

* 多个并发事务（2个或者以上）；
* 每个事务都持有锁（或者是已经在等待锁）;
* 每个事务都需要再继续持有锁；
* 事务之间产生加锁的循环等待，形成死锁。

```mysql
例子：
session A先执行：

set session autocommit=0;

start transaction;

insert into t values(7);

 

session B后执行：

set session autocommit=0;

start transaction;

insert into t values(7);

 

session C最后执行：

set session autocommit=0;

start transaction;

insert into t values(7);

 

三个事务都试图往表中插入一条为7的记录：

(1)A先执行，插入成功，并获取id=7的排他锁；

(2)B后执行，需要进行PK校验，故需要先获取id=7的共享锁，阻塞；

(3)C后执行，也需要进行PK校验，也要先获取id=7的共享锁，也阻塞；

 

如果此时，session A执行：

rollback;

id=7排他锁释放。

 

则B，C会继续进行主键校验：

(1)B会获取到id=7共享锁，主键未互斥；

(2)C也会获取到id=7共享锁，主键未互斥；

 

B和C要想插入成功，必须获得id=7的排他锁，但由于双方都已经获取到id=7的共享锁，它们都无法获取到彼此的排他锁，死锁就出现了。

 

当然，InnoDB有死锁检测机制，B和C中的一个事务会插入成功，另一个事务会自动放弃：

ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
```



### 如何避免死锁

* **类似的业务逻辑以固定的顺序访问表和行。**
* 大事务拆小。大事务更倾向于死锁，如果业务允许，将大事务拆小。
* 在同一个事务中，尽可能做到一次锁定所需要的所有资源，减少死锁概率。

* 降低隔离级别，如果业务允许，将隔离级别调低也是较好的选择
* **为表添加合理的索引。可以看到如果不走索引将会为表的每一行记录添加上锁（或者说是表锁）**



### 死锁调试

```mysql
例子：
InnoDB的行锁都是实现在索引上的，实验可以使用主键，建表时设定为innodb引擎：

create table t (

id int(10) primary key

)engine=innodb;

插入一些实验数据：

start transaction;

insert into t values(1);

insert into t values(3);

insert into t values(10);

commit;

【实验一，间隙锁互斥】

开启区间锁，RR的隔离级别下，上例会有：

(-infinity, 1)

(1, 3)

(3, 10)

(10, infinity)

这四个区间。


事务A删除某个区间内的一条不存在记录，获取到共享间隙锁，会阻止其他事务B在相应的区间插入数据，因为插入需要获取排他间隙锁。

 

session A：

set session autocommit=0;

start transaction;

delete from t where id=5;



session B：

set session autocommit=0;

start transaction;

insert into t values(0);

insert into t values(2);

insert into t values(12);

insert into t values(7);

 

事务B插入的值：0, 2, 12都不在(3, 10)区间内，能够成功插入，而7在(3, 10)这个区间内，会阻塞。
```

show engine innodb status;   查看锁的情况

```mysql
LOCK WAIT 2 lock struct(s), heap size 312, 1 row lock(s), undo log entries 3
MySQL thread id 69, OS thread handle 0x858, query id 1361 localhost 127.0.0.1 root update
insert into t values(7)
------- TRX HAS BEEN WAITING 30 SEC FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 46 page no 3 n bits 80 index `PRIMARY` of table `test`.`t` trx id 13802 lock_mode X locks gap before rec insert intention waiting
Record lock, heap no 4 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 8000000a; asc     ;;
 1: len 6; hex 0000000035bd; asc     5 ;;
 2: len 7; hex 85000001380128; asc     8 (;;

------------------
```

可以看到 执行insert into t values(7)时，会先获取（3，10）这个区间的间隙锁，而当前这个区间的间隙锁已经被第一个事务拿到，所以当前等待这个区间的间隙锁的释放。