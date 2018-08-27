# Java RMI

RMI 全称是 remote method invocation – 远程方法调用，一种用于远程过程调用的应用程序编程接口，是纯 java 的网络分布式应用系统的核心解决方案之一。

RMI 目前使用 Java 远程消息交换协议 JRMP （Java Remote Messageing Protocol） 进行通信，由于 JRMP 是专为 Java对象制定的，是分布式应用系统的百分之百纯 java 解决方案,用 Java RMI 开发的应用系统可以部署在任何支持 JRE的平台上，缺点是，由于 JRMP 是专门为 java 对象指定的，因此 RMI 对于非 JAVA 语言开发的应用系统的支持不足，不能与非 JAVA 语言书写的对象进行通信。

## 使用

* 接口定义

  ```java
  import java.rmi.Remote;
  public interface MyService extends Remote {
  	public void sayHello() throws RemoteException;
  }
  ```

  其中接口需要继承Remote接口。定义的方法必须抛出throws RemoteException 异常。

* 实现定义

  ```java
  import java.rmi.RemoteException;
  import java.rmi.server.UnicastRemoteObject;
  public class MyServiceImp extends UnicastRemoteObject implements MyService {
  	private static final long serialVersionUID = 1L;
  	protected MyServiceImp() throws RemoteException {
  		super();
  	}
  	@Override
  	public void sayHello(String message) throws RemoteException {
  		System.out.println("Hello,"+message);
  	}
  }
  ```

  其中实现的类必须继承UnicastRemoteObject类。会生成一个调用父类构造的构造方法。实现的方法必须抛出throws RemoteException 异常。

* 发布

  ```java
  import java.net.MalformedURLException;
  import java.rmi.Naming;
  import java.rmi.RemoteException;
  import java.rmi.registry.LocateRegistry;
  
  public class ExportService {
  	public static void main(String[] args) throws RemoteException, MalformedURLException {
  		MyService myService = new MyServiceImp();
  		LocateRegistry.createRegistry(0);
  		Naming.rebind("rmi://127.0.0.1/Service", myService);
  		System.out.println("服务发布成功！");
  	}
  }
  ```

* 调用

  ```java
  import java.net.MalformedURLException;
  import java.rmi.Naming;
  import java.rmi.NotBoundException;
  import java.rmi.RemoteException;
  
  public class doService {
  	public static void main(String[] args) throws MalformedURLException, RemoteException, NotBoundException{
  		MyService myService = (MyService)Naming.lookup("rmi://127.0.0.1/Service");
  		myService.sayHello("Tom");
  	}
  }
  ```



## 源码分析

### 发布操作

发布过程一共分为三步操作，第一步实例化发布对象，第二步注册发布端口，第三步绑定服务地址。

#### 实例化对象过程

因为RMI的要求，实现类中必须继承`UnicastRemoteObject`类，而且会生成一个默认构造函数，其中会调用父类的构造方法。

```java
protected MyServiceImp() throws RemoteException {
		super();
	}
```

所以实例时会调用`UnicastRemoteObject`中的构造方法。

```java
 protected UnicastRemoteObject() throws RemoteException
    {
        this(0);
    }
 ...
  protected UnicastRemoteObject(int port) throws RemoteException
    {
        this.port = port;
        exportObject((Remote) this, port);
    }
...
 public static Remote exportObject(Remote obj, int port)
        throws RemoteException
    {
        return exportObject(obj, new UnicastServerRef(port));
    }
...
 private static Remote exportObject(Remote obj, UnicastServerRef sref)
        throws RemoteException
    {
        // if obj extends UnicastRemoteObject, set its ref.
        if (obj instanceof UnicastRemoteObject) {
            ((UnicastRemoteObject) obj).ref = sref;
        }
        return sref.exportObject(obj, null, false);
    }
```

这里可以看到默认设置端口为0，然后封装成UnicastServerRef对象，调用发布方法。其中调用正在的发布处理之前还有一步操作，判断`obj instanceof UnicastRemoteObject`当前对象是否为`UnicastRemoteObject`类型，因为当前的参数obj就是我们具体的实现类，而这个类是继承`UnicastRemoteObject`，所以会将sref的值赋给当前class中的ref属性。然后调用`UnicastServerRef`中的`exportObject`方法。

