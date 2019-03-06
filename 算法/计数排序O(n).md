# 计数排序

**计数排序的适用范围？**

待排序的元素在某一个范围[MIN, MAX]之间。

***画外音：很多业务场景是符合这一场景，例如uint32的数字排序位于[0, 2^32]之间。***

 

**计数排序的空间复杂度？**

计数排序需要一个辅助空间，空间大小为O(MAX-MIN)，用来存储所有元素出现次数（“计数”）。

***画外音：计数排序的核心是，空间换时间。***

 

**计数排序的关键步骤？**

**步骤一**：扫描待排序数据arr[N]，使用计数数组counting[MAX-MIN]，对每一个arr[N]中出现的元素进行计数；

**步骤二**：扫描计数数组counting[]，还原arr[N]，排序结束；

 

举个**栗子**：

假设待排序的数组，

arr={5, 3, 7, 1, 8, 2, 9, 4, 7, 2, 6, 6, 2, 6, 6}

很容易发现，待排序的元素在[0, 10]之间，可以用counting[0,10]来存储计数。

 

**第一步：统计计数**

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOy4WlyQ3JQpvckE6jHf53fu7ImV7DRugTJ1dtEczd7icCOJN7EWfnKVMicNQFdKOqdgSrZ6podxfSuQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

扫描未排序的数组arr[N]，对每一个出现的元素进行计数。

扫描完毕后，计数数组counting[0, 10]会变成上图中的样子，如粉色示意，**6**这个元素在arr[N]中出现了**4**次，在counting[0, 10]中，**下标为6**的位置**计数是4**。

 

**第二步：还原数组**

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOy4WlyQ3JQpvckE6jHf53fuibABWDR5XEYyP323no07jBdV1VVSyNBsTekUf3wSrrRwx3lbCic2Wk7w/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

扫描计数数组counting[0, 10]，通过每个元素的计数，还原arr[N]。

如上图粉色示意，count[0, 10]**下标为6**的位置**计数是4**，排完序是**4个连续的6**。

从counting下标MIN到MAX，逐个还原，填满arr[N]时，排序结束。

 

**神奇不神奇！！！**

 

**计数排序**(Counting Sort)，总结：

- 计数排序，时间复杂度为O(n)；
- 当待排序元素个数很多，但值域范围很窄时，计数排序是很节省空间的；



代码：

```java

    private Integer[] arr ={72, 11, 82, 32, 11, 13, 17, 13, 54, 28, 79, 56};

    @Test
    public void test(){

        //获取最大值
        int max = 0;
        for(Integer a:arr){
            if(a > max){
                max = a;
            }
        }
		//建桶
        Integer[] sort = new Integer[max+1];


        //数据计算入桶
        for(int i =0 ; i< arr.length;i++){
            if(sort[arr[i]] == null){
                sort[arr[i]] = 1;
            }else{
                sort[arr[i]]++;
            }
        }

        int k = 0;
        //出桶
        for(int i =0; i< sort.length;i++){
            if(sort[i] == null){
                continue;
            }
            for(int j = 0; j <sort[i];j++){
                arr[k++] = i;
            }
        }

        System.out.println("排序后：");
        for(Integer a:arr){
            System.out.println(a);
        }


    }
```

