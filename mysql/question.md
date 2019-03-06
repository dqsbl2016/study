# 字符串前缀索引长度计算

## 第一种方法：按数据分布

* 查询数据分布

  * ```mysql
    mysql> select count(*) as count,索引列 from 表名 group by 索引列 order by count desc limit 10;
    
    例如：
    
    mysql> select count(*) as count,ssu_name from p_ssu group by ssu_name order by count desc limit 10;
    +-------+-----------------------------+
    | count | ssu_name                    |
    +-------+-----------------------------+
    |   249 | 楦¤泲(|鏂¤)                |
    |   216 | 瑗跨孩鏌¿(鏅?殀500g)      |
    |   203 | 澶х櫧鑿(鏅?殀鏂¤)       |
    |   174 | 绾㈢毊娲嬭懕(|500g)         |
    |   163 | 鐧借悵鍗(|500g)            |
    |   154 | 鐢樿摑鍦嗙櫧鑿(鏅?殀鏂¤) |
    |   142 | 榛勭摐(鏅?殀鏂¤)          |
    |   142 | 鐧界爞绯(|鏂¤)             |
    |   140 | 棣欒弴(|500g)               |
    |   127 | 鍏冨疂|澶ц眴娌箌|妗¶(10L)  |
    +-------+-----------------------------+
    10 rows in set (0.46 sec)
    
    ```

* 查询想要的长度前缀的数据分布

  * ```mysql
    mysql> select count(*) as count,left(ssu_name,4) as name from p_ssu group by name order by count desc  limit 10;
    +-------+--------------+
    | count | name         |
    +-------+--------------+
    |   745 | 浜斿緱鍒﹟   |
    |   676 | 榛勫績鍦熻眴 |
    |   640 | 搴峰笀鍌厊   |
    |   563 | 鍙?彛鍙?箰 |
    |   534 | 鏉庨敠璁皘   |
    |   529 | 浜旇姳鑲(   |
    |   468 | 瑗跨孩鏌¿(   |
    |   445 | 鑳¤悵鍗(   |
    |   421 | 绾㈢毊娲嬭懕 |
    |   403 | 鍐滃か灞辨硥 |
    +-------+--------------+
    10 rows in set (0.19 sec)
                    
    mysql> select count(*) as count,left(ssu_name,7) as name from p_ssu group by name order by count desc  limit 10;
    +-------+---------------------+
    | count | name                |
    +-------+---------------------+
    |   270 | 鍏冨疂|澶ц眴娌箌   |
    |   268 | 鍙?彛鍙?箰|鍙?箰 |
    |   260 | |娉稿窞鑰佺獤||     |
    |   249 | 楦¤泲(|鏂¤)        |
    |   242 | 灞?渤|鐣?寗閰眧   |
    |   236 | 瑗跨孩鏌¿(鏅?殀   |
    |   216 | 浜旇姳鑲(椴/浜   |
    |   209 | 澶х櫧鑿(鏅?殀   |
    |   208 | 榛勫績鍦熻眴(|榛   |
    |   206 | 棣欒弴(|500         |
    +-------+---------------------+
    10 rows in set (0.23 sec)
    
    mysql> select count(*) as count,left(ssu_name,8) as name from p_ssu group by name order by count desc  limit 10;
    +-------+----------------------+
    | count | name                 |
    +-------+----------------------+
    |   257 | 鍙?彛鍙?箰|鍙?箰| |
    |   255 | 鍏冨疂|澶ц眴娌箌|   |
    |   249 | 楦¤泲(|鏂¤)         |
    |   237 | 灞?渤|鐣?寗閰眧|   |
    |   216 | 浜旇姳鑲(椴/浜岀骇 |
    |   216 | 瑗跨孩鏌¿(鏅?殀5   |
    |   208 | 榛勫績鍦熻眴(|榛勭毊 |
    |   206 | 澶х櫧鑿(鏅?殀鏂¤ |
    |   206 | 棣欒弴(|500g         |
    |   192 | 澶?お涔恷楦＄簿||   |
    +-------+----------------------+
    10 rows in set (0.31 sec)
    
    mysql> select count(*) as count,left(ssu_name,9) as name from p_ssu group by name order by count desc  limit 10;
    +-------+-----------------------+
    | count | name                  |
    +-------+-----------------------+
    |   255 | 鍙?彛鍙?箰|鍙?箰|| |
    |   251 | 鍏冨疂|澶ц眴娌箌|妗¶ |
    |   249 | 楦¤泲(|鏂¤)          |
    |   228 | 灞?渤|鐣?寗閰眧|缃 |
    |   216 | 瑗跨孩鏌¿(鏅?殀50   |
    |   208 | 榛勫績鍦熻眴(|榛勭毊/ |
    |   206 | 澶х櫧鑿(鏅?殀鏂¤) |
    |   199 | 浜旇姳鑲(椴/浜岀骇| |
    |   187 | 澶?お涔恷楦＄簿||琚 |
    |   181 | 娴峰ぉ|鑽夎弴鑰佹娊|| |
    +-------+-----------------------+
    10 rows in set (0.40 sec)                
    ```

  * 最终发现到8的时候最合适