```java
 public Remote exportObject(Remote var1, Object var2, boolean var3) throws RemoteException {
        Class var4 = var1.getClass();

        Remote var5;
        try {
            var5 = Util.createProxy(var4, this.getClientRef(), this.forceStubUse);
        } catch (IllegalArgumentException var7) {
            throw new ExportException("remote object implements illegal remote interface", var7);
        }

        if (var5 instanceof RemoteStub) {
            this.setSkeleton(var1);
        }

        Target var6 = new Target(var1, this, var5, this.ref.getObjID(), var3);
        this.ref.exportObject(var6);
        this.hashToMethod_Map = (Map)hashToMethod_Maps.get(var4);
        return var5;
    }
```

首先创建代理类，

```java
public static Remote createProxy(Class<?> var0, RemoteRef var1, boolean var2) throws StubNotFoundException {
        Class var3;
        try {
            var3 = getRemoteClass(var0);
        } catch (ClassNotFoundException var9) {
            throw new StubNotFoundException("object does not implement a remote interface: " + var0.getName());
        }

        if (var2 || !ignoreStubClasses && stubClassExists(var3)) {
            return createStub(var3, var1);
        } else {
            final ClassLoader var4 = var0.getClassLoader();
            final Class[] var5 = getRemoteInterfaces(var0);
            final RemoteObjectInvocationHandler var6 = new RemoteObjectInvocationHandler(var1);

            try {
                return (Remote)AccessController.doPrivileged(new PrivilegedAction<Remote>() {
                    public Remote run() {
                        return (Remote)Proxy.newProxyInstance(var4, var5, var6);
                    }
                });
            } catch (IllegalArgumentException var8) {
                throw new StubNotFoundException("unable to create proxy", var8);
            }
        }
    }
```

这里先调用getRemoteClass方法，其中参数var0为实现类。

```java
 private static Class<?> getRemoteClass(Class<?> var0) throws ClassNotFoundException {
        while(var0 != null) {
            Class[] var1 = var0.getInterfaces();

            for(int var2 = var1.length - 1; var2 >= 0; --var2) {
                if (Remote.class.isAssignableFrom(var1[var2])) {
                    return var0;
                }
            }

            var0 = var0.getSuperclass();
        }

        throw new ClassNotFoundException("class does not implement java.rmi.Remote");
    }
```

首先获取实现类的所有接口，然后遍历，这里采用了倒序的遍历方式，遍历中会进行判断，如果符合则返回当前类。

>isAssignableFrom  判断处理
>
>有两个Class类型的类象，一个是调用isAssignableFrom方法的类对象（后称对象a），以及方法中作为参数的这个类对象（称之为对象b），这两个对象如果满足以下条件则返回true，否则返回false：
>
>​    a对象所对应类信息是b对象所对应的类信息的父类或者是父接口，简单理解即a是b的父类或接口
>
>​    a对象所对应类信息与b对象所对应的类信息相同，简单理解即a和b为同一个类或同一个接口
>
>例子：
>
>```java
>//说明：Protocol是接口，DubboProtocol是Protocol的实现
>Class protocolClass = Protocol.class ;   
>Class dubboProtocolClass = DubboProtocol.class ;
>        
>        
> protocolClass.isAssignableFrom(dubboProtocolClass )) ;   //返回true
> protocolClass.isAssignableFrom(protocolClass )) ;        //返回true
> dubboProtocolClass.isAssignableFrom(protocolClass )) ;   //返回false
>```

这里应该就是判断实现类实现的接口是否继承了`Remote`接口。

继续回到上面，会有一段判断

```java
if (var2 || !ignoreStubClasses && stubClassExists(var3)) 
```

这里var2 是传过来的参数，在前面使用`new UnicastServerRef(port)`封装端口的时候，实例化`UnicastServerRef`设置了属性`forceStubUse`为false，然后传入到当前方法中，所以这里的var2是false，

继续判断`ignoreStubClasses` ,这个在Util类中的静态代码

