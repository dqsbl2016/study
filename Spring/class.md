# AbstractApplicationContext 

`ApplicationContext`接口的抽象实现，没有强制规定配置的存储类型，仅仅实现通用的上下文。主要用到模板方法设计模式，具体实现由子类进行。自动通过`registerBeanPostProcessors()`方法注册`BeanFactoryPostProcessor`, `BeanPostProcessor`和`ApplicationListener`的实例用来探测bean factory里的特殊bean 。

# BeanDefinitionRegistry 

用于持有像`RootBeanDefinition`和 `ChildBeanDefinition`实例的`bean definitions`的注册表接口。`DefaultListableBeanFactory`实现了这个接口，因此可以通过相应的方法向`beanFactory`里面注册bean。`GenericApplicationContext`内置一个`DefaultListableBeanFactory`实例，它对这个接口的实现实际上是通过调用这个实例的相应方法实现的。 

# GenericApplicationContext 

通用应用上下文，内部持有一个`DefaultListableBeanFactory`实例，这个类实现了`BeanDefinitionRegistry`接口，可以在它身上使用任意的bean definition读取器。典型的使用案例是：通过`BeanFactoryRegistry`接口注册bean definitions，然后调用`refresh()`方法来初始化那些带有应用上下文语义（`org.springframework.context.ApplicationContextAware`）的bean，自动探测`org.springframework.beans.factory.config.BeanFactoryPostProcessor`等。 

# AnnotationConfigRegistry 

注解配置注册表。用于注解配置应用上下文的通用接口，拥有一个注册配置类和扫描配置类的方法。 