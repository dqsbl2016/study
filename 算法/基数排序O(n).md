# 基数排序

排序，面试中考察基本功问的比较多，工作多年以后，对排序的细节记忆不那么清楚的小伙伴，面试时会比较吃亏。

 

有一种很神奇的排序，**基数排序**(Radix Sort)，时间复杂度为O(n)，今天花1分钟，通过几幅图，争取让大家搞懂细节。

***画外音：居然还有时间复杂度为O(n)的排序算法？不但有，其实还有很多。***

 

举个栗子：

假设待排序的数组arr={72, 11, 82, 32, 44, 13, 17, 95, 54, 28, 79, 56}

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOzc1ZjiazmOVC0b3jE5L7uGiaicVWnTxjLEVZS95iazUseeS7UH6SjlwUnZSvHrKCjPlOPiadGY573rPUg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

基数排序的**两个关键要点**：

（1）**基**：被排序的元素的“个位”“十位”“百位”，暂且叫“基”，栗子中“基”的个数是2（个位和十位）；

*画外音：来自野史，大神可帮忙修正。*

（2）**桶**：“基”的每一位，都有一个取值范围，栗子中“基”的取值范围是0-9共10种，所以需要10个桶（bucket），来存放被排序的元素；

 

基数排序的**算法步骤**为：

FOR (每一个基) {

//循环内，以某一个“基”为依据

第一步：遍历数据集arr，将元素放入对应的桶bucket

第二步：遍历桶bucket，将元素放回数据集arr

}

 

更具体的，对应到上面的栗子，“基”有个位和十位，所以，FOR循环会执行两次。

 

**【第一次：以“个位”为依据】**

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOzc1ZjiazmOVC0b3jE5L7uGiazhe7c3R5BGGssHaHSJ7DFQQeuI9ZOiaEhRdNf11sqr71A58DMeSpnYw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

***画外音：上图中标红的部分，个位为“基”。***

第一步：遍历数据集arr，将元素放入对应的桶bucket；

 

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOzc1ZjiazmOVC0b3jE5L7uGiaJU1eMrnrGPtibLzzYn6zefBPohA0wDkbnVkha7QBSG9tfbfSDmVbkHQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

操作完成之后，各个桶会变成上面这个样子，即：个位数相同的元素，会在同一个桶里。

 

**第二步**：遍历桶bucket，将元素放回数据集arr；

***画外音：需要注意，先入桶的元素要先出桶。***

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOzc1ZjiazmOVC0b3jE5L7uGiaibEJDKiaFYHWibEQEiaic6Azibbq3STQ9Ja2oibKE59icJwv9Mdos6h4k9CsJg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

操作完成之后，数据集会变成上面这个样子，即：整体按照个位数排序了。

***画外音：个位数小的在前面，个位数大的在后面。***

 

**【第二次：以“十位”为依据】**

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOzc1ZjiazmOVC0b3jE5L7uGia5JKj4Y5r6SjUk61dKuNgSGM4De7abx5VMbP3Uc8aY4ZoWrqBbY7X0w/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

***画外音：上图中标红的部分，十位为“基”。***

**第一步**：依然遍历数据集arr，将元素放入对应的桶bucket；

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOzc1ZjiazmOVC0b3jE5L7uGiarULP9icqdHzzNDlNlDWBmmQAwbriczA6662G61L5VdibpibvqEzlq4KOkA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

操作完成之后，各个桶会变成上面这个样子，即：十位数相同的元素，会在同一个桶里。

 

**第二步**：依然遍历桶bucket，将元素放回数据集arr；

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOzc1ZjiazmOVC0b3jE5L7uGia7GaOF3zwHQvibyETGo84dibCP0HHTQ9MdYFsqAwMKZoVeGXFN8jqk9KA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

操作完成之后，数据集会变成上面这个样子，即：整体按照十位数也排序了。

***画外音：十位数小的在前面，十位数大的在后面。***

 

首次按照个位从小到大，第二次按照十位从小到大，即：**排序结束**。

 

**神奇不神奇！！！**

 

几个小点：

（1）**基的选取**，可以先从个位开始，也可以先从十位开始，结果是一样的；

（2）基数排序，是一种**稳定的排序**；

（3）**时间复杂度**，可以认为是**线性**的O(n)；



代码：

```java
 private Integer[] arr ={72, 11, 82, 32, 44, 13, 17, 95, 54, 28, 79, 56};

 public void test(){
        //先获取基
        //查最大值
        int s = 0;
        for(int i =0; i<arr.length;i++){
            if(arr[i] > s){
                s = arr[i];
            }
        }
        //取最大值位数 （获取到基）
        int size = 0;
        while(s > 0){
            s = s/10;
            size++;
        }

        // 定义了10个桶，为了防止每一位都一样所以将每个桶的长度设为最大,与原数组大小相同
        int length = arr.length;
        int[][] bucket = new int[10][length];
     	// 记录每个桶中元素个数
        int[] count = new int[10];

        int divisor = 1;// 定义每一轮的除数，1,10,100...
        int digit;// 获取元素中对应位上的数字，即装入那个桶
     
     	//遍历基
        for(int i =0;i<size;i++){
            //遍历数组，计算入桶
            for (int j =0; j< arr.length; j++) {// 计算入桶
                digit = (arr[j] / divisor) % 10;
                bucket[digit][count[digit]++] = arr[j];
            }

            int m= 0;
            //遍历桶，出桶放入数组
            for(int j =0;j<10;j++){
                if(count[j] == 0){
                    continue;
                }
                //根据每个桶中记录的元素个数 获取桶内元素
                for(int k = 0; k <count[j];k++){
                    arr[m] = bucket[j][k];
                    m++;
                }
                //桶记录出完，清空此桶记录元素的个数
                count[j] = 0;
            }
		   //桶内元素清空，准备下次计算	
            bucket = new int[10][length];
			
            //准备下一轮位数比对
            divisor = divisor * 10;
        }

        System.out.println("排序后:");
        for (int z : arr) {
            System.out.println(z);
        }
    }

//结果：
排序后:
11
13
17
28
32
44
54
56
72
79
82
95
```