```java
 static {
        serverRefLog = Log.getLog("sun.rmi.server.ref", "transport", logLevel);
        ignoreStubClasses = (Boolean)AccessController.doPrivileged(new GetBooleanAction("java.rmi.server.ignoreStubClasses"));
        withoutStubs = Collections.synchronizedMap(new WeakHashMap(11));
        stubConsParamTypes = new Class[]{RemoteRef.class};
    }
```

这个里面`AccessController.doPrivileged`是一个本地方法，这个是将`GetBooleanAction`实例标识为特权。

**具体未理解**

然后最后一个判断是stubClassExists(var3)，是否已存在代理类。

这个判断最后结果为false。  

>java 中 && 会比 || 优先执行   所以最后为 false || true &&false   最后为false   

继续上面逻辑分析，这里会进入else的逻辑处理。

```java
else {
            final ClassLoader var4 = var0.getClassLoader();
            final Class[] var5 = getRemoteInterfaces(var0);
            final RemoteObjectInvocationHandler var6 = new RemoteObjectInvocationHandler(var1);

            try {
                return (Remote)AccessController.doPrivileged(new PrivilegedAction<Remote>() {
                    public Remote run() {
                        return (Remote)Proxy.newProxyInstance(var4, var5, var6);
                    }
                });
            } catch (IllegalArgumentException var8) {
                throw new StubNotFoundException("unable to create proxy", var8);
            }
        }
```

首先会获取各种资源，这里会生成一个new RemoteObjectInvocationHandler(var1)，然后通过newProxyInstance生成代理

```java
 @CallerSensitive
    public static Object newProxyInstance(ClassLoader loader,
                                          Class<?>[] interfaces,
                                          InvocationHandler h)
        throws IllegalArgumentException
    {
        Objects.requireNonNull(h);

        final Class<?>[] intfs = interfaces.clone();
        final SecurityManager sm = System.getSecurityManager();
        if (sm != null) {
            checkProxyAccess(Reflection.getCallerClass(), loader, intfs);
        }

        /*
         * Look up or generate the designated proxy class.
         */
        Class<?> cl = getProxyClass0(loader, intfs);

        /*
         * Invoke its constructor with the designated invocation handler.
         */
        try {
            if (sm != null) {
                checkNewProxyPermission(Reflection.getCallerClass(), cl);
            }

            final Constructor<?> cons = cl.getConstructor(constructorParams);
            final InvocationHandler ih = h;
            if (!Modifier.isPublic(cl.getModifiers())) {
                AccessController.doPrivileged(new PrivilegedAction<Void>() {
                    public Void run() {
                        cons.setAccessible(true);
                        return null;
                    }
                });
            }
            return cons.newInstance(new Object[]{h});
        } catch (IllegalAccessException|InstantiationException e) {
            throw new InternalError(e.toString(), e);
        } catch (InvocationTargetException e) {
            Throwable t = e.getCause();
            if (t instanceof RuntimeException) {
                throw (RuntimeException) t;
            } else {
                throw new InternalError(t.toString(), t);
            }
        } catch (NoSuchMethodException e) {
            throw new InternalError(e.toString(), e);
        }
    }
```

获取要创建代理的类，通过构造函数进行实例。

继续回到上面，当创建好代理后，

```java
  Target var6 = new Target(var1, this, var5, this.ref.getObjID(), var3);
        this.ref.exportObject(var6);
        this.hashToMethod_Map = (Map)hashToMethod_Maps.get(var4);
        return var5;
```

会继续封装一个Target对象，然后调用`exportObject`进行服务发布。

```java
public void exportObject(Target var1) throws RemoteException {
        this.ep.exportObject(var1);
    }
...
public void exportObject(Target var1) throws RemoteException {
        this.transport.exportObject(var1);
    }
...
 public void exportObject(Target var1) throws RemoteException {
        synchronized(this) {
            this.listen();
            ++this.exportCount;
        }

        boolean var2 = false;
        boolean var12 = false;

        try {
            var12 = true;
            super.exportObject(var1);
            var2 = true;
            var12 = false;
        } finally {
            if (var12) {
                if (!var2) {
                    synchronized(this) {
                        this.decrementExportCount();
                    }
                }

            }
        }

        if (!var2) {
            synchronized(this) {
                this.decrementExportCount();
            }
        }

    }
```

