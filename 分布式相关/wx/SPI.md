#                            SPI

### 定义

spi(service provider interface)服务提供接口，它是通过约定一种接口实现的规约，来完成接口服务的扩展实现。

它是JDK内置的一种服务提供发现机制，目前市面上有很多框架都是用它来做服务的扩展发现，大家耳熟能详的如jdbc、日志框架都有用到，简单来说，它是一种动态替换发现的机制，举个例子，如果我们定义了一个规范，需要第三方厂商去实现，那么对于我们应用来说，只需要继承对应的厂商插件，既可以完成对应的实现机制。形成一种可插拔式的扩展手段

### JDK实现SPI

JDK使用ServiceLoader实现spi的核心功能，

实现原理为

1、从MEDA_INF/services 目录中获取所有的类的配置文件

2、文件名必须是类的全路径包含包名

3、文件中输入所有的实现类

4、文件的格式必须是utf-8

java实现的spi有如下缺点

（1）spi会加载所有的扩展点，不管是否用到，这种记载方式，造成加载不灵活，浪费资源失败，很难进行定位问题

（2）如果spi加载

### Dubbo实现SPI

dubbo修正了这样的缺点，并进行了改进，

dubbo实现中，大量使用了这种功能，所以想学习dubbo源码。必须学好spi，同时在dubbo的实现中也大量使用了缓存，就是内存缓存，在获取所有的对象之前都会先判断是否有相应的缓存，从这个方面可以看出，dubbo是基础单例模式实现的

#### 解析的两种方式

Protocol protocol = ExtensionLoader. getExtensionLoader(Protocol.class). getExtension("myProtocol");

Protocol protocol = ExtensionLoader.getExtensionLoader(Protocol.class). getAdaptiveExtension();

#### getAdaptiveExtension源码解析

首先针对第二个进行源码分析，看一下它是如何获取一个动态扩展点的实例的

测试以Protocol为例

 执行分为两个部分，首先是调用了 ExtensionLoader.getExtensionLoader(Protocol.class)，那我们先从这里出发，一步步揭开它的神秘面纱

getExtensionLoader解析

```java
//判断是否为空
if (type == null)
    throw new IllegalArgumentException("Extension type == null");
//判断该类型是否接口
if(!type.isInterface()) {
    throw new IllegalArgumentException("Extension type(" + type + ") is not interface!");
}
//判断是否有SPI扩展点的备注@SPI
if(!withExtensionAnnotation(type)) {
    throw new IllegalArgumentException("Extension type(" + type + 
            ") is not extension, because WITHOUT @" + SPI.class.getSimpleName() + " Annotation!");
}
//首先从缓存中查询是否已经有该类型的扩展器，如果有则取出
ExtensionLoader<T> loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
//如果没有 则新建一个扩展器
if (loader == null) {
    EXTENSION_LOADERS.putIfAbsent(type, new ExtensionLoader<T>(type));
    loader = (ExtensionLoader<T>) EXTENSION_LOADERS.get(type);
}
return loader;
```

继续看下 创建一个新的扩展器，它的构造方法里做了些什么

```java
//保存Protocol.class对象
this.type = type;
//构建一个objectFactory对象，字面意思就是一个对象工厂 
//它的定义是 private final ExtensionFactory objectFactory;
objectFactory = (type == ExtensionFactory.class ? null :
        ExtensionLoader.getExtensionLoader(ExtensionFactory.class).
                getAdaptiveExtension());
```

暂时在这里不进行展开，在讲完上面的Protocol扩展器之后，在回看此方法，应该就能看懂了



书接上文，讲到就此构建了扩展器对象，这时候ExtensionLoader. getExtensionLoader(Protocol.class)代表的就是ExtensionLoader的实例对象了。

那么接下来我们继续解析后面的内容getAdaptiveExtension()，它的意思是获取一个可适配的扩展点，它最终会获取一个符合条件自适应的扩展对象实例，它是怎么做到的呢，且看源码

```java
//不变的是它还是先从缓存中读取该实例
Object instance = cachedAdaptiveInstance.get();
//对象为空
if (instance == null) {
    //且没有创建适配对象的错误存在
    if(createAdaptiveInstanceError == null) {
        //采用了双重检查锁 去重新创建新的适配对象，这里是进行了同步操作
        synchronized (cachedAdaptiveInstance) {
            instance = cachedAdaptiveInstance.get();
            if (instance == null) {
                try {
                    //上面又对缓存做了判断，是否存在该对象，
                    //如果没有则走下面 新建流程
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
```

下面看下具体的创建过程 看方法createAdaptiveExtension

这里面一句话 做了很多的事情，通过嵌套方法调用，首先通过getAdaptiveExtensionClass()获取一个适配的class对象，接着对这个对象进行构建一个实例的操作，最后通过injectExtension方法，对该实例中所有set开头的方法进行依赖注入操作。

```java
//可以实现扩展点的注入
return injectExtension((T) getAdaptiveExtensionClass().newInstance());
```

那么继续往下挖吧  >>getAdaptiveExtensionClass，就是你了,不要躲闪，你已经发光了

