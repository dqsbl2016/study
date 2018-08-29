# JAVA SPI

SPI全称（service provider interface），是JDK内置的一种服务提供发现机制，目前市面上有很多框架都是用它来做服务的扩展发现，大家耳熟能详的如JDBC、日志框架都有用到；

简单来说，它是一种动态替换发现的机制。举个简单的例子，如果我们定义了一个规范，需要第三方厂商去实现，那么对于我们应用方来说，只需要集成对应厂商的插件，既可以完成对应规范的实现机制。 形成一种插拔式的扩展手段。

## 使用

* 需要在classpath下创建一个目录，该目录命名必须是：META-INF/services 

* 在该目录下创建一个properties文件，该文件需要满足以下几个条件

  a)  文件名必须是扩展的接口的全路径名称

  b)  文件内部描述的是该扩展接口的所有实现类

  c)  文件的编码格式是UTF-8

* 通过java.util.ServiceLoader的加载机制来发现 

## 缺点

* JDK标准的SPI会一次性加载实例化扩展点的所有实现，什么意思呢？就是如果你在META-INF/service下的文件里面加了N个实现类，那么JDK启动的时候都会一次性全部加载。那么如果有的扩展点实现初始化很耗时或者如果有些实现类并没有用到，那么会很浪费资源
* 如果扩展点加载失败，会导致调用方报错，而且这个错误很难定位到是这个原因

# Dubbo SPI 扩展

## 使用

*  需要在resource目录下配置META-INF/dubbo或者META-INF/dubbo/internal或者META-INF/services，并基于SPI接口去创建一个文件
* 文件名称和接口名称保持一致，文件内容和SPI有差异，内容是KEY对应Value

## 源码结构