发布服务会调用`sun.rmi.transport.tcp.TCPTransport`中的`exportObject`方法，进行TCP协议发布服务。

首先会进行`synchronized`锁住类，然后调用`listen`方法进行发布。

```java
private void listen() throws RemoteException {
        assert Thread.holdsLock(this);

        TCPEndpoint var1 = this.getEndpoint();
        int var2 = var1.getPort();
        if (this.server == null) {
            if (tcpLog.isLoggable(Log.BRIEF)) {
                tcpLog.log(Log.BRIEF, "(port " + var2 + ") create server socket");
            }

            try {
                this.server = var1.newServerSocket();
                Thread var3 = (Thread)AccessController.doPrivileged(new NewThreadAction(new TCPTransport.AcceptLoop(this.server), "TCP Accept-" + var2, true));
                var3.start();
            } catch (BindException var4) {
                throw new ExportException("Port already in use: " + var2, var4);
            } catch (IOException var5) {
                throw new ExportException("Listen failed on port: " + var2, var5);
            }
        } else {
            SecurityManager var6 = System.getSecurityManager();
            if (var6 != null) {
                var6.checkListen(var2);
            }
        }

    }
```

这里是TCP内部的实现，新建ServerSocket连接，然后开启一个线程，处理等待连接。

然后执行exportObject发布操作，将代理放入发布服务列表中。

```java
 public void exportObject(Target var1) throws RemoteException {
        var1.setExportedTransport(this);
        ObjectTable.putTarget(var1);
    }
。。。
 static void putTarget(Target var0) throws ExportException {
        ObjectEndpoint var1 = var0.getObjectEndpoint();
        WeakRef var2 = var0.getWeakImpl();
        if (DGCImpl.dgcLog.isLoggable(Log.VERBOSE)) {
            DGCImpl.dgcLog.log(Log.VERBOSE, "add object " + var1);
        }

        Object var3 = tableLock;
        synchronized(tableLock) {
            if (var0.getImpl() != null) {
                if (objTable.containsKey(var1)) {
                    throw new ExportException("internal error: ObjID already in use");
                }

                if (implTable.containsKey(var2)) {
                    throw new ExportException("object already exported");
                }

                objTable.put(var1, var0);
                implTable.put(var2, var0);
                if (!var0.isPermanent()) {
                    incrementKeepAliveCount();
                }
            }

        }
    }
```



#### 注册发布端口

通过`LocateRegistry.createRegistry(0);`进入

```java
public static Registry createRegistry(int port) throws RemoteException {
        return new RegistryImpl(port);
    }
。。。
 public RegistryImpl(final int var1) throws RemoteException {
        if (var1 == 1099 && System.getSecurityManager() != null) {
            try {
                AccessController.doPrivileged(new PrivilegedExceptionAction<Void>() {
                    public Void run() throws RemoteException {
                        LiveRef var1x = new LiveRef(RegistryImpl.id, var1);
                        RegistryImpl.this.setup(new UnicastServerRef(var1x));
                        return null;
                    }
                }, (AccessControlContext)null, new SocketPermission("localhost:" + var1, "listen,accept"));
            } catch (PrivilegedActionException var3) {
                throw (RemoteException)var3.getException();
            }
        } else {
            LiveRef var2 = new LiveRef(id, var1);
            this.setup(new UnicastServerRef(var2));
        }

    }
```

这里会先将端口号封装进LiveRef对象中，然后再封装成UnicastServerRef对象。然后进入setup方法

```java
 private void setup(UnicastServerRef var1) throws RemoteException {
        this.ref = var1;
        var1.exportObject(this, (Object)null, true);
    }
```

与上面一样进入发布服务流程，这里发布的是RegistryImpl这个实现类。

其中在创建代理的过程中，因为这个类的代理对象在java中已经存在，所以会进入到createStub(var3, var1)方法。

