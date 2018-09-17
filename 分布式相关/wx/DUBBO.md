# dubbo

### 定义

Dubbo是阿里巴巴SOA服务化治理方案的核心框架，每天为2,000+个服务提供3,000,000,000+次访问量支持，并被广泛应用于阿里巴巴集团的各成员站点。

Dubbo[]是一个分布式服务框架，致力于提供高性能和透明化的RPC远程服务调用方案，以及SOA服务治理方案。

它最大的特点是按照分层的方式来架构，使用这种方式可以使各个层之间解耦合（或者最大限度地松耦合）。从服务模型的角度来看，Dubbo采用的是一种非常简单的模型，要么是提供方提供服务，要么是消费方消费服务，所以基于这一点可以抽象出服务提供方（Provider）和服务消费方（Consumer）两个角色。关于注册中心、协议支持、服务监控等内容。

### 服务发布解析

在讲发布之前 先想一个问题，dubbo的配置文件是怎么加载的，加载之后映射的对象又是什么，在学习spring的时候，当读取非bean以外的标签，都是自定义标签的范畴，这时候就不得不说一个类的作用NamespaceHandlerSupport，它是进行标签解析的核心类，有了它我们就可以进行标签的解析工作，当然在dubbo同样是使用这样的解析方式。

那接下来重点是加载的入口处是哪里呢，之前我们在学习spring源码的时候回接触多很多的spring的扩展接口，这些接口会在spring初始化的过程中被主动调用，dubbo也是基于这样的方式进行调用的，

那么切入点是在哪里呢，我们可以通过 查找那些spring中扩展接口是否在dubbo中进行实现 这个方式进行查询，当然最简单还是看官方文档啊，这个查询的方式只是一种猜测。那么我们就会找到ServiceBean这个类，它是服务发布的入口点，那么让我们看一下它类的定义，它实现了InitializingBean, DisposableBean, ApplicationContextAware, ApplicationListener, BeanNameAware这些接口，在类中我们看到onApplicationEvent方法是ApplicationListener的实现，afterPropertiesSet方法是InitializingBean接口的实现，

那么可以认定是通过这两个实现方法进行初始化的，具体走哪一个入口，还需要看一些参数的判断，在这里不在展开。

重点开始了，

#### 服务端发布服务

我们以onApplicationEvent方法作为入口点

```java
if (ContextRefreshedEvent.class.getName().equals(event.getClass().getName())) {
   if (isDelay() && ! isExported() && ! isUnexported()) {
        if (logger.isInfoEnabled()) {
            logger.info("The service ready on spring started. service: " + getInterface());
        }
        //导出服务方法
        export();
    }
}
```

接着进入export方法，我们可以看到首先对export和delay参数进行获取，如果export不等于null且export等于false那么意味着该服务不支持导出，直接返回，接着下面获取delay  就是是否进行延时加载，如果不设置则直接进行导出操作doExport方法，话说带有do前缀的都是干活的方法

```java
if (provider != null) {
    if (export == null) {
        export = provider.getExport();
    }
    if (delay == null) {
        delay = provider.getDelay();
    }
}
if (export != null && ! export.booleanValue()) {
    return;
}
if (delay != null && delay > 0) {
    Thread thread = new Thread(new Runnable() {
        public void run() {
            try {
                Thread.sleep(delay);
            } catch (Throwable e) {
            }
            doExport();
        }
    });
    thread.setDaemon(true);
    thread.setName("DelayExportServiceThread");
    thread.start();
} else {
    doExport();
}
```

那么我们接着往下走，doExport的代码有点多，但是我还是坚持都贴一下，这里面的主要流程是一些基础判断

这些判断都是一些简单的逻辑判断，接下来就是对dubbo标签的基础对象进行初始化操作，然后调用相关的check方法，方法里面主要是对各种标签对象进行基础赋值操作，详细请看appendProperties这个方法，最后经过一些列的对象初始化并且赋值了配置的参数值，一切准备就绪，接下来开始正式导出操作，doExportUrls方法定义了这一过程，导出服务是基于协议进行的，比如我配置了dubbo hessian协议，那么这两个服务都会被进行发布

```java
if (unexported) {
    throw new IllegalStateException("Already unexported!");
}
if (exported) {
    return;
}
exported = true;
if (interfaceName == null || interfaceName.length() == 0) {
    throw new IllegalStateException("<dubbo:service interface=\"\" /> interface not allow null!");
}
checkDefault();
if (provider != null) {
    if (application == null) {
        application = provider.getApplication();
    }
    if (module == null) {
        module = provider.getModule();
    }
    if (registries == null) {
        registries = provider.getRegistries();
    }
    if (monitor == null) {
        monitor = provider.getMonitor();
    }
    if (protocols == null) {
        protocols = provider.getProtocols();
    }
}
if (module != null) {
    if (registries == null) {
        registries = module.getRegistries();
    }
    if (monitor == null) {
        monitor = module.getMonitor();
    }
}
if (application != null) {
    if (registries == null) {
        registries = application.getRegistries();
    }
    if (monitor == null) {
        monitor = application.getMonitor();
    }
}
if (ref instanceof GenericService) {
    interfaceClass = GenericService.class;
    if (StringUtils.isEmpty(generic)) {
        generic = Boolean.TRUE.toString();
    }
} else {
    try {
        interfaceClass = Class.forName(interfaceName, true, Thread.currentThread()
                .getContextClassLoader());
    } catch (ClassNotFoundException e) {
        throw new IllegalStateException(e.getMessage(), e);
    }
    checkInterfaceAndMethods(interfaceClass, methods);
    checkRef();
    generic = Boolean.FALSE.toString();
}
if(local !=null){
    if("true".equals(local)){
        local=interfaceName+"Local";
    }
    Class<?> localClass;
    try {
        localClass = ClassHelper.forNameWithThreadContextClassLoader(local);
    } catch (ClassNotFoundException e) {
        throw new IllegalStateException(e.getMessage(), e);
    }
    if(!interfaceClass.isAssignableFrom(localClass)){
        throw new IllegalStateException("The local implemention class " + localClass.getName() + " not implement interface " + interfaceName);
    }
}
if(stub !=null){
    if("true".equals(stub)){
        stub=interfaceName+"Stub";
    }
    Class<?> stubClass;
    try {
        stubClass = ClassHelper.forNameWithThreadContextClassLoader(stub);
    } catch (ClassNotFoundException e) {
        throw new IllegalStateException(e.getMessage(), e);
    }
    if(!interfaceClass.isAssignableFrom(stubClass)){
        throw new IllegalStateException("The stub implemention class " + stubClass.getName() + " not implement interface " + interfaceName);
    }
}
checkApplication();
checkRegistry();
checkProtocol();
appendProperties(this);
checkStubAndMock(interfaceClass);
if (path == null || path.length() == 0) {
    path = interfaceName;
}
doExportUrls();
```


现在我们看一下doExportUrls方法是做什么的，第一句简明扼要的要载入所有的注册中心，那么我们先看一下是如何进行载入的

```java
List<URL> registryURLs = loadRegistries(true);//是不是获得注册中心的配置
for (ProtocolConfig protocolConfig : protocols) { //是不是支持多协议发布
    doExportUrlsFor1Protocol(protocolConfig, registryURLs);
}
```

