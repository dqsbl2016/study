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