```java
  private static RemoteStub createStub(Class<?> var0, RemoteRef var1) throws StubNotFoundException {
        String var2 = var0.getName() + "_Stub";

        try {
            Class var3 = Class.forName(var2, false, var0.getClassLoader());
            Constructor var4 = var3.getConstructor(stubConsParamTypes);
            return (RemoteStub)var4.newInstance(var1);
        } 
      。。。
  }
```

直接通过反射，获取到代理对象RegistryImpl_Stub。然后同样封装成`Target`对象，进行发布。

#### 绑定服务地址

通过`Naming.rebind("rmi://127.0.0.1/Service", myService);`进入。

```java
public static void rebind(String name, Remote obj)
        throws RemoteException, java.net.MalformedURLException
    {
        ParsedNamingURL parsed = parseURL(name);
        Registry registry = getRegistry(parsed);

        if (obj == null)
            throw new NullPointerException("cannot bind to null");

        registry.rebind(parsed.name, obj);
    }
```

首先是对name的解析，

```java
 private static ParsedNamingURL parseURL(String str)
        throws MalformedURLException
    {
        try {
            return intParseURL(str);
        } catch (URISyntaxException ex) {
            /* With RFC 3986 URI handling, 'rmi://:<port>' and
             * '//:<port>' forms will result in a URI syntax exception
             * Convert the authority to a localhost:<port> form
             */
            MalformedURLException mue = new MalformedURLException(
                "invalid URL String: " + str);
            mue.initCause(ex);
            int indexSchemeEnd = str.indexOf(':');
            int indexAuthorityBegin = str.indexOf("//:");
            if (indexAuthorityBegin < 0) {
                throw mue;
            }
            if ((indexAuthorityBegin == 0) ||
                    ((indexSchemeEnd > 0) &&
                    (indexAuthorityBegin == indexSchemeEnd + 1))) {
                int indexHostBegin = indexAuthorityBegin + 2;
                String newStr = str.substring(0, indexHostBegin) +
                                "localhost" +
                                str.substring(indexHostBegin);
                try {
                    return intParseURL(newStr);
                } catch (URISyntaxException inte) {
                    throw mue;
                } catch (MalformedURLException inte) {
                    throw inte;
                }
            }
            throw mue;
        }
 }
```

通过调用`intParseURL`方法进行解析，这里再异常中会再做一次处理。

```java
private static ParsedNamingURL intParseURL(String str)
        throws MalformedURLException, URISyntaxException
    {
        URI uri = new URI(str);
        if (uri.isOpaque()) {
            throw new MalformedURLException(
                "not a hierarchical URL: " + str);
        }
        if (uri.getFragment() != null) {
            throw new MalformedURLException(
                "invalid character, '#', in URL name: " + str);
        } else if (uri.getQuery() != null) {
            throw new MalformedURLException(
                "invalid character, '?', in URL name: " + str);
        } else if (uri.getUserInfo() != null) {
            throw new MalformedURLException(
                "invalid character, '@', in URL host: " + str);
        }
        String scheme = uri.getScheme();
        if (scheme != null && !scheme.equals("rmi")) {
            throw new MalformedURLException("invalid URL scheme: " + str);
        }

        String name = uri.getPath();
        if (name != null) {
            if (name.startsWith("/")) {
                name = name.substring(1);
            }
            if (name.length() == 0) {
                name = null;
            }
        }

        String host = uri.getHost();
        if (host == null) {
            host = "";
            try {
                /*
                 * With 2396 URI handling, forms such as 'rmi://host:bar'
                 * or 'rmi://:<port>' are parsed into a registry based
                 * authority. We only want to allow server based naming
                 * authorities.
                 */
                uri.parseServerAuthority();
            } catch (URISyntaxException use) {
                // Check if the authority is of form ':<port>'
                String authority = uri.getAuthority();
                if (authority != null && authority.startsWith(":")) {
                    // Convert the authority to 'localhost:<port>' form
                    authority = "localhost" + authority;
                    try {
                        uri = new URI(null, authority, null, null, null);
                        // Make sure it now parses to a valid server based
                        // naming authority
                        uri.parseServerAuthority();
                    } catch (URISyntaxException use2) {
                        throw new
                            MalformedURLException("invalid authority: " + str);
                    }
                } else {
                    throw new
                        MalformedURLException("invalid authority: " + str);
                }
            }
        }
        int port = uri.getPort();
        if (port == -1) {
            port = Registry.REGISTRY_PORT;
        }
        return new ParsedNamingURL(host, port, name);
    }
```