loadRegistries解析，该方法主要是获取dubbo文件中配置的注册中心，当然可以有多个，如zookeeper我们可以配置多个，用|分隔开来，就可以实现注册中心的集群了。

checkRegistry方法看似检查，其实里面做了赋值的操作

```
checkRegistry();
List<URL> registryList = new ArrayList<URL>();
if (registries != null && registries.size() > 0) {
    for (RegistryConfig config : registries) {
        String address = config.getAddress();
        if (address == null || address.length() == 0) {
           address = Constants.ANYHOST_VALUE;
        }
        String sysaddress = System.getProperty("dubbo.registry.address");
        if (sysaddress != null && sysaddress.length() > 0) {
            address = sysaddress;
        }
        if (address != null && address.length() > 0 
                && ! RegistryConfig.NO_AVAILABLE.equalsIgnoreCase(address)) {
            Map<String, String> map = new HashMap<String, String>();
            appendParameters(map, application);
            appendParameters(map, config);
            map.put("path", RegistryService.class.getName());
            map.put("dubbo", Version.getVersion());
            map.put(Constants.TIMESTAMP_KEY, String.valueOf(System.currentTimeMillis()));
            if (ConfigUtils.getPid() > 0) {
                map.put(Constants.PID_KEY, String.valueOf(ConfigUtils.getPid()));
            }
            if (! map.containsKey("protocol")) {
                if (ExtensionLoader.getExtensionLoader(RegistryFactory.class).hasExtension("remote")) {
                    map.put("protocol", "remote");
                } else {
                    map.put("protocol", "dubbo");
                }
            }
            List<URL> urls = UrlUtils.parseURLs(address, map);
            for (URL url : urls) {
                url = url.addParameter(Constants.REGISTRY_KEY, url.getProtocol());
                url = url.setProtocol(Constants.REGISTRY_PROTOCOL);
                if ((provider && url.getParameter(Constants.REGISTER_KEY, true))
                        || (! provider && url.getParameter(Constants.SUBSCRIBE_KEY, true))) {
                    registryList.add(url);
                }
            }
        }
    }
}
return registryList;
```

checkRegistry 方法解析，那么稍微讲一下这个，以后对于这样的方法不在讲了，看源码中的逻辑可以发现它从

ConfigUtils.getProperty("dubbo.registry.address")中获取dubbo配置文件中对应的参数，这个就是注册中心的地址，如果我们不设置配置中心则可以进行设置N/A, 这个地址是一定要有的，不然就会抛出异常，看逻辑中如果没有register配置项，则抛出如下的异常，接着最后appendProperties这个方法在上面已经有所讲述，就是针对传入的对象进行依赖注入，就是根据方法的名称获取配置文件中对该属性的设置的值，然后构造set方法进行注入

```java
if (registries == null || registries.size() == 0) {
    String address = ConfigUtils.getProperty("dubbo.registry.address");
    if (address != null && address.length() > 0) {
        registries = new ArrayList<RegistryConfig>();
        String[] as = address.split("\\s*[|]+\\s*");
        for (String a : as) {
            RegistryConfig registryConfig = new RegistryConfig();
            registryConfig.setAddress(a);
            registries.add(registryConfig);
        }
    }
}
if ((registries == null || registries.size() == 0)) {
    throw new IllegalStateException((getClass().getSimpleName().startsWith("Reference") 
            ? "No such any registry to refer service in consumer " 
                : "No such any registry to export service in provider ")
                                            + NetUtils.getLocalHost()
                                            + " use dubbo version "
                                            + Version.getVersion()
                                            + ", Please add <dubbo:registry address=\"...\" /> to your spring config. If you want unregister, please set <dubbo:service registry=\"N/A\" />");
}
for (RegistryConfig registryConfig : registries) {
    appendProperties(registryConfig);
}
```

我们继续分析下面的代码，这时候registries是有一个registery数据，就是我们配置文件中设置的registery标签中的数据，继续往下走我们会看到一个复合判断

其中 RegistryConfig.NO_AVAILABLE ==N/A，这个就是我们如果没有配置中心的话，就填入这个就可以，当满足上面的条件会构造一个RegistryConfig方法，然后加入到registries中去，这就是我上面讲到的配置了一个或者多个配置中心，这个条件就是限定了是否有配置中心，然后如果没有则registries是空的，那么在之后我们就可以看到是否注册到注册中心就是由它去判断的。我们是已有注册中心的为基础，进行讲解，因为没有注册中心就是不向注册中心进行注册了，对于服务发布是没有影响的。

这时候我们获取了所有的注册中心的配置数据，那么接下来我们继续走主线，

```java
if (address != null && address.length() > 0 
        && ! RegistryConfig.NO_AVAILABLE.equalsIgnoreCase(address)) 
```

现在进入基于协议的发布流程，发布是基于协议进行的，不同的协议发布成不同的服务

在继续强调一下是多协议发布

```java
for (ProtocolConfig protocolConfig : protocols) { //是不是支持多协议发布
    doExportUrlsFor1Protocol(protocolConfig, registryURLs);
}
```

下面应该到doExportUrlsFor1Protocol方法了，看来它也等急了，这么久才来，俗话说好饭不怕晚，下面就来品尝一下它的美味
这里面的代码确实太多了，我不得不拿其中的相关代码去分析，该方法前面大部分代码都是在获取正确的host（主机IP地址）；接下来的代码是对配置了method的标签进行解析，这些我们暂时略过，

主要看发布 分几种情况，当我们配置injvm，意思是服务将以injvm协议export出去，如果是同一个jvm的应用程序可以直接通过jvm发起调用，而不需要通过远程调用

```java
if ("injvm".equals(protocolConfig.getName())) {
        protocolConfig.setRegister(false);
        map.put("notify", "false");
}
```

```jva
String contextPath = protocolConfig.getContextpath();
if ((contextPath == null || contextPath.length() == 0) && provider != null) {
    contextPath = provider.getContextpath();
}
URL url = new URL(name, host, port, (contextPath == null || contextPath.length() == 0 ? "" : contextPath + "/") + path, map);

if (ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class)
        .hasExtension(url.getProtocol())) {
    url = ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class)
            .getExtension(url.getProtocol()).getConfigurator(url).configure(url);
}
```

下面是构建一个发布的URL地址，同时判断是否存在该协议的扩展点对象，如果存在则从中获取配置的url

```java
String contextPath = protocolConfig.getContextpath();
if ((contextPath == null || contextPath.length() == 0) && provider != null) {
    contextPath = provider.getContextpath();
}
URL url = new URL(name, host, port, (contextPath == null || contextPath.length() == 0 ? "" : contextPath + "/") + path, map);

if (ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class)
        .hasExtension(url.getProtocol())) {
    url = ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class)
            .getExtension(url.getProtocol()).getConfigurator(url).configure(url);
}
```

下面的代码就是核心中的核心，重点中的重点了，主要逻辑是发布服务，本地的或者远程的（注册中心）

首先获取scope属性值，如果scope没有设置或者是非NONE 则继续判断是否是远程remote，如果不是则发布本地服务，这个服务是有缓存的，这样可以通过本地接口服务进行服务服务调用，局域网中可以方便进行服务调用,接下来开始判断 scope是否配置了 LOCAL，这个表示是否只发布本地服务，接着判断registryURL是否有数据，它就是注册中心的服务了，现在我们配置了一个zookeeper的注册中心，那么代码往下继续走 ，Invoke就是代理了 真正 要执行的功能类，且看 ref 它就是指向接口实现类的引用