![image](https://github.com/dqsbl2016/study/blob/master/分布式相关/xy/img/structure.jpg)

## 源码分析

参考例子 看Protocol的源码。

```java
@SPI("dubbo")
public interface Protocol {
    
    /**
     * 获取缺省端口，当用户没有配置端口时使用。
     * 
     * @return 缺省端口
     */
    int getDefaultPort();

    /**
     * 暴露远程服务：<br>
     * 1. 协议在接收请求时，应记录请求来源方地址信息：RpcContext.getContext().setRemoteAddress();<br>
     * 2. export()必须是幂等的，也就是暴露同一个URL的Invoker两次，和暴露一次没有区别。<br>
     * 3. export()传入的Invoker由框架实现并传入，协议不需要关心。<br>
     * 
     * @param <T> 服务的类型
     * @param invoker 服务的执行体
     * @return exporter 暴露服务的引用，用于取消暴露
     * @throws RpcException 当暴露服务出错时抛出，比如端口已占用
     */
    @Adaptive
    <T> Exporter<T> export(Invoker<T> invoker) throws RpcException;

    /**
     * 引用远程服务：<br>
     * 1. 当用户调用refer()所返回的Invoker对象的invoke()方法时，协议需相应执行同URL远端export()传入的Invoker对象的invoke()方法。<br>
     * 2. refer()返回的Invoker由协议实现，协议通常需要在此Invoker中发送远程请求。<br>
     * 3. 当url中有设置check=false时，连接失败不能抛出异常，并内部自动恢复。<br>
     * 
     * @param <T> 服务的类型
     * @param type 服务的类型
     * @param url 远程服务的URL地址
     * @return invoker 服务的本地代理
     * @throws RpcException 当连接服务提供方失败时抛出
     */
    @Adaptive
    <T> Invoker<T> refer(Class<T> type, URL url) throws RpcException;

    /**
     * 释放协议：<br>
     * 1. 取消该协议所有已经暴露和引用的服务。<br>
     * 2. 释放协议所占用的所有资源，比如连接和端口。<br>
     * 3. 协议在释放后，依然能暴露和引用新的服务。<br>
     */
    void destroy();

}
```

@SPI 表示当前这个接口是一个扩展点，可以实现自己的扩展实现，默认的扩展点是看properties配置中对应key值的value内容，也就是DubboProtocol。

@Adaptive  表示一个自适应扩展点，在方法级别上，会动态生成一个适配器类 ，在类级别上，会返回这个自定义适配器类。

### 第一种入口

在正常发布服务时，通过ServiceConfig进入，可以看到定义的一个属性。当然不止这一个地方，dubbo很多地方都用到了SPI机制。

```java
 private static final Protocol protocol = 
     ExtensionLoader.getExtensionLoader(Protocol.class).getAdaptiveExtension(); 
```

这个就是通过SPI机制，来获取到具体的Protocol实现类。

首先分析`ExtensionLoader. getExtensionLoader(Protocol.class)`;

```java
 @SuppressWarnings("unchecked")
    public static <T> ExtensionLoader<T> getExtensionLoader(Class<T> type) {
        if (type == null)
            throw new IllegalArgumentException("Extension type == null");
        if(!type.isInterface()) {
            throw new IllegalArgumentException("Extension type(" + type + ") is not interface!");
        }
        if(!withExtensionAnnotation(type)) {
            throw new IllegalArgumentException("Extension type(" + type + 
                    ") is not extension, because WITHOUT @" + SPI.class.getSimpleName() + " Annotation!");
        }
        
        ExtensionLoader<T> loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
        if (loader == null) {
            EXTENSION_LOADERS.putIfAbsent(type, new ExtensionLoader<T>(type));
            loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
        }
        return loader;
    }
```

首先会做验证处理，传过来的参数class不能为空，必须是接口，必须有SPI注解。

然后从集合中获取它的ExtensionLoader，这里第一次调用时集合是空的，所以会进入空的处理逻辑。

直接新实例化一个ExtensionLoader对象，然后put进集合中。然后返回ExtensionLoader对象。

那么实例化ExtensionLoader对象会做什么呢？进入方法看一下。

```java
   private ExtensionLoader(Class<?> type) {//Protocol.class
        this.type = type;
        objectFactory = (type == ExtensionFactory.class ? null :
                ExtensionLoader.getExtensionLoader(ExtensionFactory.class).
                        getAdaptiveExtension());
    }
```

首先记录接口内容，然后获取一个ExtensionFactory对象记录。（这里又会执行SPI机制）

获取到了`ExtensionLoader`后，继续会调用`getAdaptiveExtension`方法。

```java
public T getAdaptiveExtension() {
        Object instance = cachedAdaptiveInstance.get();
        if (instance == null) {
            if(createAdaptiveInstanceError == null) {
                synchronized (cachedAdaptiveInstance) {
                    instance = cachedAdaptiveInstance.get();
                    if (instance == null) {
                        try {
                            instance = createAdaptiveExtension();
                            cachedAdaptiveInstance.set(instance);
                        } catch (Throwable t) {
                            createAdaptiveInstanceError = t;
                            throw new IllegalStateException("fail to create adaptive instance: " + t.toString(), t);
                        }
                    }
                }
            }
            else {
                throw new IllegalStateException("fail to create adaptive instance: " + createAdaptiveInstanceError.toString(), createAdaptiveInstanceError);
            }
        }

        return (T) instance;
    }
```

首先依然是从缓存`cachedAdaptiveInstance`中获取`AdaptiveExtension`，第一次为空会进入空的逻辑，这里因为线程安全问题，所以用了双重检查锁机制，然后调用`createAdaptiveExtension`创建`AdaptiveExtension`.然后将创建好的`AdaptiveExtension`放入缓存中。

```java
private T createAdaptiveExtension() {
        try {
            //可以实现扩展点的注入
            return injectExtension((T) getAdaptiveExtensionClass().newInstance());
        } catch (Exception e) {
            throw new IllegalStateException("Can not create adaptive extenstion " + type + ", cause: " + e.getMessage(), e);
        }
    }
```

这里包含了多步操作，首先执行getAdaptiveExtensionClass方法获取返回

```java
private Class<?> getAdaptiveExtensionClass() {
        getExtensionClasses();
        //TODO  不一定？
        if (cachedAdaptiveClass != null) {
            return cachedAdaptiveClass; //AdaptiveCompiler
        }
        return cachedAdaptiveClass = createAdaptiveExtensionClass();
    }
```

会调用getExtensionClasses方法，这个就是获取所有配置的实现方法。

```java
//加载扩展点的实现类
	private Map<String, Class<?>> getExtensionClasses() {

        Map<String, Class<?>> classes = cachedClasses.get();
        if (classes == null) {
            synchronized (cachedClasses) {
                classes = cachedClasses.get();
                if (classes == null) {
                    classes = loadExtensionClasses();
                    cachedClasses.set(classes);
                }
            }
        }
        return classes;
	}
```

依然是先从缓存取，然后加同步关键字，使用双重检查锁。然后调用loadExtensionClasses获取

```java
 // 此方法已经getExtensionClasses方法同步过。
    private Map<String, Class<?>> loadExtensionClasses() {
        //type->Protocol.class
        //得到SPI的注解
        final SPI defaultAnnotation = type.getAnnotation(SPI.class);
        if(defaultAnnotation != null) { //如果不等于空.
            String value = defaultAnnotation.value();
            if(value != null && (value = value.trim()).length() > 0) {
                String[] names = NAME_SEPARATOR.split(value);
                if(names.length > 1) {
                    throw new IllegalStateException("more than 1 default extension name on extension " + type.getName()
                            + ": " + Arrays.toString(names));
                }
                if(names.length == 1) cachedDefaultName = names[0];
            }
        }
        
        Map<String, Class<?>> extensionClasses = new HashMap<String, Class<?>>();
        loadFile(extensionClasses, DUBBO_INTERNAL_DIRECTORY);
        loadFile(extensionClasses, DUBBO_DIRECTORY);
        loadFile(extensionClasses, SERVICES_DIRECTORY);
        return extensionClasses;
    }
```

首先会获取当前接口的SPI注解内容，如果不为空，获取value值，然后或进行解析验证，如果配置多个会报错，所以不允许配置多个，然后记录下配置的value值。

然后执行读取文件，这里面就是dubbo的定义会从哪些位置读取文件。

* META-INF/dubbo/internal/
* META-INF/dubbo/
* META-INF/services/

继续进入loadFile方法，看一下实现

```java
 private void loadFile(Map<String, Class<?>> extensionClasses, String dir) {
        String fileName = dir + type.getName();
        try {
            Enumeration<java.net.URL> urls;
            ClassLoader classLoader = findClassLoader();
            if (classLoader != null) {
                urls = classLoader.getResources(fileName);
            } else {
                urls = ClassLoader.getSystemResources(fileName);
            }
            if (urls != null) {
                while (urls.hasMoreElements()) {
                    java.net.URL url = urls.nextElement();
                    try {
                        BufferedReader reader = new BufferedReader(new InputStreamReader(url.openStream(), "utf-8"));
                        try {
                            String line = null;
                            while ((line = reader.readLine()) != null) {
                                final int ci = line.indexOf('#');
                                if (ci >= 0) line = line.substring(0, ci);
                                line = line.trim();
                                if (line.length() > 0) {
                                    try {
                                        String name = null;
                                        int i = line.indexOf('=');
                                        if (i > 0) {//文件采用name=value方式，通过i进行分割
                                            name = line.substring(0, i).trim();
                                            line = line.substring(i + 1).trim();
                                        }
                                        if (line.length() > 0) {
                                            Class<?> clazz = Class.forName(line, true, classLoader);
                                            //加载对应的实现类，并且判断实现类必须是当前的加载的扩展点的实现
                                            if (! type.isAssignableFrom(clazz)) {
                                                throw new IllegalStateException("Error when load extension class(interface: " +
                                                        type + ", class line: " + clazz.getName() + "), class " 
                                                        + clazz.getName() + "is not subtype of interface.");
                                            }

                                            //判断是否有自定义适配类，如果有，则在前面讲过的获取适配类的时候，直接返回当前的自定义适配类，不需要再动态创建
                                            if (clazz.isAnnotationPresent(Adaptive.class)) {
                                                if(cachedAdaptiveClass == null) {
                                                    cachedAdaptiveClass = clazz;
                                                } else if (! cachedAdaptiveClass.equals(clazz)) {
                                                    throw new IllegalStateException("More than 1 adaptive class found: "
                                                            + cachedAdaptiveClass.getClass().getName()
                                                            + ", " + clazz.getClass().getName());
                                                }
                                            } else {
                                                try {
                                                    //如果没有Adaptive注解，则判断当前类是否带有参数是type类型的构造函数，如果有，则认为是
                                                    //wrapper类。这个wrapper实际上就是对扩展类进行装饰.
                                                    //可以在dubbo-rpc-api/internal下找到Protocol文件，发现Protocol配置了3个装饰
                                                    //分别是,filter/listener/mock. 所以Protocol这个实例来说，会增加对应的装饰器
                                                    clazz.getConstructor(type);//
                                                    //得到带有public DubboProtocol(Protocol protocol)的扩展点。进行包装
                                                    Set<Class<?>> wrappers = cachedWrapperClasses;
                                                    if (wrappers == null) {
                                                        cachedWrapperClasses = new ConcurrentHashSet<Class<?>>();
                                                        wrappers = cachedWrapperClasses;
                                                    }
                                                    wrappers.add(clazz);//包装类 ProtocolFilterWrapper(ProtocolListenerWrapper(Protocol))
                                                } catch (NoSuchMethodException e) {
                                                    clazz.getConstructor();
                                                    if (name == null || name.length() == 0) {
                                                        name = findAnnotationName(clazz);
                                                        if (name == null || name.length() == 0) {
                                                            if (clazz.getSimpleName().length() > type.getSimpleName().length()
                                                                    && clazz.getSimpleName().endsWith(type.getSimpleName())) {
                                                                name = clazz.getSimpleName().substring(0, clazz.getSimpleName().length() - type.getSimpleName().length()).toLowerCase();
                                                            } else {
                                                                throw new IllegalStateException("No such extension name for the class " + clazz.getName() + " in the config " + url);
                                                            }
                                                        }
                                                    }
                                                    String[] names = NAME_SEPARATOR.split(name);
                                                    if (names != null && names.length > 0) {
                                                        Activate activate = clazz.getAnnotation(Activate.class);
                                                        if (activate != null) {
                                                            cachedActivates.put(names[0], activate);
                                                        }
                                                        for (String n : names) {
                                                            if (! cachedNames.containsKey(clazz)) {
                                                                cachedNames.put(clazz, n);
                                                            }
                                                            Class<?> c = extensionClasses.get(n);
                                                            if (c == null) {
                                                                extensionClasses.put(n, clazz);
                                                            } else if (c != clazz) {
                                                                throw new IllegalStateException("Duplicate extension " + type.getName() + " name " + n + " on " + c.getName() + " and " + clazz.getName());
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } catch (Throwable t) {
                                        IllegalStateException e = new IllegalStateException("Failed to load extension class(interface: " + type + ", class line: " + line + ") in " + url + ", cause: " + t.getMessage(), t);
                                        exceptions.put(line, e);
                                    }
                                }
                            } // end of while read lines
                        } finally {
                            reader.close();
                        }
                    } catch (Throwable t) {
                        logger.error("Exception when load extension class(interface: " +
                                            type + ", class file: " + url + ") in " + url, t);
                    }
                } // end of while urls
            }
        } catch (Throwable t) {
            logger.error("Exception when load extension class(interface: " +
                    type + ", description file: " + fileName + ").", t);
        }
    }
```

这里面代码比较长，做了很多处理。

主要就是读取porperties文件，遍历配置的所有信息，如果是key-value方式配置进行分割处理。

然后对实现类通过反射获取，做一步验证是否是对应扩展接口的实现类。

然后判断这个类是否定义了Adaptive注解，如果设置了这个注解直接把这个类放入到cachedAdaptiveClass缓存中（这个值后面会有应用）。其实这个就是默认适配这个类。

如果类没有Adaptive注解，判断当前类是否带有参数是type类型的构造函数，如果有，则认为是//wrapper类。这个wrapper实际上就是对扩展类进行装饰。然后将这个wrapper类放入集合中。

继续回到上面方法，

```java
private Class<?> getAdaptiveExtensionClass() {
        getExtensionClasses();
        //TODO  不一定？
        if (cachedAdaptiveClass != null) {
            return cachedAdaptiveClass; //AdaptiveCompiler
        }
        return cachedAdaptiveClass = createAdaptiveExtensionClass();
    }
```

会判断cachedAdaptiveClass是否有值，这个就是刚才提到的，如果是类中有Adaptive注解，那么cachedAdaptiveClass的值就是这个实现类，会直接将这个类返回。

继续看另外的分支会进入createAdaptiveExtensionClass方法

```java
 //创建一个适配器扩展点。（创建一个动态的字节码文件）
    private Class<?> createAdaptiveExtensionClass() {
        //生成字节码代码
        String code = createAdaptiveExtensionClassCode();
        //获得类加载器
        ClassLoader classLoader = findClassLoader();
        com.alibaba.dubbo.common.compiler.Compiler compiler = ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.common.compiler.Compiler.class).getAdaptiveExtension();
        //动态编译字节码
        return compiler.compile(code, classLoader);
    }
```

这里首先调用createAdaptiveExtensionClassCode获取字节码文件，可以看里面具体实现。但是实际上这些是固定写好的字节码。

然后依然通过SPI机制获取到compiler的实现然后动态编译。然后将编译后的class返回。其实就是生成一个动态适配器类。 例如Protocol&Adaptive。

继续回到上面的方法，

```java
  private T createAdaptiveExtension() {
        try {
            //可以实现扩展点的注入
            return injectExtension((T) getAdaptiveExtensionClass().newInstance());
        } catch (Exception e) {
            throw new IllegalStateException("Can not create adaptive extenstion " + type + ", cause: " + e.getMessage(), e);
        }
    }
```

这里还会调用injectExtension方法，具体进入看看做了什么

```java
private T injectExtension(T instance) {
        try {
            if (objectFactory != null) {
                for (Method method : instance.getClass().getMethods()) {
                    if (method.getName().startsWith("set")
                            && method.getParameterTypes().length == 1
                            && Modifier.isPublic(method.getModifiers())) {
                        Class<?> pt = method.getParameterTypes()[0];
                        try {
                            String property = method.getName().length() > 3 ? method.getName().substring(3, 4).toLowerCase() + method.getName().substring(4) : "";
                            Object object = objectFactory.getExtension(pt, property);
                            if (object != null) {
                                method.invoke(instance, object);
                            }
                        } catch (Exception e) {
                            logger.error("fail to inject via method " + method.getName()
                                    + " of interface " + type.getName() + ": " + e.getMessage(), e);
                        }
                    }
                }
            }
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        }
        return instance;
    }
```

看到这里就明白了，这个方法会传入适配的类，然后判断是否存在set开头的方法，参数数量为1个，还是public修饰的，如果存在则会做一个依赖注入操作。



### 总结：

到这里，整个分析差不多了。

实例上就是分为

* 如果实现类中用了@Adaptive注解，则直接返回这个类。
* 如果实现类中存在构造函数，并且参数为扩展点的接口，则这个认为是个warpper类，加入到warpper集合。（组装链路调用在哪未找到）
* 如果类中没有使用@Adaptive注解，则会生成动态吗来生成一个class类，就是这个Protocol&Adaptive动态适配器。
* 最后会判断实现类是否有set方法，如果有则会做个依赖注入操作。

### 第二种入口

获取指定的实现类

```java
ExtensionLoader.getExtensionLoader(Protocol.class).getExtension("DubboProtocol");
```

这种是直接获取指定的实现类。

```java
public T getExtension(String name) {
		if (name == null || name.length() == 0)
		    throw new IllegalArgumentException("Extension name == null");
		if ("true".equals(name)) {
		    return getDefaultExtension();
		}
		Holder<Object> holder = cachedInstances.get(name);
		if (holder == null) {
		    cachedInstances.putIfAbsent(name, new Holder<Object>());
		    holder = cachedInstances.get(name);
		}
		Object instance = holder.get();
		if (instance == null) {
		    synchronized (holder) {
	            instance = holder.get();
	            if (instance == null) {
	                instance = createExtension(name);
	                holder.set(instance);
	            }
	        }
		}
		return (T) instance;
	}
```

首先验证参数的有效性，依然是先从缓存中获取，如果没有最终会调用createExtension

```java
private T createExtension(String name) {
        Class<?> clazz = getExtensionClasses().get(name);//"dubbo"  clazz=DubboProtocol
        if (clazz == null) {
            throw findException(name);
        }
        try {
            T instance = (T) EXTENSION_INSTANCES.get(clazz);
            if (instance == null) {
                EXTENSION_INSTANCES.putIfAbsent(clazz, (T) clazz.newInstance());
                instance = (T) EXTENSION_INSTANCES.get(clazz);
            }
            injectExtension(instance);
            Set<Class<?>> wrapperClasses = cachedWrapperClasses;
            if (wrapperClasses != null && wrapperClasses.size() > 0) {
                for (Class<?> wrapperClass : wrapperClasses) {
                    instance = injectExtension((T) wrapperClass.getConstructor(type).newInstance(instance));
                }
            }
            return instance;
        } catch (Throwable t) {
            throw new IllegalStateException("Extension instance(name: " + name + ", class: " +
                    type + ")  could not be instantiated: " + t.getMessage(), t);
        }
    }
```

这里就是获取到具体的实现类，然后获取之前的wrapperClasses集合，然后遍历进行链路调用，同时还会通过injectExtension方法，检查是否需要依赖注入。