这里对uri的解析，然后封装成`ParsedNamingURL`对象返回。

回到上面继续执行，会调用getRegistry方法，获取注册中心。

```java
 private static Registry getRegistry(ParsedNamingURL parsed)
        throws RemoteException
    {
        return LocateRegistry.getRegistry(parsed.host, parsed.port);
    }
    。。。
   public static Registry getRegistry(String host, int port,
                                       RMIClientSocketFactory csf)
        throws RemoteException
    {
        Registry registry = null;

        if (port <= 0)
            port = Registry.REGISTRY_PORT;

        if (host == null || host.length() == 0) {
            // If host is blank (as returned by "file:" URL in 1.0.2 used in
            // java.rmi.Naming), try to convert to real local host name so
            // that the RegistryImpl's checkAccess will not fail.
            try {
                host = java.net.InetAddress.getLocalHost().getHostAddress();
            } catch (Exception e) {
                // If that failed, at least try "" (localhost) anyway...
                host = "";
            }
        }

        /*
         * Create a proxy for the registry with the given host, port, and
         * client socket factory.  If the supplied client socket factory is
         * null, then the ref type is a UnicastRef, otherwise the ref type
         * is a UnicastRef2.  If the property
         * java.rmi.server.ignoreStubClasses is true, then the proxy
         * returned is an instance of a dynamic proxy class that implements
         * the Registry interface; otherwise the proxy returned is an
         * instance of the pregenerated stub class for RegistryImpl.
         **/
        LiveRef liveRef =
            new LiveRef(new ObjID(ObjID.REGISTRY_ID),
                        new TCPEndpoint(host, port, csf, null),
                        false);
        RemoteRef ref =
            (csf == null) ? new UnicastRef(liveRef) : new UnicastRef2(liveRef);

        return (Registry) Util.createProxy(RegistryImpl.class, ref, false);
    }
```

就是获取之前一步中创建的RegistryImpl代理对象。

**这里这个获取方式？？** 为什么不直接从集合中获取？ 是否考虑端口号不一致？

然后调用`registry.rebind(parsed.name, obj);`,会调用代理对象中的rebind方法。

```java
public void rebind(String var1, Remote var2) throws AccessException, RemoteException {
        try {
            RemoteCall var3 = super.ref.newCall(this, operations, 3, 4905912898345647071L);

            try {
                ObjectOutput var4 = var3.getOutputStream();
                var4.writeObject(var1);
                var4.writeObject(var2);
            } catch (IOException var5) {
                throw new MarshalException("error marshalling arguments", var5);
            }

            super.ref.invoke(var3);
            super.ref.done(var3);
        } catch (RuntimeException var6) {
            throw var6;
        } catch (RemoteException var7) {
            throw var7;
        } catch (Exception var8) {
            throw new UnexpectedException("undeclared checked exception", var8);
        }
    }
```

这里通过newCall，进入`sun.rmi.server.UnicastRef`中`newCall`方法。

```java
public RemoteCall newCall(RemoteObject var1, Operation[] var2, int var3, long var4) throws RemoteException {
        clientRefLog.log(Log.BRIEF, "get connection");
        Connection var6 = this.ref.getChannel().newConnection();

        try {
            clientRefLog.log(Log.VERBOSE, "create call context");
            if (clientCallLog.isLoggable(Log.VERBOSE)) {
                this.logClientCall(var1, var2[var3]);
            }

            StreamRemoteCall var7 = new StreamRemoteCall(var6, this.ref.getObjID(), var3, var4);

            try {
                this.marshalCustomCallData(var7.getOutputStream());
            } catch (IOException var9) {
                throw new MarshalException("error marshaling custom call data");
            }

            return var7;
        } catch (RemoteException var10) {
            this.ref.getChannel().free(var6, false);
            throw var10;
        }
    }
```