```java
//获取一个扩展class对象
getExtensionClasses();
//TODO 判断是否缓存中存在该适配class对象，如果有则直接发回
if (cachedAdaptiveClass != null) {
    return cachedAdaptiveClass; //AdaptiveCompiler
}
//这里就是创建一个新的适配器对象了
return cachedAdaptiveClass = createAdaptiveExtensionClass();

```



都到这份上了 继续吧，迫不及待的想去征服它，，，嘎嘎getExtensionClasses 我来了

createAdaptiveExtensionClass

```java
//不出所料的 还是从缓存从获取
Map<String, Class<?>> classes = cachedClasses.get();
if (classes == null) {
    synchronized (cachedClasses) {
        classes = cachedClasses.get();
        if (classes == null) {
            //同样经历了双重检查锁之后，没有得到想要的结果，然后愤然自立更生，加载属于自己的扩展点，
            //该我表现的时刻终于来临了，come on
            classes = loadExtensionClasses();
            cachedClasses.set(classes);
        }
    }
}
return classes;
```



一条路走到黑，看它还有什么幺蛾子，loadExtensionClasses 来吧 让我在来看你一眼，好像某歌词，

蛾子来了，看来还是比较大啊，比较之前，代码已经增多不少，简单一看，发现了3个load操作，那么跟进吧

loadExtensionClasses

```
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
```

本来不想把源码都贴进来的，后来发现，如果以小片段来分解 会有种 只有点没有面的尴尬，还是把代码都整理进来，这样就不用针对源码在对一遍了，因为亲，你看的都是原封不动的源码啊，

里面写的非常亲民，发现好多都是我们日常中很常见的，我初看这个源码的时候，错愕了一阵，这就是源码么，怎么没有其它框架的特质呢（ps:看不懂，懵圈的感觉没有出现)，很是诧异，看来国产的还是走的爱国路线啊，必须赞一个,

代码的核心就是读取配置文件中所有的扩展点类，首先判断该扩展点类上是否有@Adaptive的注册，因为有这种注解的类，就是命中注定的不平凡呐，一注解注一生啊！它的伟大作用就是指定了它作为扩展器对象，无他，就此一个，其次就是判断该类中是否存在一个 clazz.getConstructor(type)这样的构造方法，如果存在则放入缓存，这个是wrapper类型的类，对具体的扩展对象 进行包装操作，之后进行一个扩展的功能处理，那么不是这两种呢，还是存到一个缓存中以备后用啊，在异常里我们看到了其他扩展点的身影，备胎的滋味，不好受啊，，，

走到这一步已经获取到需要的东东了，扩展点class已经确定了，或者有，或者需要创建动态可适配的，都有了定论

loadFile

```java
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
```

接下来回到初始的调用点getExtensionClasses方法我们已经走完流程了，那么继续往下走，查看缓存中是否存在适配点，如果没有则需要进行动态生成一个了，有的话不用说了 直接返回，如果没有则走该方法，进行动态生成一个适配class

createAdaptiveExtensionClass

```java
getExtensionClasses();
//TODO  不一定？
if (cachedAdaptiveClass != null) {
    return cachedAdaptiveClass; //AdaptiveCompiler
}
return cachedAdaptiveClass = createAdaptiveExtensionClass();
```

来来来，让我们看一下，通过下面的代码生成并且完成了扩展点class

createAdaptiveExtensionClass

```java
//生成字节码代码
String code = createAdaptiveExtensionClassCode();
//获得类加载器
ClassLoader classLoader = findClassLoader();
com.alibaba.dubbo.common.compiler.Compiler compiler = ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.common.compiler.Compiler.class).getAdaptiveExtension();
//动态编译字节码
return compiler.compile(code, classLoader);
```

createAdaptiveExtensionClassCode方法具体的创建过程就不贴代码了，并不影响对SPI的理解，到这一步就创建完成了一个适配点

PS 之前的objectFactory 我们现在可以讲一下了，通过上文你应该能够自己去试着理解了，它同样是创建了一个适配点对象，在配置文件中我们发现它的实现类AdaptiveExtensionFactory类上面有注解@Adaptive 于是乎，聪明的你应该能想到是怎么回事了，对，创建的就是这个对象，上面已经交代清楚了，如果还是不清楚，请回看，看仔细 看明白 ，

#### getExtension("myProtocol")源码解析

上面讲解的是获取动态的适配器扩展点，这个就是获取指定的扩展点，参数里面传递着具体的扩展点名称，好吧，我们开始吧

开始还是一通判断上面已经有讲解，不在重复了

getExtension("myProtocol")

```java
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
                 //关键点 创建指定的扩展点
               instance = createExtension(name);
               holder.set(instance);
           }
       }
}
return (T) instance;
```



这里面的的第一句看到了熟悉的方法的身影getExtensionClasses，它不就是上面讲的去加载扩展类的么，这里亦不在重复，接下来就是创建该类型的对象了，通过反射，都知道的云云，，，

然后还是有injectExtension依赖注入这一块，就是注入有set方法的，在往下有一个重点就是注入wrapper对象进行扩展点的包装，形成a>b>dubbo这种形式，最后把该扩展点对象进行返回，就完成了指定扩展点对象的获取

createExtension

```java
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
```