```java
String scope = url.getParameter(Constants.SCOPE_KEY);
//配置为none不暴露
if (! Constants.SCOPE_NONE.toString().equalsIgnoreCase(scope)) {

    //配置不是remote的情况下做本地暴露 (配置为remote，则表示只暴露远程服务)
    //发布服务
    if (!Constants.SCOPE_REMOTE.toString().equalsIgnoreCase(scope)) {
        exportLocal(url);
    }
    //如果配置不是local则暴露为远程服务.(配置为local，则表示只暴露本地服务)
    //注册服务
    if (! Constants.SCOPE_LOCAL.toString().equalsIgnoreCase(scope) ){
        if (logger.isInfoEnabled()) {
            logger.info("Export dubbo service " + interfaceClass.getName() + " to url " + url);
        }
        if (registryURLs != null && registryURLs.size() > 0
                && url.getParameter("register", true)) {
            for (URL registryURL : registryURLs) {//
                url = url.addParameterIfAbsent("dynamic", registryURL.getParameter("dynamic"));
                URL monitorUrl = loadMonitor(registryURL);
                if (monitorUrl != null) {
                    url = url.addParameterAndEncoded(Constants.MONITOR_KEY, monitorUrl.toFullString());
                }
                if (logger.isInfoEnabled()) {
                    logger.info("Register dubbo service " + interfaceClass.getName() + " url " + url + " to registry " + registryURL);
                }
                //通过proxyFactory来获取Invoker对象
                Invoker<?> invoker = proxyFactory.getInvoker(ref, (Class) interfaceClass, registryURL.addParameterAndEncoded(Constants.EXPORT_KEY, url.toFullString()));
                //注册服务
                Exporter<?> exporter = protocol.export(invoker);
                //将exporter添加到list中
                exporters.add(exporter);
            }
        } else {
            Invoker<?> invoker = proxyFactory.getInvoker(ref, (Class) interfaceClass, url);
            Exporter<?> exporter = protocol.export(invoker);
            exporters.add(exporter);
        }
    }
}
```

下面我们单拿出来这一句进行分析,这个proxyFactory是一个自定义扩展点

它的定义是private static final ProxyFactory proxyFactory = ExtensionLoader.getExtensionLoader(ProxyFactory.class).getAdaptiveExtension();通过对它的扩展点的查看它们都没有在类上使用@Adaptive，那么会生成一个动态的扩展ProxyFactory$Adpative对象，那么最终生成的扩展点是哪一个呢，看接口定义上的默认是javasissit，那么最终生的扩展 对象是JavassistProxyFactory，当然在生成的动态类中我们可以看到这一句 String extName = url.getParameter("proxy", "javassist");首先是通过proxy获取一个对应的值，这时候获取的是空 ，然后就用javassist默认值，然后生成一个具体的类型，就是上面说 的JavassistProxyFactory，那么最终执行的是该类的getInvoker方法，那么就分析一个该方法

```java
 Invoker<?> invoker = proxyFactory.getInvoker(ref, (Class) interfaceClass, registryURL.addParameterAndEncoded(Constants.EXPORT_KEY, url.toFullString()));
```

那么让我们继续分析一下getInvoker方法

```java
// TODO Wrapper类不能正确处理带$的类名
final Wrapper wrapper = Wrapper.getWrapper(proxy.getClass().getName().indexOf('$') < 0 ? proxy.getClass() : type);
return new AbstractProxyInvoker<T>(proxy, type, url) {
    @Override
    protected Object doInvoke(T proxy, String methodName, 
                              Class<?>[] parameterTypes, 
                              Object[] arguments) throws Throwable {
        return wrapper.invokeMethod(proxy, methodName, parameterTypes, arguments);
    }
};
```



现在分析一下这个复合语句，从这里可以看到SPI机制使用的多么的频繁，exporter和proxyFactory 都是通过这个机制获取的对象，见类的字段定义区

protocol = ExtensionLoader. getExtensionLoader(Protocol.class).getAdaptiveExtension(); 

proxyFactory= ExtensionLoader.getExtensionLoader(ProxyFactory.class).getAdaptiveExtension();

首先讲下proxyFactory，如果我们对之前讲解的SPI的源码已经了然于胸，那么这个就很好理解了，还是之前讲解的一个是上面的定义方式，还有一种根据名称获取具体的扩展点的形式，通过分析能够知道返回的对象到底是什么类型，这个具体的就不在展开，直接说了是StubProxyFactoryWrapper的扩展点，这是一个wrapper类型的对象。

先停下来想想，之前的源码如果有扩展对象 则把具体的对象通过构造方法进行封装之后进行返回，封装是什么对象呢，且看ProxyFactory接口有这个注解@SPI("javassist")，这个就是默认要返回的对象，这个就是典型的例子，那么就会执行StubProxyFactoryWrapper里面的getInvoker方法，上面说过默认的它包装了JavassistProxyFactory对象，所有具体的又是执行了

JavassistProxyFactory的getInvoker方法，下面看下它是怎么实现的

```java
Exporter<?> exporter = protocol.export(
        proxyFactory.getInvoker(ref, (Class) interfaceClass, local));
```



上面说道执行getInvoker方法，那么看看它的流程，它创建一个动态代理类，之后会使用它进行执行方法，主要是创建了一个AbstractProxyInvoker类型的对象，并重写了doInvoke方法，最后通过动态代理类的invokeMethod方法

```java
// TODO Wrapper类不能正确处理带$的类名
final Wrapper wrapper = Wrapper.getWrapper(proxy.getClass().getName().indexOf('$') < 0 ? proxy.getClass() : type);
return new AbstractProxyInvoker<T>(proxy, type, url) {
    @Override
    protected Object doInvoke(T proxy, String methodName, 
                              Class<?>[] parameterTypes, 
                              Object[] arguments) throws Throwable {
        return wrapper.invokeMethod(proxy, methodName, parameterTypes, arguments);
    }
};
```

