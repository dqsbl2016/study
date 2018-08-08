# Spring Interfaces and Class

## BeanFactory

Spring Bean容器的根接口。提供多种获取Bean方法接口。

* `ListableBeanFactory`

  继承`BeanFactory`接口，获取Bean的集合，一次获取全部Bean 而不是一个bean。

* `HierarchicalBeanFactory`

  继承`BeanFactory`接口， 提供上一级容器的访问功能。

  * `ConfigurableBeanFactory`

* `AutowireCapableBeanFactory`

  继承`BeanFactory`接口，实现对已存在实例的管理。

## Resource

* `ClassPathResource `  class  

  通过`ClassLoader` 获取资源

* `FileSystemResource ` class

  通过`file`获取资源

* `ServletContextResource` class 

  通过`ServletContext` 获取资源

* `UrlResource` class

  通过`url`或`uri` 获取资源



## ResourceLoader

提供 classpath下单资源文件的载入 （Classpath:）

- `ResourcePatternResolver`

  提供了多资源文件的载入 （Classpath*:）

  - `PathMatchingResourcePatternResolver` class

    通过与`ResourceLoader`关联关系，实例化的时候传入`ResourceLoader`具体实现，来对文件进行解析。

- `applicationContext` 

##  BeanDefinitionReader

加载、解析Bean内容。

- `XmlBeanDefinitionReader`  class

  针对XML文件加载、解析。

- `PropertiesBeanDefinitionReader` class

  针对Properties文件加载、解析。

- `GroovyBeanDefinitionReader` class

  

##  BeanDefinitionDocumentReader

- `DefaultBeanDefinitionDocumentReader`  class

  document结构的解析bean。

##  BeanDefinitionParserDelegate  class

对`<bean>`、各种集合类型等标签的解析处理。

## BeanMetadataElement

bean元数据元素

- `BeanDefinition` 

  存储bean详细信息。

  - `AnnotatedGenericBeanDefinition`  class

  - `RootBeanDefinition` class

    一版如果bean存在层级关系，父级用`RootBeanDefinition` 表示，否则就直接使用`RootBeanDefinition` 表示

  - `ChildBeanDefinition` class

    如果存在层级关系，子级的使用`ChildBeanDefinition` 表示

  - `GenericBeanDefinition`  class

    一站式服务类

- `BeanDefinitionHolder`

- `BeanDefinitionReaderUtils`

  提供的公共静态处理

## BeanDefinitionRegistry

针对`beandefinition`的管理

* `DefaultListableBeanFactory`

  

* `GenericApplicationContext`

  













AbstractApplicationContext

`ApplicationContext`接口的抽象实现，没有强制规定配置的存储类型，仅仅实现通用的上下文。主要用到模板方法设计模式，具体实现由子类进行。自动通过`registerBeanPostProcessors()`方法注册`BeanFactoryPostProcessor`, `BeanPostProcessor`和`ApplicationListener`的实例用来探测bean factory里的特殊bean 。

BeanDefinitionRegistry

用于持有像`RootBeanDefinition`和 `ChildBeanDefinition`实例的`bean definitions`的注册表接口。`DefaultListableBeanFactory`实现了这个接口，因此可以通过相应的方法向`beanFactory`里面注册bean。`GenericApplicationContext`内置一个`DefaultListableBeanFactory`实例，它对这个接口的实现实际上是通过调用这个实例的相应方法实现的。 

GenericApplicationContext

通用应用上下文，内部持有一个`DefaultListableBeanFactory`实例，这个类实现了`BeanDefinitionRegistry`接口，可以在它身上使用任意的bean definition读取器。典型的使用案例是：通过`BeanFactoryRegistry`接口注册bean definitions，然后调用`refresh()`方法来初始化那些带有应用上下文语义（`org.springframework.context.ApplicationContextAware`）的bean，自动探测`org.springframework.beans.factory.config.BeanFactoryPostProcessor`等。 

AnnotationConfigRegistry

注解配置注册表。用于注解配置应用上下文的通用接口，拥有一个注册配置类和扫描配置类的方法。 