这里就是先创建一个TCP连接，然后将连接封装成StreamRemoteCall对象返回。然后将服务名和代理实现类写入。之后调用 super.ref.invoke(var3);方法

```java
public void invoke(RemoteCall var1) throws Exception {
        try {
            clientRefLog.log(Log.VERBOSE, "execute call");
            var1.executeCall();
        } catch (RemoteException var3) {
            clientRefLog.log(Log.BRIEF, "exception: ", var3);
            this.free(var1, false);
            throw var3;
        } catch (Error var4) {
            clientRefLog.log(Log.BRIEF, "error: ", var4);
            this.free(var1, false);
            throw var4;
        } catch (RuntimeException var5) {
            clientRefLog.log(Log.BRIEF, "exception: ", var5);
            this.free(var1, false);
            throw var5;
        } catch (Exception var6) {
            clientRefLog.log(Log.BRIEF, "exception: ", var6);
            this.free(var1, true);
            throw var6;
        }
    }
```

这里调用`executeCall`方法，会执行StreamRemoteCall中的

```java
public void executeCall() throws Exception {
        DGCAckHandler var2 = null;

        byte var1;
        try {
            if (this.out != null) {
                var2 = this.out.getDGCAckHandler();
            }

            this.releaseOutputStream();
            DataInputStream var3 = new DataInputStream(this.conn.getInputStream());
            byte var4 = var3.readByte();
            if (var4 != 81) {
                if (Transport.transportLog.isLoggable(Log.BRIEF)) {
                    Transport.transportLog.log(Log.BRIEF, "transport return code invalid: " + var4);
                }

                throw new UnmarshalException("Transport return code invalid");
            }

            this.getInputStream();
            var1 = this.in.readByte();
            this.in.readID();
        } catch (UnmarshalException var11) {
            throw var11;
        } catch (IOException var12) {
            throw new UnmarshalException("Error unmarshaling return header", var12);
        } finally {
            if (var2 != null) {
                var2.release();
            }

        }

        switch(var1) {
        case 1:
            return;
        case 2:
            Object var14;
            try {
                var14 = this.in.readObject();
            } catch (Exception var10) {
                throw new UnmarshalException("Error unmarshaling return", var10);
            }

            if (!(var14 instanceof Exception)) {
                throw new UnmarshalException("Return type not Exception");
            } else {
                this.exceptionReceivedFromServer((Exception)var14);
            }
        default:
            if (Transport.transportLog.isLoggable(Log.BRIEF)) {
                Transport.transportLog.log(Log.BRIEF, "return code invalid: " + var1);
            }

            throw new UnmarshalException("Return code invalid");
        }
    }
```

这里没明白做什么？验证数据？

然后调用super.ref.done(var3);

???

### 服务调用

服务调用通过Naming.lookup("rmi://127.0.0.1/Service"); 进入

```java
public static Remote lookup(String name)
        throws NotBoundException,
            java.net.MalformedURLException,
            RemoteException
    {
        ParsedNamingURL parsed = parseURL(name);
        Registry registry = getRegistry(parsed);

        if (parsed.name == null)
            return registry;
        return registry.lookup(parsed.name);
    }
```

首先一样解析URL，获取注册中心。也就是RegistryImpl代理类 RegistryImpl_Stub.

然后调用其中的lookup方法。

```java
public Remote lookup(String var1) throws AccessException, NotBoundException, RemoteException {
        try {
            RemoteCall var2 = super.ref.newCall(this, operations, 2, 4905912898345647071L);

            try {
                ObjectOutput var3 = var2.getOutputStream();
                var3.writeObject(var1);
            } catch (IOException var18) {
                throw new MarshalException("error marshalling arguments", var18);
            }

            super.ref.invoke(var2);

            Remote var23;
            try {
                ObjectInput var6 = var2.getInputStream();
                var23 = (Remote)var6.readObject();
            } catch (IOException var15) {
                throw new UnmarshalException("error unmarshalling return", var15);
            } catch (ClassNotFoundException var16) {
                throw new UnmarshalException("error unmarshalling return", var16);
            } finally {
                super.ref.done(var2);
            }

            return var23;
        } catch (RuntimeException var19) {
            throw var19;
        } catch (RemoteException var20) {
            throw var20;
        } catch (NotBoundException var21) {
            throw var21;
        } catch (Exception var22) {
            throw new UnexpectedException("undeclared checked exception", var22);
        }
    }
```