## 第二种方法：计算完整列的选择性

* 首先计算完整列的计算性

  * ```mysql
    mysql>select count(DISTINCT 索引列)/count(*) from 表名
    
    例如： 
    
    mysql> select count(distinct ssu_name)/count(*) from p_ssu;
    +-----------------------------------+
    | count(distinct ssu_name)/count(*) |
    +-----------------------------------+
    |                            0.6094 |
    +-----------------------------------+
    1 row in set (0.34 sec)
    
    ```

* 通常来说前缀的选择性能接近这个计算值，基本上就可以了。查询一下不同前缀值的计算数值

  * ```mysql
    mysql> select count(DISTINCT LEFT(索引列，长度))/count(*),..... from 表名
    
    例如：
    mysql> select count(distinct left(ssu_name,3))/count(*) as name3,
        -> count(distinct left(ssu_name,4))/count(*) as name4,
        -> count(distinct left(ssu_name,5))/count(*) as name5,
        -> count(distinct left(ssu_name,6))/count(*) as name6,
        -> count(distinct left(ssu_name,7))/count(*) as name7,
        -> count(distinct left(ssu_name,8))/count(*) as name8,
        -> count(distinct left(ssu_name,9))/count(*) as name9,
        -> count(distinct left(ssu_name,10))/count(*) as name10,
        -> count(distinct left(ssu_name,11))/count(*) as name11,
        -> count(distinct left(ssu_name,12))/count(*) as name12,
        -> count(distinct left(ssu_name,13))/count(*) as name13,
        -> count(distinct left(ssu_name,14))/count(*) as name14,
        -> count(distinct left(ssu_name,15))/count(*) as name15,
        -> count(distinct left(ssu_name,16))/count(*) as name16,
        -> count(distinct left(ssu_name,17))/count(*) as name17,
        -> count(distinct left(ssu_name,18))/count(*) as name18,
        -> count(distinct left(ssu_name,19))/count(*) as name19,
        -> count(distinct left(ssu_name,20))/count(*) as name20
        ->
        -> from p_ssu;
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
    | name3  | name4  | name5  | name6  | name7  | name8  | name9  | name10 | name11 | name12 | name13 | name14 | name15 | name16 | name17 | name18 | name19 | name20 |
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
    | 0.1552 | 0.2538 | 0.3394 | 0.3967 | 0.4413 | 0.4782 | 0.5095 | 0.5355 | 0.5545 | 0.5683 | 0.5778 | 0.5848 | 0.5902 | 0.5947 | 0.5986 | 0.6015 | 0.6036 | 0.6050 |
    +--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
    1 row in set (3.75 sec)
    
    这里可以看到随着长度越长，计算的值越贴近完整列的计算值。但是越到后面提升的越小。
    ```

    

# 前缀索引缺点

* mysql无法使用前缀索引做order by 与 group by
* 无法使用前缀索引做扫描覆盖(Covering Index) ，即当索引本身包含查询所需全部数据时，不再访问数据文件本身 

# InnoDB，快照读，在RR和RC下有何差异

RC-读取已提交

- 数据库领域，事务隔离级别的一种，简称RC
- 它解决“读脏”问题，保证读取到的数据行都是已提交事务写入的
- 它可能存在“读幻影行”问题，同一个事务里，连续相同的read可能读到不同的结果集