下面讲 protocol.export(...）这个，它也是一个动态扩展点，然后最后获取的是ProtocolFilterWrapper（ProtocolListenerWrapper（RegisteryProtocol），因为上文中通过loadRegisters方法已经把配置文件的registery读取出来了，这时候通过动态适配扩展点中的流程可知，从URL中获取协议名称，然后构建对应的扩展点对象， 依次执行对应的export方法

ProtocolFilterWrapper ，如果registery协议，那么执行下面的代码，这时候protocol=ProtocolListenerWrapper

```java
if (Constants.REGISTRY_PROTOCOL.equals(invoker.getUrl().getProtocol())) {
    return protocol.export(invoker);
}
return protocol.export(buildInvokerChain(invoker, Constants.SERVICE_FILTER_KEY, Constants.PROVIDER));
```

继续到ProtocolListenerWrapper中继续执行，然后这时候protocol=RegistryProtocol,我们继续跟进

```java
if (Constants.REGISTRY_PROTOCOL.equals(invoker.getUrl().getProtocol())) {
    return protocol.export(invoker);
}
return new ListenerExporterWrapper<T>(protocol.export(invoker),  // DubboProtocol
        Collections.unmodifiableList(ExtensionLoader.getExtensionLoader(ExporterListener.class)
                .getActivateExtension(invoker.getUrl(), Constants.EXPORTER_LISTENER_KEY)));
```



RegisteryProtocol 类的export方法，在这个方法里实现了，发布dubbo服务和注册zookeeper配置中心，并且进行设置订阅监听服务，doLocalExport实现了发布服务到netty服务器，下面就先分析它到底 是怎么做的

```java
//export invoker
final ExporterChangeableWrapper<T> exporter = doLocalExport(originInvoker);
//registry provider
final Registry registry = getRegistry(originInvoker);
//得到需要注册到zk上的协议地址，也就是dubbo://
final URL registedProviderUrl = getRegistedProviderUrl(originInvoker);
registry.register(registedProviderUrl);
// 订阅override数据
// FIXME 提供者订阅时，会影响同一JVM即暴露服务，又引用同一服务的的场景，因为subscribed以服务名为缓存的key，导致订阅信息覆盖。
final URL overrideSubscribeUrl = getSubscribedOverrideUrl(registedProviderUrl);
final OverrideListener overrideSubscribeListener = new OverrideListener(overrideSubscribeUrl);
overrideListeners.put(overrideSubscribeUrl, overrideSubscribeListener);
registry.subscribe(overrideSubscribeUrl, overrideSubscribeListener);
//保证每次export都返回一个新的exporter实例
return new Exporter<T>() {
    public Invoker<T> getInvoker() {
        return exporter.getInvoker();
    }
    public void unexport() {
       try {
          exporter.unexport();
       } catch (Throwable t) {
           logger.warn(t.getMessage(), t);
        }
        try {
           registry.unregister(registedProviderUrl);
        } catch (Throwable t) {
           logger.warn(t.getMessage(), t);
        }
        try {
           overrideListeners.remove(overrideSubscribeUrl);
           registry.unsubscribe(overrideSubscribeUrl, overrideSubscribeListener);
        } catch (Throwable t) {
           logger.warn(t.getMessage(), t);
        }
  
    
    }
};
```

doLocalExport方法，实现 了导出dubbo服务的 操作，首先看第一句，获取缓存key，这个 方法是很重要的它是获取具体导出的key，即export参数中 的值，这个export的注入，请自行查阅，在这个方法里又调用了getProviderUrl方法，这个方法里定义了要获取的key值，即String export = origininvoker.getUrl().getParameterAndDecoded(Constants.EXPORT_KEY);通过这句代码获取export属性值，然后 构造成新的URL进行返回，然后获取的最终值是dubbo开头的协议，接着通过一系列缓存中去获取该key

是否有缓存，第一次肯定是没有的，然后继续执行代码此时，构建一个新的invokerDelegete对象讲originInvoker进行包装，传递的URL也是dubbo类型的，接着又构建了一个装饰的发布对象参数为invokerDelegete，这时候protocol=ProtocolFilterWrapper(ProtocolListener(DubboProtocol))，调用ProtocolFilterWrapper的export方法

```java
String key = getCacheKey(originInvoker);
ExporterChangeableWrapper<T> exporter = (ExporterChangeableWrapper<T>) bounds.get(key);
if (exporter == null) {
    synchronized (bounds) {
        exporter = (ExporterChangeableWrapper<T>) bounds.get(key);
        if (exporter == null) {
            final Invoker<?> invokerDelegete = new InvokerDelegete<T>(originInvoker, getProviderUrl(originInvoker));
            exporter = new ExporterChangeableWrapper<T>((Exporter<T>)protocol.export(invokerDelegete), originInvoker);
            bounds.put(key, exporter);
        }
    }
}
return (ExporterChangeableWrapper<T>) exporter;
```



我们来分析一下buildInvokerChain方法，从字面意思上是获取所有的过滤点，getActivateExtension这个方法是获取所有活动的扩展点，让我们来看看它的实现先是获取所有filter的实现类，这家伙消停点了，然后把这些组成一个过滤链，所有的请求都要经过这个链，

```java
Invoker<T> last = invoker;
List<Filter> filters = ExtensionLoader.getExtensionLoader(Filter.class).getActivateExtension(invoker.getUrl(), key, group);
if (filters.size() > 0) {
    for (int i = filters.size() - 1; i >= 0; i --) {
        final Filter filter = filters.get(i);
        final Invoker<T> next = last;
        last = new Invoker<T>() {

            public Class<T> getInterface() {
                return invoker.getInterface();
            }

            public URL getUrl() {
                return invoker.getUrl();
            }

            public boolean isAvailable() {
                return invoker.isAvailable();
            }

            public Result invoke(Invocation invocation) throws RpcException {
                return filter.invoke(next, invocation);
            }

            public void destroy() {
                invoker.destroy();
            }

            @Override
            public String toString() {
                return invoker.toString();
            }
        };
    }
```

下面解析buildInvokerChain方法，这个是构建了一个过滤器链，从下面filters获取了所有的活动的扩展点，有必要去展示一下

```
echo=com.alibaba.dubbo.rpc.filter.EchoFilter
generic=com.alibaba.dubbo.rpc.filter.GenericFilter
genericimpl=com.alibaba.dubbo.rpc.filter.GenericImplFilter
token=com.alibaba.dubbo.rpc.filter.TokenFilter
accesslog=com.alibaba.dubbo.rpc.filter.AccessLogFilter
activelimit=com.alibaba.dubbo.rpc.filter.ActiveLimitFilter
classloader=com.alibaba.dubbo.rpc.filter.ClassLoaderFilter
context=com.alibaba.dubbo.rpc.filter.ContextFilter
consumercontext=com.alibaba.dubbo.rpc.filter.ConsumerContextFilter
exception=com.alibaba.dubbo.rpc.filter.ExceptionFilter
executelimit=com.alibaba.dubbo.rpc.filter.ExecuteLimitFilter
deprecated=com.alibaba.dubbo.rpc.filter.DeprecatedFilter
compatible=com.alibaba.dubbo.rpc.filter.CompatibleFilter
timeout=com.alibaba.dubbo.rpc.filter.TimeoutFilter
```

这是所有的过滤器，在下面的代码中将这些过滤器封装成链的形式，这就是典型的链式模式，在每一个环节都处理与它相关的功能，这样做的好处就是单一职责和流水线作业的标准化，获取执行链之后，然后继续调用，这时候protocol就是ProtocolListenerWrapper，如果不明白看SPI那块。

```java
List<Filter> filters = ExtensionLoader.getExtensionLoader(Filter.class).getActivateExtension(invoker.getUrl(), key, group);
if (filters.size() > 0) {
    for (int i = filters.size() - 1; i >= 0; i --) {
        final Filter filter = filters.get(i);
        final Invoker<T> next = last;
        last = new Invoker<T>() {

            public Class<T> getInterface() {
                return invoker.getInterface();
            }

            public URL getUrl() {
                return invoker.getUrl();
            }

            public boolean isAvailable() {
                return invoker.isAvailable();
            }

            public Result invoke(Invocation invocation) throws RpcException {
                return filter.invoke(next, invocation);
            }

            public void destroy() {
                invoker.destroy();
            }

            @Override
            public String toString() {
                return invoker.toString();
            }
        };
```

这时候开始执行ProtocolListenerWrapper类中export方法，，这时候会构建一个ListenerExporterWrapper对象，其中传递两个参数，第一个是protocol，现在它是dubboProtocol对象，那么会接着执行它的export

```java
if (Constants.REGISTRY_PROTOCOL.equals(invoker.getUrl().getProtocol())) {
    return protocol.export(invoker);
}
return new ListenerExporterWrapper<T>(protocol.export(invoker),  // DubboProtocol
        Collections.unmodifiableList(ExtensionLoader.getExtensionLoader(ExporterListener.class)
                .getActivateExtension(invoker.getUrl(), Constants.EXPORTER_LISTENER_KEY)));
```

下面看一下DubboProtocol类中export是怎么写的，终于到了dubbo，我来了，哈哈，这里构建了一个DubboExporter对象，将invoker等进一步封装，然后返回；在这里通过调用openServer方法完成对netty进行发布服务，并且开启心跳监测

```java
URL url = invoker.getUrl();

// export service.
String key = serviceKey(url);
DubboExporter<T> exporter = new DubboExporter<T>(invoker, key, exporterMap);
exporterMap.put(key, exporter);

//export an stub service for dispaching event
Boolean isStubSupportEvent = url.getParameter(Constants.STUB_EVENT_KEY,Constants.DEFAULT_STUB_EVENT);
Boolean isCallbackservice = url.getParameter(Constants.IS_CALLBACK_SERVICE, false);
if (isStubSupportEvent && !isCallbackservice){
    String stubServiceMethods = url.getParameter(Constants.STUB_EVENT_METHODS_KEY);
    if (stubServiceMethods == null || stubServiceMethods.length() == 0 ){
        if (logger.isWarnEnabled()){
            logger.warn(new IllegalStateException("consumer [" +url.getParameter(Constants.INTERFACE_KEY) +
                    "], has set stubproxy support event ,but no stub methods founded."));
        }
    } else {
        stubServiceMethodsMap.put(url.getServiceKey(), stubServiceMethods);
    }
}

openServer(url);

return exporter;
```

下面看看openServer方法是如何实现的，在这里获取url地址，然后进行发布，具体走createServer方法，那么我们一同看看究竟

```java
// find server.
String key = url.getAddress();
//client 也可以暴露一个只有server可以调用的服务。
boolean isServer = url.getParameter(Constants.IS_SERVER_KEY,true);
if (isServer) {
   ExchangeServer server = serverMap.get(key);
   if (server == null) {
      serverMap.put(key, createServer(url));
   } else {
      //server支持reset,配合override功能使用
      server.reset(url);
   }
}
```

看看createServer方法是如何实现的，在这里加入参数设置，继续通过Exchangers.bind(url, requestHandler);去完成发布之路

```java
//默认开启server关闭时发送readonly事件
url = url.addParameterIfAbsent(Constants.CHANNEL_READONLYEVENT_SENT_KEY, Boolean.TRUE.toString());
//默认开启heartbeat
url = url.addParameterIfAbsent(Constants.HEARTBEAT_KEY, String.valueOf(Constants.DEFAULT_HEARTBEAT));
String str = url.getParameter(Constants.SERVER_KEY, Constants.DEFAULT_REMOTING_SERVER);

if (str != null && str.length() > 0 && ! ExtensionLoader.getExtensionLoader(Transporter.class).hasExtension(str))
    throw new RpcException("Unsupported server type: " + str + ", url: " + url);

url = url.addParameter(Constants.CODEC_KEY, Version.isCompatibleVersion() ? COMPATIBLE_CODEC_NAME : DubboCodec.NAME);
ExchangeServer server;
try {
    //发布服务
    server = Exchangers.bind(url, requestHandler);
} catch (RemotingException e) {
    throw new RpcException("Fail to start server(url: " + url + ") " + e.getMessage(), e);
}
str = url.getParameter(Constants.CLIENT_KEY);
if (str != null && str.length() > 0) {
    Set<String> supportedTypes = ExtensionLoader.getExtensionLoader(Transporter.class).getSupportedExtensions();
    if (!supportedTypes.contains(str)) {
        throw new RpcException("Unsupported client type: " + str);
    }
}
return server;
```



继续跟下bind方法代码，在这里又调用了一个扩展点方法getExchanger，bind方法是哪个对象执行的要先跟一下方法

```java
if (url == null) {
    throw new IllegalArgumentException("url == null");
}
if (handler == null) {
    throw new IllegalArgumentException("handler == null");
}
url = url.addParameterIfAbsent(Constants.CODEC_KEY, "exchange");
return getExchanger(url).bind(url, handler);
```

getExchanger方法里面，首先获取了一个type，这个type的值是header，取得默认的，继续跟进，慢慢清晰起来了

```java
String type = url.getParameter(Constants.EXCHANGER_KEY, Constants.DEFAULT_EXCHANGER);
return getExchanger(type);
```

getExchanger方法是一个扩展点，最终返回的对象是HeaderExchanger，这个还是SPI的范畴，不熟悉的话，移步SPI学习，至此确认了是执行HeaderExchanger的bind方法，那么书接上文，继续跟进吧

```java
ExtensionLoader.getExtensionLoader(Exchanger.class).getExtension(type);
```

bind方法里是这样实现的，构建了一个新的HeaderExchangeServer对象，并传递server对象，也就是具体的服务对象使用的mina或者netty服务器，解析一下 里面方法

```java
return new HeaderExchangeServer(Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler))));
```

这句代码里执行了很多东西，首先handler被两个对象进行封装，一个是解码相关，另一个是处理接收的请求，下面看下bind方法是怎么实现的

```java
Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler)))
```

继续跟进bind方法，在这里面进行一些基础判空判断，并且进行传递多个handler的时候用ChannelHandlerDispatcher（ps这个是处理器适配器）进行包装，我们发现又一个getTransporter方法。这个又是一个扩展点适配器，还是SPI，此处就不在重复讲解是怎么获取该扩展点的，直接说结果是NettyTransport,跟了这么久终于见到真身了，使用netty进行服务发布，然后最终调用的是NettyTransport的bind方法，继续跟进

```java
if (url == null) {
    throw new IllegalArgumentException("url == null");
}
if (handlers == null || handlers.length == 0) {
    throw new IllegalArgumentException("handlers == null");
}
ChannelHandler handler;
if (handlers.length == 1) {
    handler = handlers[0];
} else {
    handler = new ChannelHandlerDispatcher(handlers);
}
return getTransporter().bind(url, handler);
```

bind方法中 构建了一个netty的服务端，到这里启动了netty服务并且设置了监听，在往下就是关于netty的操作，这里就不展开了，构建好了server就放进缓存里，下次就不用再创建了，直接使用。

```java
return new NettyServer(url, listener);
```



这时候才走完doLocalExport方法逻辑，返回一个exporter的Wrapper对象，这个对象在return的时候会在新构建的Export对象里进一步调用。

接着往下走，往注册中心注册服务

下一步开始分析getRegistry这个方法，还 是源码为道，首先获取了当前的registery的URL实例，如果是registery开头 的协议类型，则通过这个registery获取对应的具体协议头，这里是zookeeper，这里的protocol=zookeeper

然后将zookeeper注入到registeryUrl中，然后最后一句  registeryFactory具体调用是哪一个呢，通过SPI我们可以知道是ZookeeperRegistryFactory，但是这里没有getRegistry方法，所以找到它的父类AbstractRegistryFactory，这里定义了该方法，所以继续跟进getRegistry方法

```java
URL registryUrl = originInvoker.getUrl(); //registry://
if (Constants.REGISTRY_PROTOCOL.equals(registryUrl.getProtocol())) {
    String protocol = registryUrl.getParameter(Constants.REGISTRY_KEY, Constants.DEFAULT_DIRECTORY);
    registryUrl = registryUrl.setProtocol(protocol).removeParameter(Constants.REGISTRY_KEY);
}//zookeeper://
return registryFactory.getRegistry(registryUrl);
```

getRegistry方法,首先构建url对象，然后同步获取registery，下面跟进一下createRegistry方法，这里是调用的ZookeeperRegisteryFactory类的方法

```java
url = url.setPath(RegistryService.class.getName())
      .addParameter(Constants.INTERFACE_KEY, RegistryService.class.getName())
      .removeParameters(Constants.EXPORT_KEY, Constants.REFER_KEY);
String key = url.toServiceString();
   // 锁定注册中心获取过程，保证注册中心单一实例
   LOCK.lock();
   try {
       Registry registry = REGISTRIES.get(key);
       if (registry != null) {
           return registry;
       }
       registry = createRegistry(url);
       if (registry == null) {
           throw new IllegalStateException("Can not create registry " + url);
       }
       REGISTRIES.put(key, registry);
       return registry;
   } finally {
       // 释放锁
       LOCK.unlock();
   }
```



继续跟进createRegistry方法，这都是核心啊，在这里构建了一个ZookeeperRegistry实例，继续跟进，没毛病

```java
return new ZookeeperRegistry(url, zookeeperTransporter);
```

在zookeeper构建中，我们看都了构建 了zkClinet的实例，然后设置了状态监听，如果是重新连接，则进行覆盖 ，至此registry已构建成功，这个是zookeeper连接的实例，

```java
   super(url);
   if (url.isAnyHost()) {
   throw new IllegalStateException("registry address == null");
}
   String group = url.getParameter(Constants.GROUP_KEY, DEFAULT_ROOT);
   if (! group.startsWith(Constants.PATH_SEPARATOR)) {
       group = Constants.PATH_SEPARATOR + group;
   }
   this.root = group;
   zkClient = zookeeperTransporter.connect(url);
   zkClient.addStateListener(new StateListener() {
       public void stateChanged(int state) {
           if (state == RECONNECTED) {
           try {
   recover();
} catch (Exception e) {
   logger.error(e.getMessage(), e);
}
           }
       }
   });
```

然后返回到调用处继续执行，调用处代码我在记录一遍，方便看，获取了registy之后继续往下走，获取registedProviderUrl地址，这里是dubbo开头的地址，然后调用register方法，注意啦，这时候registery具体的对象类型是什么呢，上面看是ZookeeperRegistery，但是通过调试我们发现是调用的FailbackRegistry类中的register方法，这是为什么呢，想想，想想，可能你已经知道，但我还是要停顿一下，注意啦，是因为Zookeeper中么有该方法，所以找到 它父类的FailbackRegistry的register方法，就这么个东西。

```java
//export invoker
final ExporterChangeableWrapper<T> exporter = doLocalExport(originInvoker);
//registry provider 代理执行到这一句，获取了registery
final Registry registry = getRegistry(originInvoker);
//得到需要注册到zk上的协议地址，也就是dubbo://
final URL registedProviderUrl = getRegistedProviderUrl(originInvoker);
registry.register(registedProviderUrl);
// 订阅override数据
// FIXME 提供者订阅时，会影响同一JVM即暴露服务，又引用同一服务的的场景，因为subscribed以服务名为缓存的key，导致订阅信息覆盖。
final URL overrideSubscribeUrl = getSubscribedOverrideUrl(registedProviderUrl);
final OverrideListener overrideSubscribeListener = new OverrideListener(overrideSubscribeUrl);
overrideListeners.put(overrideSubscribeUrl, overrideSubscribeListener);
registry.subscribe(overrideSubscribeUrl, overrideSubscribeListener);
//保证每次export都返回一个新的exporter实例
return new Exporter<T>() {
    public Invoker<T> getInvoker() {
        return exporter.getInvoker();
    }
    public void unexport() {
       try {
          exporter.unexport();
       } catch (Throwable t) {
           logger.warn(t.getMessage(), t);
        }
        try {
           registry.unregister(registedProviderUrl);
        } catch (Throwable t) {
           logger.warn(t.getMessage(), t);
        }
        try {
           overrideListeners.remove(overrideSubscribeUrl);
           registry.unsubscribe(overrideSubscribeUrl, overrideSubscribeListener);
        } catch (Throwable t) {
           logger.warn(t.getMessage(), t);
        }
    }
};
```

那么继续往下跟进吧register方法，在这里完成了注册，主要看doRegistery方法，一看do开头的就知道是真正干活的，一般是这样 哈哈，那么继续跟进吧，废话不多说

```java
super.register(url); //AbstractRegistry
failedRegistered.remove(url);
failedUnregistered.remove(url);
try {
    // 向服务器端发送注册请求
    doRegister(url);
} catch (Exception e) {
    doRegister Throwable t = e;

    // 如果开启了启动时检测，则直接抛出异常
    boolean check = getUrl().getParameter(Constants.CHECK_KEY, true)
            && url.getParameter(Constants.CHECK_KEY, true)
            && ! Constants.CONSUMER_PROTOCOL.equals(url.getProtocol());
    boolean skipFailback = t instanceof SkipFailbackWrapperException;
    if (check || skipFailback) {
        if(skipFailback) {
            t = t.getCause();
        }
        throw new IllegalStateException("Failed to register " + url + " to registry " + getUrl().getAddress() + ", cause: " + t.getMessage(), t);
    } else {
        logger.error("Failed to register " + url + ", waiting for retry, cause: " + t.getMessage(), t);
    }

    // 将失败的注册请求记录到失败列表，定时重试
    failedRegistered.add(url);
```

doRegistery方法里就这一句 ，好熟悉，有么有，使用zkClinet创建一个动态的url节点，这个就是dubbo服务的节点，注册到注册中心了。注册完之后 ，继续走流程，接下来会在注册中心注册订阅一个服务

```java
zkClient.create(toUrlPath(url), url.getParameter(Constants.DYNAMIC_KEY, true));
```

subscribe走这个订阅方法，我们看具体是怎么做的，又看到一个do开头的，它是具体干活的我们看看

```java
super.subscribe(url, listener);
removeFailedSubscribed(url, listener);
try {
    // 向服务器端发送订阅请求
    doSubscribe(url, listener);
} catch (Exception e) {
    Throwable t = e;

    List<URL> urls = getCacheUrls(url);
    if (urls != null && urls.size() > 0) {
        notify(url, listener, urls);
        logger.error("Failed to subscribe " + url + ", Using cached list: " + urls + " from cache file: " + getUrl().getParameter(Constants.FILE_KEY, System.getProperty("user.home") + "/dubbo-registry-" + url.getHost() + ".cache") + ", cause: " + t.getMessage(), t);
    } else {
        // 如果开启了启动时检测，则直接抛出异常
        boolean check = getUrl().getParameter(Constants.CHECK_KEY, true)
                && url.getParameter(Constants.CHECK_KEY, true);
        boolean skipFailback = t instanceof SkipFailbackWrapperException;
        if (check || skipFailback) {
            if(skipFailback) {
                t = t.getCause();
            }
            throw new IllegalStateException("Failed to subscribe " + url + ", cause: " + t.getMessage(), t);
        } else {
            logger.error("Failed to subscribe " + url + ", waiting for retry, cause: " + t.getMessage(), t);
        }
    }

    // 将失败的订阅请求记录到失败列表，定时重试
    addFailedSubscribed(url, listener);
```



dosubscibe，里面的方法逻辑就是往zookeeper里注册监听，这个我不在多说，做完这一切，回到调用处构建一个新的export对象进行返回，该对象中执行刚才导出的exporter中的逻辑，就此服务发布过程结束。

```java
try {
      if (Constants.ANY_VALUE.equals(url.getServiceInterface())) {
          String root = toRootPath();
          ConcurrentMap<NotifyListener, ChildListener> listeners = zkListeners.get(url);
          if (listeners == null) {
              zkListeners.putIfAbsent(url, new ConcurrentHashMap<NotifyListener, ChildListener>());
              listeners = zkListeners.get(url);
          }
          ChildListener zkListener = listeners.get(listener);
          if (zkListener == null) {
              listeners.putIfAbsent(listener, new ChildListener() {
                  public void childChanged(String parentPath, List<String> currentChilds) {
                      for (String child : currentChilds) {
      child = URL.decode(child);
                          if (! anyServices.contains(child)) {
                              anyServices.add(child);
                              subscribe(url.setPath(child).addParameters(Constants.INTERFACE_KEY, child, 
                                      Constants.CHECK_KEY, String.valueOf(false)), listener);
                          }
                      }
                  }
              });
              zkListener = listeners.get(listener);
          }
          zkClient.create(root, false);
          List<String> services = zkClient.addChildListener(root, zkListener);
          if (services != null && services.size() > 0) {
              for (String service : services) {
service = URL.decode(service);
anyServices.add(service);
                  subscribe(url.setPath(service).addParameters(Constants.INTERFACE_KEY, service, 
                          Constants.CHECK_KEY, String.valueOf(false)), listener);
              }
          }
      } else {
          List<URL> urls = new ArrayList<URL>();
          for (String path : toCategoriesPath(url)) {
              ConcurrentMap<NotifyListener, ChildListener> listeners = zkListeners.get(url);
              if (listeners == null) {
                  zkListeners.putIfAbsent(url, new ConcurrentHashMap<NotifyListener, ChildListener>());
                  listeners = zkListeners.get(url);
              }
              ChildListener zkListener = listeners.get(listener);
              if (zkListener == null) {
                  listeners.putIfAbsent(listener, new ChildListener() {
                      public void childChanged(String parentPath, List<String> currentChilds) {
                       ZookeeperRegistry.this.notify(url, listener, toUrlsWithEmpty(url, parentPath, currentChilds));
                      }
                  });
                  zkListener = listeners.get(listener);
              }
              zkClient.create(path, false);
              List<String> children = zkClient.addChildListener(path, zkListener);
              if (children != null) {
               urls.addAll(toUrlsWithEmpty(url, path, children));
              }
          }
          notify(url, listener, urls);
      }
  } catch (Throwable e) {
      throw new RpcException("Failed to subscribe " + url + " to zookeeper " + getUrl() + ", cause: " + e.getMessage(), e);
  }
```



### 客户端订阅服务



客户端的入口是ReferenceBean，它同样实现了多个spring的接口FactoryBean, ApplicationContextAware, InitializingBean, DisposableBean。

还是看 InitializingBean 接口的afterPropertiesSet方法，这个作为一个入口类方法，在其中对基础数据进行初始化，然后依次调用getObject方法、get方法、init方法、createProxy方法 后两个方法都 refreshenceConfig)，在，createProxy方法中创建具体的代理，我们从这句开始分析吧

