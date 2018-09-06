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

通过解析

1. Protocol protocol = ExtensionLoader. getExtensionLoader(Protocol.class). getExtension("myProtocol");

2. Protocol protocol = ExtensionLoader.getExtensionLoader(Protocol.class). getAdaptiveExtension();

   首先针对第二个进行源码分析，看一下它是如何获取一个动态扩展点的实例的



