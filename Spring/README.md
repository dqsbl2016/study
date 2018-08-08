# Spring

## IOC初始化

* IOC初始化相关的CLASS
  * `beanFactory`
    * `ListableBeanFactory`
    * `HierarchicalBeanFactory`
      * `ConfigurableBeanFactory`
    * `AutowireCapableBeanFactory`
  * `Resource`
    * `ClassPathResource `  class
    * `FileSystemResource ` class
    * `ServletContextResource` class 
    * `UrlResource` class
  * `ResourceLoader`
    * `ResourcePatternResolver`
      * `PathMatchingResourcePatternResolver` class
    * `applicationContext` 
  * `BeanDefinitionReader`
    * `XmlBeanDefinitionReader`  class
    * `PropertiesBeanDefinitionReader` class
    * `GroovyBeanDefinitionReader` class
  * `AnnotatedBeanDefinitionReader` 
  * `ClassPathScanningCandidateComponentProvider`
    * `ClassPathBeanDefinitionScanner` class
  * `BeanDefinitionDocumentReader`
    * `DefaultBeanDefinitionDocumentReader`  class
  * `BeanDefinitionParserDelegate`  class
  * `BeanMetadataElement`
    * `BeanDefinition` 
      * `AnnotatedGenericBeanDefinition`  class
      * `RootBeanDefinition` class
      * `ChildBeanDefinition` class
      * `GenericBeanDefinition`  class
    * `BeanDefinitionHolder`
  * `BeanDefinitionReaderUtils`
  * `BeanDefinitionRegistry`
    - `DefaultListableBeanFactory`
    - `GenericApplicationContext`
* IOC初始化过程（XML）
* IOC初始化过程(Annotation)
* 自定义标签解析
* 自定义注解解析