先是判断是否jvm方式，如果在设置了url的情况下不做本地引用了，这里的url是null，然后判断isInjvm=false

继续走流程执行loadRegistries方法，这个是获取所有registery的配置，在我们的配置中是是设置了一个register协议,继续走，因为只只配了一个所有会走invoker = refprotocol.refer(interfaceClass, urls.get(0));这个流程这个就是直接返回了refer后的invoke，如果配置了多个注册中心，那么就会走下面的逻辑，首先构建一个invokers的列表对象，将所有的注册中心地址都执行refprotocol.refer(interfaceClass, url)，然后相应的invoke对象保存到invokers列表中，这时候用registryURL保存了最后一个url地址，如果是注册的url，则针对注册中心进行负载，如果没有，则使用默认的进行负载获取最终的invoke对象，之后对这个invoke对象进行创建代理然后返回。下面针对refprotocol.refer(interfaceClass, url)进行分析，这时候refprotocol=processfilter(processListener(registeryProtocol))这样的结构，和服务端发布是一样的，只不过执行的方法不同，下面直接分析registeryProtocol的refer方法

```java
URL tmpUrl = new URL("temp", "localhost", 0, map);
final boolean isJvmRefer;
      if (isInjvm() == null) {
          if (url != null && url.length() > 0) { //指定URL的情况下，不做本地引用
              isJvmRefer = false;
          } else if (InjvmProtocol.getInjvmProtocol().isInjvmRefer(tmpUrl)) {
              //默认情况下如果本地有服务暴露，则引用本地服务.
              isJvmRefer = true;
          } else {
              isJvmRefer = false;
          }
      } else {
          isJvmRefer = isInjvm().booleanValue();
      }

if (isJvmRefer) {
   URL url = new URL(Constants.LOCAL_PROTOCOL, NetUtils.LOCALHOST, 0, interfaceClass.getName()).addParameters(map);
   invoker = refprotocol.refer(interfaceClass, url);
          if (logger.isInfoEnabled()) {
              logger.info("Using injvm service " + interfaceClass.getName());
          }
} else {
          if (url != null && url.length() > 0) { // 用户指定URL，指定的URL可能是对点对直连地址，也可能是注册中心URL
              String[] us = Constants.SEMICOLON_SPLIT_PATTERN.split(url);
              if (us != null && us.length > 0) {
                  for (String u : us) {
                      URL url = URL.valueOf(u);
                      if (url.getPath() == null || url.getPath().length() == 0) {
                          url = url.setPath(interfaceName);
                      }
                      if (Constants.REGISTRY_PROTOCOL.equals(url.getProtocol())) {
                          urls.add(url.addParameterAndEncoded(Constants.REFER_KEY, StringUtils.toQueryString(map)));
                      } else {
                          urls.add(ClusterUtils.mergeUrl(url, map));
                      }
                  }
              }
          } else { // 通过注册中心配置拼装URL
           List<URL> us = loadRegistries(false);
           if (us != null && us.size() > 0) {
               for (URL u : us) {
                   URL monitorUrl = loadMonitor(u);
                      if (monitorUrl != null) {
                          map.put(Constants.MONITOR_KEY, URL.encode(monitorUrl.toFullString()));
                      }
                   urls.add(u.addParameterAndEncoded(Constants.REFER_KEY, StringUtils.toQueryString(map)));
                  }
           }
           if (urls == null || urls.size() == 0) {
                  throw new IllegalStateException("No such any registry to reference " + interfaceName  + " on the consumer " + NetUtils.getLocalHost() + " use dubbo version " + Version.getVersion() + ", please config <dubbo:registry address=\"...\" /> to your spring config.");
              }
          }

          if (urls.size() == 1) {
              invoker = refprotocol.refer(interfaceClass, urls.get(0));
          } else {
              List<Invoker<?>> invokers = new ArrayList<Invoker<?>>();
              URL registryURL = null;
              for (URL url : urls) {
                  invokers.add(refprotocol.refer(interfaceClass, url));
                  if (Constants.REGISTRY_PROTOCOL.equals(url.getProtocol())) {
                      registryURL = url; // 用了最后一个registry url
                  }
              }
              if (registryURL != null) { // 有 注册中心协议的URL
                  // 对有注册中心的Cluster 只用 AvailableCluster
                  URL u = registryURL.addParameter(Constants.CLUSTER_KEY, AvailableCluster.NAME); 
                  invoker = cluster.join(new StaticDirectory(u, invokers));
              }  else { // 不是 注册中心的URL
                  invoker = cluster.join(new StaticDirectory(invokers));
              }
          }
      }

      Boolean c = check;
      if (c == null && consumer != null) {
          c = consumer.isCheck();
      }
      if (c == null) {
          c = true; // default true
      }
      if (c && ! invoker.isAvailable()) {
          throw new IllegalStateException("Failed to check the status of the service " + interfaceName + ". No provider available for the service " + (group == null ? "" : group + "/") + interfaceName + (version == null ? "" : ":" + version) + " from the url " + invoker.getUrl() + " to the consumer " + NetUtils.getLocalHost() + " use dubbo version " + Version.getVersion());
      }
      if (logger.isInfoEnabled()) {
          logger.info("Refer dubbo service " + interfaceClass.getName() + " from url " + invoker.getUrl());
      }
      // 创建服务代理
      return (T) proxyFactory.getProxy(invoker)
```

