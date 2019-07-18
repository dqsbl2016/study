```
public class Name {
    private String first, last;

    public Name(String first, String last) {
        if (first == null || last == null)
            throw new NullPointerException();
        this.first = first;
        this.last = last;
    }

    public boolean equals(Name o) {
        return first.equals(o.first) && last.equals(o.last);
    }

    public int hashCode() {
        return 31 * first.hashCode() + last.hashCode();
    }

    public static void main(String[] args) {
        Set s = new HashSet();
        s.add(new Name("Mickey", "Mouse"));
        System.out.println(s.contains(new Name("Mickey", "Mouse")));
    }
}

以上程序输出内容是？

(a) true
(b) false
(c) 程序编译错误
(d) 以上都不是
```



```java
答案: B

首先contains的逻辑就是判断key是否相等，判断的逻辑（HashMap中getNode方法）
first.hash == hash && // always check first node
                ((k = first.key) == key || (key != null && key.equals(k)))，
需要判断hashcode相等与equals结果。
这里hashCode方法已经重写，但是equals没有。
Object中
 public boolean equals(Object obj) {
        return (this == obj);
    }
这个class中
   public boolean equals(Name o) {
        return first.equals(o.first) && last.equals(o.last);
    }
 参数类型不对，所以是重载而非重写。 所以equals返回为false。
 
 
 后续：
 这也是为什么重写hashcode的时候也一定要重写equals。
```