这里会根据name地址获取到注册中心配置的服务。而获取到的服务对象就是我们发布服务生成的代理。

然后调用具体调用方法，这个时候代理类接收到服务请求后，会与服务端建立通信。

### 服务端接收客户端请求后的响应处理

客户端调用服务方法后，实际上调用的是代理对象的对应方法，而stub里面只有和网络相关的处理逻辑，并没有对应的业务处理逻辑 。比如说server上有一个add方法，stub中同样也有一个add方法，但是stub上的这个add方法并不包含添加的逻辑实现，他仅仅包含如何连接到远程的skeleton、调用方法的详细信息、参数、返回值等等。 

而服务端如何处理呢？服务端在之前listen()方法中启动了一个线程

```java
 Thread var3 = (Thread)AccessController.doPrivileged(new NewThreadAction(new TCPTransport.AcceptLoop(this.server), "TCP Accept-" + var2, true));            
```

其中`new TCPTransport.AcceptLoop(this.server)`中的run方法

```java
   public void run() {
            try {
                this.executeAcceptLoop();
            } finally {
                try {
                    this.serverSocket.close();
                } catch (IOException var7) {
                    ;
                }

            }

        }
```



```java
  private void executeAcceptLoop() {
            if (TCPTransport.tcpLog.isLoggable(Log.BRIEF)) {
                TCPTransport.tcpLog.log(Log.BRIEF, "listening on port " + TCPTransport.this.getEndpoint().getPort());
            }

            while(true) {
                Socket var1 = null;

                try {
                    var1 = this.serverSocket.accept();
                    InetAddress var16 = var1.getInetAddress();
                    String var3 = var16 != null ? var16.getHostAddress() : "0.0.0.0";

                    try {
                        TCPTransport.connectionThreadPool.execute(TCPTransport.this.new ConnectionHandler(var1, var3));
                    } catch (RejectedExecutionException var11) {
                        TCPTransport.closeSocket(var1);
                        TCPTransport.tcpLog.log(Log.BRIEF, "rejected connection from " + var3);
                    }
                } catch (Throwable var15) {
                    Throwable var2 = var15;

                    try {
                        if (this.serverSocket.isClosed()) {
                            return;
                        }

                        try {
                            if (TCPTransport.tcpLog.isLoggable(Level.WARNING)) {
                                TCPTransport.tcpLog.log(Level.WARNING, "accept loop for " + this.serverSocket + " throws", var2);
                            }
                        } catch (Throwable var13) {
                            ;
                        }
                    } finally {
                        if (var1 != null) {
                            TCPTransport.closeSocket(var1);
                        }

                    }

                    if (!(var15 instanceof SecurityException)) {
                        try {
                            TCPEndpoint.shedConnectionCaches();
                        } catch (Throwable var12) {
                            ;
                        }
                    }

                    if (!(var15 instanceof Exception) && !(var15 instanceof OutOfMemoryError) && !(var15 instanceof NoClassDefFoundError)) {
                        if (var15 instanceof Error) {
                            throw (Error)var15;
                        }

                        throw new UndeclaredThrowableException(var15);
                    }

                    if (!this.continueAfterAcceptFailure(var15)) {
                        return;
                    }
                }
            }
        }
```

获取到连接后，会通过线程池新建一个线程。

最后执行到handleMessages方法 再执行serviceCall方法， 根据之前存入流中的请求地址和方法来从之前记录的ObjectTable中的objTable中获取对应的Target  ，再获取var5.getDispatcher();  再通过 var6.dispatch(var37, var1); 获取到对应的方法 通过 var8.invoke(var1, var10); 执行方法

​                    

















参考：https://www.jianshu.com/p/2c78554a3f36