# 桶排序

时间复杂度为O(n)的排序，常见的有三种：

- **基数排序**(Radix Sort)
- **计数排序**(Counting Sort)
- **桶排序**(Bucket Sort)

今天，1分钟，争取让大家搞懂桶排序。

***画外音：百度“桶排序”，很多文章是错误的，本文内容与《算法导论》中的桶排序保持一致。***

 

桶排序的适用范围是，待排序的元素能够均匀分布在某一个范围[MIN, MAX]之间。

***画外音：很多业务场景是符合这一场景，待排序的元素在某一范围内，且是均匀分布的。***

 

桶排序需要两个辅助空间：

- 第一个辅助空间，是**桶空间**B
- 第二个辅助空间，是**桶内的元素链表空间**

总的来说，空间复杂度是O(n)。

 

桶排序有两个关键步骤：

- 扫描待排序数据A[N]，对于元素A[i]，放入对应的桶X
- A[i]放入桶X，如果桶X已经有了若干元素，使用插入排序，将arr[i]放到桶内合适的位置

***画外音：***

***（1）桶X内的所有元素，是一直有序的；***

***（2）插入排序是稳定的，因此桶内元素顺序也是稳定的；***

 

当arr[N]中的所有元素，都按照上述步骤放入对应的桶后，就完成了全量的排序。

 

桶排序的伪代码是：

bucket_sort(A[N]){

​     for i =1 to n{

​           将A[i]放入对应的桶B[X];

​           使用插入排序，将A[i]插入到B[X]中正确的位置;

​     }

​     将B[X]中的所有元素，按顺序合并，排序完毕;

}

 

举个**栗子**：

假设待排序的数组均匀分布在[0, 99]之间：

{5,18,27,33,42,66,90,8,81,47,13,67,9,36,62,22}

可以设定10个桶，申请额外的空间bucket[10]来作为辅助空间。其中，每个桶bucket[i]来存放[10*i, 10*i+9]的元素链表。

![img](https://mmbiz.qpic.cn/mmbiz_png/YrezxckhYOxDap9ictbNA8xCYonsS3K8hSU1RTJWb378ricHktmgnibIOIFvOibOWFS0J0SfpzbPauAUbbQ5HzAIZA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

上图所示：

- 待排序的数组为unsorted[16]
- 桶空间是buket[10]
- 扫描所有元素之后，元素被放到了自己对应的桶里
- 每个桶内，使用插入排序，保证一直是有序的

例如，标红的元素66, 67, 62最终会在一个桶里，并且使用插入排序桶内保持有序。

 

最终，每个**桶**按照次序输出，排序完毕。

 

**神奇不神奇！！！**

 

桶排序(Bucket Sort)，总结：

- 桶排序，是一种复杂度为O(n)的排序
- 桶排序，是一种稳定的排序
- 桶排序，适用于数据均匀分布在一个区间内的场景



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
        //判断桶空间
        int size = (max/10)+1;

        Integer[][] sort = new Integer[size][10];

        //入桶
        for(Integer a :arr){
               if(sort[a/10][0] == null){
                   sort[a/10][0] = a;
               }else{
                   get(sort[a/10],a,0);
               }
        }

        int m = 0;
        //出桶
        for(int k =0; k < size;k++){
            if(sort[k] == null ){
                continue;
            }
            for(int j = 0; j< sort[k].length;j++){
                if(sort[k][j] == null){
                    continue;
                }
                arr[m++] = sort[k][j];
            }
        }

        System.out.println("排序后：");
        for(Integer a:arr){
            System.out.println(a);
        }

    }

	//确保插入有序
    private void get(Integer[] arrs,Integer value,Integer index){
         if(index == arrs.length -1 ) {
             return;
         }
        if(arrs[index] == null){
            arrs[index] = value;
            return;
        }
        int temp;
        if(arrs[index] > value){
            temp = arrs[index];
            arrs[index] = value;
         }else{
            temp = value;
        }
        get(arrs,temp,++index);
    }
```