RR-可重复读

- 数据库领域，事务隔离级别的一种，简称RR
- 它不但解决“读脏”问题，还解决了“读幻影行”问题，同一个事务里，连续相同的read读到相同的结果集

```mysql
举例：
t(id PK, name);
 
表中有三条记录：
1, shenjian
2, zhangsan
3, lisi




```

```mysql
Case 1，两个并发事务A，B执行的时间序列如下（A先于B开始，B先于A结束）：

A1: start transaction;
         B1: start transaction;
A2: select * from t;
         B2: insert into t values (4, wangwu);
A3: select * from t;
         B3: commit;
A4: select * from t;


RR下：
A2会读到 1，2，3
A3会读到 1，2，3
A4会读到 1，2，3  可重复读的概念就是 当前事务未提交之前任何时候的读取的数据都是一致的。

RC下：
A2会读到 1，2，3
A3会读到 1，2，3
A4会读到 1，2，3，4  因为可以读取已提交，所以会读到B事务提交的内容
```

```mysql
Case 2，仍然是上面的两个事务，只是A和B开始时间稍有不同（B先于A开始，B先于A结束）：

         B1: start transaction;
A1: start transaction;
A2: select * from t;
         B2: insert into t values (4, wangwu);
A3: select * from t;
         B3: commit;
A4: select * from t;

RR下：
A2会读到 1，2，3
A3会读到 1，2，3
A4会读到 1，2，3  可重复读的概念就是 当前事务未提交之前任何时候的读取的数据都是一致的。

RC下：
A2会读到 1，2，3
A3会读到 1，2，3
A4会读到 1，2，3，4  因为可以读取已提交，所以会读到B事务提交的内容
```

```mysql
Case 3，仍然是并发的事务A与B（A先于B开始，B先于A结束）：

A1: start transaction;
         B1: start transaction;
         B2: insert into t values (4, wangwu);
         B3: commit;
A2: select * from t;

RR下：
A2会读到 1，2，3，4 为什么这里会读到4呢？因为这个是事务A的第一个read查询，所以它会查询当前时间点之前的所有已提交数据。

RC下：
A2会读到 1，2，3，4 因为可以读取已提交，所以会读到B事务提交的内容
```

```mysql
Case 4，事务开始的时间再换一下（B先于A开始，B先于A结束）：

         B1: start transaction;
A1: start transaction;
         B2: insert into t values (4, wangwu);
         B3: commit;
A2: select * from t;

RR下：
A2会读到 1，2，3，4 
为什么这里会读到4呢？因为这个是事务A的第一个read查询，所以它会查询当前时间点之前的所有已提交数据。
事务的开始时间不一样，不会影响快照读

RC下：
A2会读到 1，2，3，4 因为可以读取已提交，所以会读到B事务提交的内容
```

## 结论

* RR下快照读，事务会在第一次Read的时候建立读的视图，会读取所有已提交的数据。
* RC下快照都，事务在每次Read的时候都会建立读的视图，每次读都会读取当前所有已提交数据。

# **主键与唯一索引约束**冲突处理

* InnoDb中插入数据主键已存在会报错回滚

* Myisam中会放弃后面的执行内容

  * 另外，对于insert的约束冲突，可以使用：insert … on duplicate key指出**在违反主键或唯一索引约束时，需要进行的额外操作**。

    * insert into t3(id) values(10) on duplicate key update flag='false'; 
    * 如果id=10的数据存在，则执行修改此条数据的flag字段改为false。

# 三范式

简单一点 ：

* 每一列只有一个 单一的 值 ，不可再拆分
* 每一行都 有主键能进行 区分
* 每一个表都不包含其他表已经包含的非主键信息

问题：

* 充分的满足第一范式设计将为表建立太量的列
  * 数据从磁盘到缓冲区，缓冲区脏页到磁盘进行持久的过程中，列的数量过多会导致性能下降。过多的列影响转换和持久的性能
* 过分的满足第三范式化造成了太多的表关联
  * 表的关联操作将带来额外的内存和性能开销
* 使用innodb 引擎的外键关系进行数据的完整性保证
  * 外键表中数据的修改会导致Innodb引擎对外键约束进行检查，就带来了额外的开销