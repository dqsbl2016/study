# RMI

# 一、`Java RMI`简介

`Java RMI`用于不同虚拟机之间的通信，这些虚拟机可以在不同的主机上、也可以在同一个主机上；一个虚拟机中的对象调用另一个虚拟上中的对象的方法，只不过是允许被远程调用的对象要通过一些标志加以标识。这样做的特点如下：

- 优点：避免重复造轮子；
- 缺点：调用过程很慢，而且该过程是不可靠的，容易发生不可预料的错误，比如网络错误等；

在`RMI`中的核心是远程对象（remote object），除了对象本身所在的虚拟机，其他虚拟机也可以调用此对象的方法，而且这些虚拟机可以不在同一个主机上。每个远程对象都要实现一个或者多个远程接口来标识自己，声明了可以被外部系统或者应用调用的方法（当然也有一些方法是不想让人访问的）。

## 1.1 `RMI`的通信模型

从方法调用角度来看，`RMI`要解决的问题，是让客户端对远程方法的调用可以相当于对本地方法的调用而屏蔽其中关于远程通信的内容，即使在远程上，也和在本地上是一样的。

从客户端-服务器模型来看，客户端程序直接调用服务端，两者之间是通过`JRMP`（ [Java Remote Method Protocol](https://en.wikipedia.org/wiki/Java_Remote_Method_Protocol)）协议通信，这个协议类似于HTTP协议，规定了客户端和服务端通信要满足的规范。

但是实际上，客户端只与代表远程主机中对象的`Stub`对象进行通信，丝毫不知道`Server`的存在。客户端只是调用`Stub`对象中的本地方法，`Stub`对象是一个本地对象，它实现了远程对象向外暴露的接口，也就是说它的方法和远程对象暴露的方法的签名是相同的。客户端认为它是调用远程对象的方法，实际上是调用`Stub`对象中的方法。**可以理解为Stub对象是远程对象在本地的一个代理**，当客户端调用方法的时候，`Stub`对象会将调用通过网络传递给远程对象。

在`java 1.2`之前，与`Stub`对象直接对话的是`Skeleton`对象，在`Stub`对象将调用传递给`Skeleton`的过程中，其实这个过程是通过`JRMP`协议实现转化的，通过这个协议将调用从一个虚拟机转到另一个虚拟机。在`Java 1.2`之后，与`Stub`对象直接对话的是`Server`程序，不再是`Skeleton`对象了。

所以从逻辑上来看，数据是在`Client`和`Server`之间横向流动的，但是实际上是从`Client`到`Stub`，然后从`Skeleton`到`Server`这样纵向流动的。

![这里写图片描述](https://img-blog.csdn.net/20170521103734214?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

## 1.2 重要的问题

### 1.2.1 数据的传递问题

我们都知道在`Java`程序中引用类型（不包括基本类型）的参数传递是按引用传递的，对于在同一个虚拟机中的传递时是没有问题的，因为的参数的引用对应的是同一个内存空间，但是对于分布式系统中，由于对象不再存在于同一个内存空间，虚拟机A的对象引用对于虚拟机B没有任何意义，那么怎么解决这个问题呢？

- 第一种：将引用传递更改为值传递，也就是将对象序列化为字节，然后使用该字节的副本在客户端和服务器之间传递，而且一个虚拟机中对该值的修改不会影响到其他主机中的数据；但是对象的序列化也有一个问题，就是对象的嵌套引用就会造成序列化的嵌套，这必然会导致数据量的激增，因此我们需要有选择进行序列化，在

  ```
  Java
  ```

  中一个对象如果能够被序列化，需要满足下面两个条件之一：

   

  - 是`Java`的基本类型；
  - 实现`java.io.Serializable`接口（`String`类即实现了该接口）；
  - 对于容器类，如果其中的对象是可以序列化的，那么该容器也是可以序列化的；
  - 可序列化的子类也是可以序列化的；

- 第二种：仍然使用引用传递，每当远程主机调用本地主机方法时，该调用还要通过本地主机查询该引用对应的对象，在任何一台机器上的改变都会影响原始主机上的数据，因为这个对象是共享的；

`RMI`中的参数传递和结果返回可以使用的三种机制（取决于数据类型）：

- 简单类型：按值传递，直接传递数据拷贝；
- 远程对象引用（实现了`Remote`接口）：以远程对象的引用传递；
- 远程对象引用（未实现`Remote`接口）：按值传递，通过序列化对象传递副本，本身不允许序列化的对象不允许传递给远程方法；

### 1.2.2 远程对象的发现问题

在调用远程对象的方法之前需要一个远程对象的引用，如何获得这个远程对象的引用在`RMI`中是一个关键的问题，如果将远程对象的发现类比于`IP`地址的发现可能比较好理解一些。

在我们日常使用网络时，基本上都是通过域名来定位一个网站，但是实际上网络是通过`IP`地址来定位网站的，因此其中就需要一个映射的过程，域名系统（`DNS`）就是为了这个目的出现的，在域名系统中通过域名来查找对应的`IP`地址来访问对应的服务器。那么对应的，`IP`地址在这里就相当于远程对象的引用，而`DNS`则相当于一个**注册表**（Registry）。而域名在RMI中就相当于远程对象的标识符，客户端通过提供远程对象的标识符访问注册表，来得到远程对象的引用。这个标识符是类似`URL`地址格式的，它要满足的规范如下：

- 该名称是`URL`形式的，类似于`http`的`URL`，schema是rmi；
- 格式类似于`rmi://host:port/name`，`host`指明注册表运行的注解，`port`表明接收调用的端口，`name`是一个标识该对象的简单名称。
- 主机和端口都是可选的，如果省略主机，则默认运行在本地；如果端口也省略，则默认端口是**1099**；

# 二、编程实现

## 2.1 基本内容

实现`RMI`所需的`API`几乎都在：

- `java.rmi`：提供**客户端**需要的类、接口和异常；
- `java.rmi.server`：提供**服务端**需要的类、接口和异常；
- `java.rmi.registry`：提供注册表的创建以及查找和命名远程对象的类、接口和异常；

其实在`RMI`中的客户端和服务端并没有绝对的界限，与Web应用中的客户端和服务器还是有区别的。这两者其实是平等的，客户端可以为服务端提供远程调用的方法，这时候，原来的客户端就是服务器端。

## 2.2 基本实现之一（注册表单独运行）

### 2.2.1 构建服务器端

什么是远程对象？首先从名称上来看，远程对象是存在于服务端以供客户端调用。那么什么对象可以被客户端进行远程调用？这个问题从编程的角度来看，**实现了java.rmi.Remote接口的类或者继承了java.rmi.Remote接口的所有接口都是远程对象**。这些继承或者实现了该接口的类或者接口中定义了客户端可以访问的方法。这个远程对象中可能有很多个方法，但是**只有在远程接口中声明的方法才能从远程调用**，其他的公共方法只能在本地虚拟机中使用。

实现过程中的注意事项：

- 子接口的每个方法都**必须**声明抛出`java.rmi.RemoteException`异常，该异常是使用`RMI`时可能抛出的大多数异常的父类。
- 子接口的实现类应该直接或者间接继承`java.rmi.server.UnicastRemoteObject`类，该类提供了很多支持`RMI`的方法，具体来说，这些方法可以通过`JRMP`协议导出一个远程对象的引用，并通过动态代理构建一个可以和远程对象交互的`Stub`对象。具体的实现看如下的例子。

首先远程接口如下：



```java
public interface UserHandler extends Remote {
    String getUserName(int id) throws RemoteException;
    int getUserCount() throws RemoteException;
    User getUserByName(String name) throws RemoteException;
}12345
```

远程接口的实现类如下：



```java
public class UserHandlerImpl extends UnicastRemoteObject implements UserHandler {
    // 该构造期必须存在，因为集继承了UnicastRemoteObject类，其构造器要抛出RemoteException
    public UserHandlerImpl() throws RemoteException {
        super();
    }

    @Override
    public String getUserName(int id) throws RemoteException {
        return "lmy86263";
    }
    @Override
    public int getUserCount() throws RemoteException{
        return 1;
    }
    @Override
    public User getUserByName(String name) throws RemoteException{
        return new User("lmy86263", 1);
    }
}12345678910111213141516171819
```

为了测试在使用`RMI`的序列化的问题，这里特别设置了一个引用类型`User`：



```java
public class User implements Serializable {
    // 该字段必须存在
    private static final long serialVersionUID = 42L;
    // setter和getter可以没有
    String name;
    int id;

    public User(String name, int id) {
        this.name = name;
        this.id = id;
    }
}123456789101112
```

在`Java 1.4`及 以前的版本中需要手动建立`Stub`对象，通过运行`rmic`命令来生成远程对象实现类的`Stub`对象，但是在`Java 1.5`之后可以通过[动态代理](http://blog.csdn.net/lmy86263/article/details/50764643)来完成，不再需要这个过程了。

运行该远程对象的服务器代码如下：

```java
UserHandler userHandler = null;
try {
    userHandler = new UserHandlerImpl();
    Naming.rebind("user", userHandler);
    System.out.println(" rmi server is ready ...");
} catch (Exception e) {
    e.printStackTrace();
}12345678
```

这里面的核心代码为`Naming.rebind("user", userHandler)` ，通过一个名称映射到该远程对象的引用，客户端通过该名称获取该远程对象的引用。

在远程对象中有三个方法：`getUserName(int id)` 和`getUserCount()`的参数和返回结果都是基本类型，因此是默认序列化的，但是对于`getUserByName(String name)`方法，返回的结果是一个引用类型，因此会涉及到序列化与反序列的问题，对于User类，必须满足以下条件：

- 必须实现`java.io.Serializable`接口；

- 其中必须有`serialVersionUID`字段，格式如下：

  ```
  private static final long serialVersionUID = 42L;1
  ```

  如果没有该字段，则默认该类会随机生成一个整数，且在客户端和服务器生成的整数不相同，则会抛出异常如下：

  ![这里写图片描述](https://img-blog.csdn.net/20170521103850956?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

  而且在**服务器和客户端这个字段必须保持一致才能进行反序列化**，如果两端都有该字段，但是数据不一致，则会抛出异常如下：

![这里写图片描述](https://img-blog.csdn.net/20170521103917358?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

- 这个类在服务器和客户端都必须可用；
- 在序列化的时候，如果在字段前加入了`transient`关键字，则该数据不会被序列化；

### 2.2.2 构建注册表

注册表其实不用写任何代码，在你的`JAVA_HOME`下`bin`目录下有一个`rmiregistry.exe`程序，需要在你的程序的`classpath`下运行该程序。

在启动服务器的时候，实际上需要运行两个服务器：

- 一个是远程对象本身；
- 一个是允许客户端下载远程对象引用的注册表；

由于远程对象需要与注册表对话，所以必须首先启动注册表程序。当注册表程序没有启动的时候，如果强行启动远程对象服务器时，会抛出如下错误：

![这里写图片描述](https://img-blog.csdn.net/20170521103952988?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

确保远程对象类可以被注册表程序发现，当远程对象类没有被注册表程序发现时，则会发现如下错误：

![这里写图片描述](https://img-blog.csdn.net/20170521104008473?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

如果是使用`maven`管理工程，则在`target/classes`目录中启动该程序。

这说明注册表程序时运行在一个单独的进程中的，它作为一个第三方的组件，来协调客户端和服务器之间的通信，但是与它们两个之间是完全解决解耦的。

rmiregistry.exe默认情况下是监听1099端口，如果已经该端口已经被使用了，可以通过命令

```shell
rmiregistry 1020 1
```

指定其他的端口来运行。

> 可以通过`start rmiregistry`命令在后台运行

运行完注册表程序后，就可以运行远程对象所在的服务器，以便接受客户端的连接。

### 2.2.3 构建客户端

客户端的代码如下：

```java
try {
    UserHandler handler = (UserHandler) Naming.lookup("user");
    int  count = handler.getUserCount();
    String name = handler.getUserName(1);
    System.out.println("name: " + name);
    System.out.println("count: " + count);
    System.out.println("user: " + handler.getUserByName("lmy86263"));
} catch (NotBoundException e) {
    e.printStackTrace();
} catch (MalformedURLException e) {
    e.printStackTrace();
} catch (RemoteException e) {
    e.printStackTrace();
}1234567891011121314
```

在上边的代码中通过`Naming.lookup(...)`获取该远程对象的引用。这个方法通过一个指定的名称来获取，该名称必须与远程对象服务器绑定的名称一致。可以通过`Naming.list(...)`方法列出所有可用的远程对象。

在使用客户端连接服务器调用远程方法的时候，需要注意的问题如下：

- `UserHandler`类在客户端本地必须可用，不然无法指定要调用的方法，而且**其全限定名必须与服务器上的对象完全相同**，不然抛出如下异常：

  ![这里写图片描述](https://img-blog.csdn.net/20170521104026094?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

- **从注册表中获取的对象引用已经失去类型信息**，需要强制转化为远程对象类型。这样运行客户端的时候才能获得相应的响应；

- 如果在方法中使用到了引用类型，比如这里的`User`，那么**该类型的全限定名也必须与服务器的相同**，如果不相同则会抛出如下异常：

  ![这里写图片描述](https://img-blog.csdn.net/20170521104041895?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

- 客户端的引用类型的`serialVersionUID`字段要与服务器端的对象保持一致；

在客户端的`User`对象如下：



```java
public class User implements Serializable {
    // 与客户端的serialVersionUID字段数据一致
    private static final long serialVersionUID = 42L;
    // setter和getter可以没有
    String name;
    int id;

    @Override
    public String toString() {
        return "User{" + "name='" + name + '\'' + ", id=" + id + '}';
    }
}123456789101112
```

## 2.3 基本实现之二（服务端运行注册表程序）

对于实现二，和实现一的主要区别在注册表程序的运行，不再是通过`rmiregistry.exe`单独运行，而是通过编程来实现，而远程接口以及其实现类与实现一完全相同。

这里注册表的实现是通过`java.rmi.registry`包中的`Registry`接口和以及其实现类`LocateRegistry`来完成的。如果你详细查看JDK的源码的话，就会发现其实我们之前使用的`java.rmi.Naming`类中的方法实际上都是间接通过`Registry`和`LocateRegistry`实现的。

其中获取根据主机和端口获取注册表引用的源码如下：

```java
/**
* Returns a registry reference obtained from information in the URL.
*/
private static Registry getRegistry(ParsedNamingURL parsed) throws RemoteException {
    return LocateRegistry.getRegistry(parsed.host, parsed.port);
}123456
```

而且Naming中的方法和Registry中是一一对应的。

而如果要创建一个注册表，这里要使用的是`LocateRegistry`，该类中只要两类方法：

- 创建**本地注册表**并且获取该注册表的引用；

  - `createRegistry(int port)`
  - `createRegistry(int port, RMIClientSocketFactory csf, RMIServerSocketFactory ssf)`

- 直接获取注册表引用，**该注册表可以是本地运行的，也可以是远程运行的**，这类方法是不能够创建注册表的，只能等注册表程序运行起来之后，和它进行通信来获取引用，否则抛出异常如下：

  ![这里写图片描述](https://img-blog.csdn.net/20170521104058798?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvbG15ODYyNjM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

  其中的方法如下：

  - `getRegistry()`
  - `getRegistry(int port)`
  - `getRegistry(String host)`
  - `getRegistry(String host, int port)`
  - `getRegistry(String host, int port, RMIClientSocketFactory csf)`

  由于是可能从远程主机获取注册表引用，因此可能需要指定`Socket`套接字来和远程主机进行沟通，在这个过程中也有可能因为各种原因造成调用过程失败；

运行远程对象的服务器代码如下：



```java
UserHandler userHandler = null;
Registry registry = null;
try {
    registry = LocateRegistry.createRegistry(1099);
    userHandler = new UserHandlerImpl();
    registry.rebind("user", userHandler);
    System.out.println(" rmi server is ready ...");
} catch (RemoteException e) {
    e.printStackTrace();
}12345678910
```

除此之外，其他服务器端和客户端的代码与实现一完全相同。

关于`RMI`的实际使用，其中一种方式可以参考相关文章第6个，通过和`ZooKeeper`结合使用`RMI` 。

