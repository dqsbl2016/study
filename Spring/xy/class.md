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

  











# 属性

## DefaultSingletonBeanRegistry

* `singletonObjects`   

  单例Bean的缓存集合。

* `earlySingletonObjects`

  早期的单例Bean的缓存集合。是将单例Bean注册到`singletonObjects`  集合之前的放置位置。

  （保存beanName和创建Bean实例之间的关系，当一个单例bean被放到这里后，那么当bean还在创建过程中，就可以通过getbean方法获取到了，目的用来检测循环引用）

* `singletonFactories`

  单例`ObjectFactory`对象的缓存集合，（用来保存BeanName和创建Bean的工厂之间的关系）

* `registeredSingleons`

  用来保存已经注册的所有单例bean

## DefaultListAbleBeanFactory

* `beanDefinitionMap`

  IOC容器，spring中的`definition`集合。



## SimpleAliasRegistry

* `aliasMap` 

  别名与beanName的集合，其中Value值（BeanName）也许还会是一个别名。

  

## FactoryBeanRegistrySupport

* `factoryBeanObjectCache`

  由`factorybean`创建的单件对象的缓存 



## AbstractBeanFactory

* `megredBeanDefinition` 

  合并`RootBeanDefinition`类型的beans集合

* `prototypesCurrentlyInCreation`

  当前正在创建的Bean集合



## AbstractAutowireCapableBeanFactory

* `factoryBeanInstanceCache`

  未完成的FactoryBean实例的集合



 