registeryProtocol >>refer方法，第一句是重新设置了协议，这个是获取registery中的配置的协议，这里是zookeeper；接着往下走 这时候通过SPI机制获取的registery=ZookeeperRegistryFactory，我们继续跟进getRegistry方法，这时候调用的是其父类的getRegistry方法，这个要注意，领域涉及的思想，继续分析getRegistry方法

```java
url = url.setProtocol(url.getParameter(Constants.REGISTRY_KEY, Constants.DEFAULT_REGISTRY)).removeParameter(Constants.REGISTRY_KEY);
Registry registry = registryFactory.getRegistry(url);
if (RegistryService.class.equals(type)) {
   return proxyFactory.getInvoker((T) registry, type, url);
}

// group="a,b" or group="*"
Map<String, String> qs = StringUtils.parseQueryString(url.getParameterAndDecoded(Constants.REFER_KEY));
String group = qs.get(Constants.GROUP_KEY);
if (group != null && group.length() > 0 ) {
    if ( ( Constants.COMMA_SPLIT_PATTERN.split( group ) ).length > 1
            || "*".equals( group ) ) {
        return doRefer( getMergeableCluster(), registry, type, url );
    }
}
return doRefer(cluster, registry, type, url);
```



AbstractRegistryFactory>>getRegistry方法；这里是通过加锁的方法创建一个单例的注册配置，继续跟进createRegistry

