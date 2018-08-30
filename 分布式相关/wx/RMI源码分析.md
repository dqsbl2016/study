



#                     RMI

## 定义

RMI（Remote Method Invocation）是Java中的[远程过程调用](http://baike.baidu.com/view/32726.htm)（Remote Procedure Call，RPC）实现，是一种分布式Java应用的实现方式

## 类层次结构

远程对象发布

![1535596957299](C:\Users\admin\AppData\Local\Temp\1535596957299.png)

远程引用层

![1535597022150](C:\Users\admin\AppData\Local\Temp\1535597022150.png)



## 源码解析

 ###  UserService实现

#### 类定义

```java
public class UserService extends UnicastRemoteObject implements IUserService
```

实现UnicastRemoteObject 从上面的结构层次图中可以看到它所处的位置，所有需要发布的远程服务对象都要继承这个类

#### 源码分析

 把UnicastRemoteObject 对象传递进去作为远程服务对象

![1535597718730](C:\Users\admin\AppData\Local\Temp\1535597718730.png)

继续调用重载的导出方法，构建一个UnicastServerRef对象，该类中实现了远程对象的发布服务，

![1535597836130](C:\Users\admin\AppData\Local\Temp\1535597836130.png)



继续执行负载导出方法

![1535598458527](C:\Users\admin\AppData\Local\Temp\1535598458527.png)



该方法中定义了生成的锁需要的代理和对服务的注册发布

![1535598945352](C:\Users\admin\AppData\Local\Temp\1535598945352.png)

具体的创建代理createProxy的执行流程

![1535599120792](C:\Users\admin\AppData\Local\Temp\1535599120792.png)

看一下具体的发射处理

![1535599183415](C:\Users\admin\AppData\Local\Temp\1535599183415.png)

至此构造对象完成，下面继续看导出服务

![1535599757679](C:\Users\admin\AppData\Local\Temp\1535599757679.png)

接下来的调用链为LiveRef ---->TcpEndPoint----->TCPTransport到这个类中就是具体的网络处理

![1535599978820](C:\Users\admin\AppData\Local\Temp\1535599978820.png)

看一下具体的监听方法

![1535600081926](C:\Users\admin\AppData\Local\Temp\1535600081926.png)

至此创建UserService服务完成，

### Registry实现

此接口为服务注册中心，通过它进行服务注册，然后提供客户端的调用，

调用形式

```java
LocateRegistry.createRegistry(8088);
```

去跟踪一下源码，我们可以看到它的实现类是RefistryImpl，在类结构层次中和unicastRemoteObject属于同一层次的实现，都继承了RemoteServer

![1535600272626](C:\Users\admin\AppData\Local\Temp\1535600272626.png)

继续跟进，在此功能下会封装一个liveRef对象，然后继续构建一个unicastServerRef和上面的很相像，

![1535600501411](C:\Users\admin\AppData\Local\Temp\1535600501411.png)

在往下进行跟进发现我们都走到同一个方法内】，熟悉的方法，和上面一样的也会创建一个服务对象，进行监听客户端的请求

![1535600610681](C:\Users\admin\AppData\Local\Temp\1535600610681.png)



### Naming.bind（绑定）

调用形式

```java
 Naming.rebind("rmi://127.0.0.1:8088/userservice",  userService);
```

它主要做了两件事情，一时构建Registery_stub对象，二是进行资源绑定，

代码跟进 此处的亮点，没有错，还是那些熟悉的代码，不出意外的它又殊途同归的调用了创建代理

![1535601119578](C:\Users\admin\AppData\Local\Temp\1535601119578.png)

上面就会生成一个registery_stub的实例

然后调用它的bind方法，this.ref=unicastRef ，里面实现了

![1535601296130](C:\Users\admin\AppData\Local\Temp\1535601296130.png)

构造一个远程连接（通过这个远程调用对象去绑定资源关系）

![1535604307016](C:\Users\admin\AppData\Local\Temp\1535604307016.png)



写入绑定的关系数据 var1=userservice   var2= userservice代理对象

![1535604404070](C:\Users\admin\AppData\Local\Temp\1535604404070.png)



### 客户端调用

调用形式

```java
 IUserService userService = (IUserService) Naming.lookup("rmi://127.0.0.1:8088/userservice");
```



至此 已建立好关联关系，这样在客户端进行调用的时候，会生成客户端的stub对象。然后通过远程调用返回userservice的代理对象，接着执行方法，整个过程是

client   ---->stub ------registery中心 ----->skelon---->service 

然后调用到具体实现方法

这里面的底层的网络操作都由stub和sekelon进行了封装首先还是构建出一个代理对象的 Registery_stub，

通过这个对象调用registery的sekelon进行代理的service的对象，进行访问，

也是通过Remotecall的方式

调用过程首先还是 获取registery_stub对象，和绑定走的是一样的



![1535608602781](C:\Users\admin\AppData\Local\Temp\1535608602781.png)

，然后接着调用具体的查询功能，把userservice服务名称传递进去，进行查找具体的代理服务对象，过程和上面的一样，先建立一个网络连接实例，然后写入要查询的服务名称，之后获取输入流 得到最终的对象，返回

![1535609002378](C:\Users\admin\AppData\Local\Temp\1535609002378.png)

到此源码分析结束