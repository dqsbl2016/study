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



## BeanWrapper

对bean实例的包装。

* `BeanWrapperImpl`

  它包装了一个bean对象，缓存了bean的内省结果 ,并可以访问bean的属性、设置bean的属性值 。

  



## BeanPostProcessor

提供对象初始化前置 后置处理器

`postProcessBeforeInitialization`

``postProcessAfterInitialization``

## InstantiationAwareBeanPostProcessor

继承于`BeanPostProcessor`,  提供对象实例化前置 后置处理器,所以这个接口会存在5个方法。

`postProcessBeforeInstantiation`

`postProcessAfterInstantiation`

`postProcessPropertyValues`修改属性

过程：

* `postProcessBeforeInstantiation`方法是最先执行的方法，它在目标对象实例化之前调用，该方法的返回值类型是Object，我们可以返回任何类型的值。由于这个时候目标对象还未实例化，所以这个返回值可以用来代替原本该生成的目标对象的实例(比如代理对象)。如果该方法的返回值代替原本该生成的目标对象，后续只有`postProcessAfterInitialization`方法会调用，其它方法不再调用；否则按照正常的流程走
* `postProcessAfterInstantiation`方法在目标对象实例化之后调用，这个时候对象已经被实例化，但是该实例的属性还未被设置，都是null。因为它的返回值是决定要不要调用`postProcessPropertyValues`方法的其中一个因素（因为还有一个因素是`mbd.getDependencyCheck()`）；如果该方法返回false,并且不需要check，那么`postProcessPropertyValues`就会被忽略不执行；如果返回true，`postProcessPropertyValues`就会被执行。
* `postProcessPropertyValues`方法对属性值进行修改(这个时候属性值还未被设置，但是我们可以修改原本该设置进去的属性值)。如果`postProcessAfterInstantiation`方法返回false，该方法可能不会被调用。可以在该方法内对属性值进行修改
* 父接口`BeanPostProcessor`的2个方法`postProcessBeforeInitialization`和`postProcessAfterInitialization`都是在目标对象被实例化之后，并且属性也被设置之后调用的。



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



 ## AbstractNestablePropertyAccessor

* `wrappedObject`  存放实例化的bean







# Annotation

## @ComponentScan

默认会扫描与配置类相同的包，会扫描这个包以及这个包下的所有子包，查找带有@Component注解的类。

此外Spring支持将 `@Named` java 注入规范 ，作为@Component注解的替代方案。两者之间有一些细微的差异，但是大多数场景中，他们是可以互相替换的。

* 直接使用，会扫描与配置类相同的包

  ```java
  package org.util
  
  @ComponentScan
  public class demo(){
  }
  
  ```

* 设置指定扫描的包

  ```java
  package org.util
  
      @ComponentScan("org.com")
      public class demo(){
      }
  ```

  * 也可以扫描多个包

    ```java
    package org.util
    
        @ComponentScan(basePackages={"org.com","org.cpo"})
        public class demo(){
        }
    ```

  但是String类型不安全

  ```java
  package org.util
  
      @ComponentScan(basePackageClasses={"com.class","cpo.class"})
      public class demo(){
      }
  ```

## @ComponentScans

`@ComponentScan` 的集合配置。 多注解方式的实现。