```java
url = url.setPath(RegistryService.class.getName())
      .addParameter(Constants.INTERFACE_KEY, RegistryService.class.getName())
      .removeParameters(Constants.EXPORT_KEY, Constants.REFER_KEY);
String key = url.toServiceString();
   // 锁定注册中心获取过程，保证注册中心单一实例
   LOCK.lock();
   try {
       Registry registry = REGISTRIES.get(key);
       if (registry != null) {
           return registry;
       }
       registry = createRegistry(url);
       if (registry == null) {
           throw new IllegalStateException("Can not create registry " + url);
       }
       REGISTRIES.put(key, registry);
       return registry;
   } finally {
       // 释放锁
       LOCK.unlock();
   }
```

ZookeeperRegistryFactory>> createRegistry方法，这里是构建了一个新的zookeeper的注册中心，

```java
return new ZookeeperRegistry(url, zookeeperTransporter);
```

ZookeeperRegistry>>构造方法，在这里我们看到了是创建了zkClient的客户端，并且建立了连接，返回注册中心对象

```java
 super(url);
   if (url.isAnyHost()) {
   throw new IllegalStateException("registry address == null");
}
   String group = url.getParameter(Constants.GROUP_KEY, DEFAULT_ROOT);
   if (! group.startsWith(Constants.PATH_SEPARATOR)) {
       group = Constants.PATH_SEPARATOR + group;
   }
   this.root = group;
   zkClient = zookeeperTransporter.connect(url);
   zkClient.addStateListener(new StateListener() {
       public void stateChanged(int state) {
           if (state == RECONNECTED) {
           try {
   recover();
} catch (Exception e) {
   logger.error(e.getMessage(), e);
}
           }
       }
   });
```

这时候继续从RegisteryProtocol>>refer方法里 已经获取了registery 就是上面的 都是这一句话执行的流程Registry registry = registryFactory.getRegistry(url); 继续继续往下走，下面的两个class类型判断肯定不相等，不是一种类型的，然后继续走，这时候配置文件中没有设置group属性，所以也不会进入下面的逻辑判断中去，最后执行的是doRefer(cluster, registry, type, url),那么继续跟进

```java
url = url.setProtocol(url.getParameter(Constants.REGISTRY_KEY, Constants.DEFAULT_REGISTRY)).removeParameter(Constants.REGISTRY_KEY);
Registry registry = registryFactory.getRegistry(url);
if (RegistryService.class.equals(type)) {
   return proxyFactory.getInvoker((T) registry, type, url);
}

// group="a,b" or group="*"
Map<String, String> qs = StringUtils.parseQueryString(url.getParameterAndDecoded(Constants.REFER_KEY));
String group = qs.get(Constants.GROUP_KEY);
if (group != null && group.length() > 0 ) {
    if ( ( Constants.COMMA_SPLIT_PATTERN.split( group ) ).length > 1
            || "*".equals( group ) ) {
        return doRefer( getMergeableCluster(), registry, type, url );
    }
}
return doRefer(cluster, registry, type, url);
```

RegisteryProtocol>>doRefer方法，这个方法的信息量大，首先构建了一个注册目录对象

```java
RegistryDirectory<T> directory = new RegistryDirectory<T>(type, url);
directory.setRegistry(registry);
directory.setProtocol(protocol);
URL subscribeUrl = new URL(Constants.CONSUMER_PROTOCOL, NetUtils.getLocalHost(), 0, type.getName(), directory.getUrl().getParameters());
if (! Constants.ANY_VALUE.equals(url.getServiceInterface())
        && url.getParameter(Constants.REGISTER_KEY, true)) {
    registry.register(subscribeUrl.addParameters(Constants.CATEGORY_KEY, Constants.CONSUMERS_CATEGORY,
            Constants.CHECK_KEY, String.valueOf(false)));
}
directory.subscribe(subscribeUrl.addParameter(Constants.CATEGORY_KEY, 
        Constants.PROVIDERS_CATEGORY 
        + "," + Constants.CONFIGURATORS_CATEGORY 
        + "," + Constants.ROUTERS_CATEGORY));
return cluster.join(directory);
```

























































































































































































































































































































































































































































































































































































































