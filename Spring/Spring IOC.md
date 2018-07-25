# Spring IOC

>在Spring应用中，所有的beans生存于Spring容器中，Spring容器负责创建，装配，管理它们的整个生命周期，从生存到死亡，这个容器称为IOC容器。

Spring容器并不是只有一个，可以分为二种类型。

### BeanFactory

  `org.springframework.beans.factory.BeanFactory` 是最简单的容器，提供基本的DI支持。

![image](https://github.com/dqsbl2016/study/blob/master/Spring/img/1532489938612.jpg)


>其中 BeanFactory 作为最顶层的一个接口类，它定义了 IOC 容器的基本功能规范，BeanFactory 有三个子类：ListableBeanFactory、>HierarchicalBeanFactory 和 AutowireCapableBeanFactory。
>但是从上图中我们可以发现最终的默认实现类是DefaultListableBeanFactory，他实现了所有的接口。那为何要定义这么多层次的接口呢？查阅这些接口的源码和说明>发现，每个接口都有他使用的场合，它主要是为了区分在Spring内部在操作过程中对象的传递和转化过程中，对对象的数据访问所做的限制。例如>ListableBeanFactory接口表示这些Bean 是可列表的，而HierarchicalBeanFactory表示的是这些Bean是有继承关系的，也就是每个Bean有可能有父Bean。>AutowireCapableBeanFactory接口定义Bean的自动装配规则。这四个接口共同定义了Bean的集合、Bean之间的关系、以及Bean行为.


### ApplicationContext

`org.springframework.context.ApplicationContext`基于BeanFactory构建，提供应用框架级别的服务，例如从属性文件解析文本信息以及发布应用事件给事件监听者。

![image](https://github.com/dqsbl2016/study/blob/master/Spring/img/1532494390919.jpg)


>ApplicationContext允许上下文嵌套，通过保持父上下文可以维持一个上下文体系。对于Bean的查找可以在这个上下文体系中发生，首先检查当前上下文，其次是父上>下文，逐级向上，这样为不同的Spring应用提供了一个共享的Bean定义环境。




## IOC容器初始化，加载上下文

Spring自带了多种类型的应用上下文，其中包括 `FileSystemXmlApplicationContext`,`ClassPathXmlApplicationContext`等。无论哪种方式都是通过调用`AbstractApplicationContext`中的`refresh()`方法开始IOC容器初始化工作。IOC容器的初始化就是`Bean`的`Resource`定位、载入和注册这三个基本的过程。Spring把这三个过程分开，使用不同的模块来完成，通过这样的设计让用户更灵活的对三个过程进行剪裁或扩展，定义出自己最合适的IOC容器初始化过程。

### 定位

定位的过程是`Resource`定位过程。是指Bean的资源定位，由`ResourceLoader`通过统一的`Resource`接口来完成，`Resource`接口将各种形式的Bean定义资源文件封装成统一的、IOC容器可进行载入操作的对象。其中最常见的四种类型资源：

* ***ClassPathResource***：

  ``` java
  public InputStream getInputStream() throws IOException {  
              InputStream is;  
               if ( this. clazz != null) {  
                    is = this. clazz.getResourceAsStream( this. path);  
              }  
               else {  
                    is = this. classLoader.getResourceAsStream( this. path);  
              }  
               if (is == null) {  
                     throw new FileNotFoundException(getDescription() + " cannot be opened because it does not exist");  
              }  
               return is;  
        }  
  ```

  通过`Class`或者`ClassLoader`的`getResourceAsStream()`方法来获得`InputStream`的。其path一般都是以`classpath:`开头，如果以`classpath*:`开头表示所有与给定名称匹配的`classpath`资源都应该被获取。 

* ***FileSystemResource***：

  ```java
  public InputStream getInputStream() throws IOException {  
               return new FileInputStream( this. file);  
        }  
  ```

  这里的`file`是使用传入（构造函数中）的`path`生成的`File`，然后使用该`File`构造`FileInputStream`作为方法的输出。

  这里的`path`一般要给出绝对路径，当然也可以是相对路径，如果是相对路径要注意其根目录。例如在eclipse中，它的根目录就是你工程目录作为你的根目录。

* ***ServletContextResource***：

  ```java
  public InputStream getInputStream() throws IOException {  
          InputStream is = this.servletContext.getResourceAsStream(this.path);  
          if (is == null) {  
              throw new FileNotFoundException("Could not open " + getDescription());  
          }  
          return is;  
  }
  ```

  `ServletContextResource`通过`ServletContext`的`getResourceAsStream()`来取得`InputStream`，这里`path`必须以`“/”`开头，并且相对于当前上下文的根目录。如常用的`path="/WEB-INF/web.xml"`。 

* ***UrlResource*** ：

  ```java
  public InputStream getInputStream() throws IOException {  
              URLConnection con = this. url.openConnection();  
              ResourceUtils. useCachesIfNecessary(con);  
               try {  
                     return con.getInputStream();  
              }  
               catch (IOException ex) {  
                     // Close the HTTP connection (if applicable).  
                     if (con instanceof HttpURLConnection) {  
                          ((HttpURLConnection) con).disconnect();  
                    }  
                     throw ex;  
              }  
   }  
  ```

  `UrlResource` 封装了`java.net.URL`，它能够被用来访问任何通过URL可以获得的对象，例如：文件、HTTP对象、FTP对象等。 所有的URL都有个标准的 String表示，这些标准前缀可以标识不同的URL类型，包括`file:`访问文件系统路径，`http: `通过HTTP协议访问的资源，`ftp: `通过FTP访问的资源等等。 

#### ResourceLoader

`ResourceLoader`接口定义了一个用于获取`Resource`的`getResource`方法。它包含很多实现类，例如`DefaultResourceLoader`实现的策略是：首先判断指定的`location`是否含有`classpath:`前缀，如果有则把`location`去掉`classpath:`前缀返回对应的`ClassPathResource`；否则就把它当做一个`URL`来处理，封装成一个`UrlResource`进行返回；如果当成`URL`处理也失败的话就把`location`对应的资源当成是一个`ClassPathResource`进行返回。 

`ApplicationContext`接口也继承了`ResourceLoader`接口，所以它的实现类也可以获取`Resource`。

* ***ClassPathXmlApplicationContext***  它在获取`Resource`时继承的是它的父类`DefaultResourceLoader`的策略。 可以从`Class Path`载入`Resource`。

* ***FileSystemXmlApplicationContext***   也继承了`DefaultResourceLoader`，但是它重写了`DefaultResourceLoader`的`getResourceByPath(String path)`方法。所以它在获取资源文件时首先也是判断指定的`location`是否包含`classpath:`前缀，如果包含，则把`location`中`classpath:`前缀后的资源从类路径下获取出来，当做一个`ClassPathResource`；否则，继续尝试把`location`封装成一个`URL`，返回对应的`UrlResource`；如果还是失败，则把`location`指定位置的资源当做一个`FileSystemResource`进行返回。 

  可以从文件系统载入`Resource`。

* ***XmlWebApplicationContext***  可以在web容器中载入`Resource`。通过`Web.xml`中配置

  ```java
  <context-param>
      <param-name>contextConfigLocation</param-name>
      <param-value>
  			classpath:applicationContext.xml
  		</param-value>
    </context-param>
    <listener>
      <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>
  ```

  就是这种方式。其中`ContextLoaderListener`实现`ServletContextListener`接口，而Spring启动时会自动触发其中的`contextInitialized `接口。最后执行的就是`XmlWebApplicationContext  `,后续将会提到这个过程。     

### 载入

载入过程是通过之前定位好的资源文件，会先通过`XmlBeanDefinitionReader`解析器将Bean定义资源文件转换成`Document`对象，然后通过`DefaultBeanDefinitionDocumentReader`对`Document`对象解析,然后将Bean的相关信息封装成IOC容器内部的数据结构，就是`BeanDefinition`。

#### BeanDefinition

Spring IOC容器管理了我们定义的各种Bean对象及相互关系，Bean对象在Spring实现中是以`BeanDefinition`来描述的。

### 注册

这个过程就是向IOC容器中注册这些`BeanDefinition`的过程，通过调用`BeanDefinitionRegistry`接口来实现完成的。实际上IOC容器就是`DefaultListableBeanFactory`中的`beanDefinitionMap` 是一个`ConcurrentHashMap`。



> 在Spring IOC的设计中，Bean的载入和依赖注入是两个独立的过程。依赖注册是第一次通过`getBean()`向容器索取Bean的时候发生，但是又一个例外，如果某个Bean设置了`lazyinit`属性，那么Bean的依赖注入会在IOC容器初始化时就也会完成。



### FileSystemXmlApplicationContext流程

通过实例调用 `new FileSystemXmlApplicationContext(xmlPath)`，进入构造函数。

```java
public FileSystemXmlApplicationContext(
			String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
			throws BeansException {
		super(parent);
		setConfigLocations(configLocations);
		if (refresh) {
			refresh();
		}
	}
```

####资源定位

调用父类构造函数，获取**资源加载器**。 使用的是`DefaultResourceLoader`,另外`FileSystemXmlApplicationContext`复写了`DefaultResourceLoader`中的`getResourceByPath`方法，所以获取资源类型逻辑有变化。

```java
public abstract class AbstractApplicationContext extends DefaultResourceLoader
		implements ConfigurableApplicationContext {
		...
		public AbstractApplicationContext() {
			this.resourcePatternResolver = getResourcePatternResolver();
		}
		...
		protected ResourcePatternResolver getResourcePatternResolver() {
			return new PathMatchingResourcePatternResolver(this);
		}
		...
}
```

返回一个`PathMatchingResourcePatternResolver`实例, 通过构造方法初始化`resourceLoader`资源加载器为`DefaultResourceLoader`,因为传入参数`this`的类`AbstractApplicationContext`继承`DefaultResourceLoader`。

```java
public PathMatchingResourcePatternResolver(ResourceLoader resourceLoader) {
		Assert.notNull(resourceLoader, "ResourceLoader must not be null");
		this.resourceLoader = resourceLoader;
	}
```

`FileSystemXmlApplicationContext`构造方法中继续调用`AbstractRefreshableConfigApplicationContext#setConfigLocations`方法，对要加载资源文件进行记录。

```java
public void setConfigLocations(@Nullable String... locations) {
		if (locations != null) {
			Assert.noNullElements(locations, "Config locations must not be null");
			this.configLocations = new String[locations.length];
			for (int i = 0; i < locations.length; i++) {
				this.configLocations[i] = resolvePath(locations[i]).trim();
			}
		}
		else {
			this.configLocations = null;
		}
	}
```

#### 载入

`FileSystemXmlApplicationContext`构造方法中继续调用`refresh()`，进入到`AbstractApplicationContext#refresh`。

```java
@Override
	public void refresh() throws BeansException, IllegalStateException {
		synchronized (this.startupShutdownMonitor) {
			//调用容器准备刷新的方法，获取容器的当时时间，同时给容器设置同步标识
            prepareRefresh();
            //告诉子类启动 refreshBeanFactory()方法，Bean 定义资源文件的载入从
            //子类的 refreshBeanFactory()方法启动
            ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();
            //为 BeanFactory 配置容器特性，例如类加载器、事件处理器等
            prepareBeanFactory(beanFactory);
            try {
                    //为容器的某些子类指定特殊的 BeanPost 事件处理器
                    postProcessBeanFactory(beanFactory);
                    //调用所有注册的 BeanFactoryPostProcessor 的 Bean
                    invokeBeanFactoryPostProcessors(beanFactory);
                    //为 BeanFactory 注册 BeanPost 事件处理器.
                    //BeanPostProcessor 是 Bean 后置处理器，用于监听容器触发的事件
                    registerBeanPostProcessors(beanFactory);
                    //初始化信息源，和国际化相关.
                    initMessageSource();
                    //初始化容器事件传播器.
                    initApplicationEventMulticaster();
                    //调用子类的某些特殊 Bean 初始化方法
                    onRefresh();
                    //为事件传播器注册事件监听器.
                    registerListeners();
                    //初始化所有剩余的单例 Bean
                    finishBeanFactoryInitialization(beanFactory);
                    //初始化容器的生命周期事件处理器，并发布容器的生命周期事件
                    finishRefresh();
            }
            catch (BeansException ex) {
                if (logger.isWarnEnabled()) {
                    logger.warn("Exception encountered during context initialization - " +
                                "cancelling refresh attempt: " + ex);
                }
                //销毁已创建的 Bean
                destroyBeans();
                //取消 refresh 操作，重置容器的同步标识.
                cancelRefresh(ex);
				// Propagate exception to caller.
				throw ex;
			}
			finally {
				// Reset common introspection caches in Spring's core, since we
				// might not ever need metadata for singleton beans anymore...
				resetCommonCaches();
			}
		}
	}
```

bean中解析、载入、注册通过`obtainFreshBeanFactory`方法进入。

```
protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
		refreshBeanFactory();
		ConfigurableListableBeanFactory beanFactory = getBeanFactory();
		if (logger.isDebugEnabled()) {
			logger.debug("Bean factory for " + getDisplayName() + ": " + beanFactory);
		}
		return beanFactory;
	}
```

调用子类`AbstractRefreshableApplicationContext`中`refreshBeanFactory`方法。

```java
@Override
	protected final void refreshBeanFactory() throws BeansException {
		if (hasBeanFactory()) {
			destroyBeans();
			closeBeanFactory();
		}
		try {
			DefaultListableBeanFactory beanFactory = createBeanFactory();
			beanFactory.setSerializationId(getId());
			customizeBeanFactory(beanFactory);
			loadBeanDefinitions(beanFactory);
			synchronized (this.beanFactoryMonitor) {
				this.beanFactory = beanFactory;
			}
		}
		catch (IOException ex) {
			throw new ApplicationContextException("I/O error parsing bean definition source for " + getDisplayName(), ex);
		}
	}
```

先验证是否已存在容器，如果存在则销毁，然后重新创建容器。创建一个`DefaultListableBeanFactory`容器。

调用子类`AbstractXmlApplicationContext`执行装载bean定义。

```java
@Override
	protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
		// Create a new XmlBeanDefinitionReader for the given BeanFactory.
		XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);
		// Configure the bean definition reader with this context's
		// resource loading environment.
		beanDefinitionReader.setEnvironment(this.getEnvironment());
		beanDefinitionReader.setResourceLoader(this);
		beanDefinitionReader.setEntityResolver(new ResourceEntityResolver(this));
		// Allow a subclass to provide custom initialization of the reader,
		// then proceed with actually loading the bean definitions.
		initBeanDefinitionReader(beanDefinitionReader);
		loadBeanDefinitions(beanDefinitionReader);
	}
```

这里会先创建一个`XmlBeanDefinitionReader`，加载上面的要加载资源文件记录。因为是`FileSystemXmlApplicationContext`作为入口，所以`getConfigResources`返回的是null，会执行`getConfigLocations`分支。

```java
protected void loadBeanDefinitions(XmlBeanDefinitionReader reader) throws BeansException, IOException {
		Resource[] configResources = getConfigResources();
		if (configResources != null) {
			reader.loadBeanDefinitions(configResources);
		}
		String[] configLocations = getConfigLocations();
		if (configLocations != null) {
			reader.loadBeanDefinitions(configLocations);
		}
	}
```

调用其父类`AbstractBeanDefinitionReader`中`loadBeanDefinitions`读取bean定义资源。

```java
public int loadBeanDefinitions(String location, @Nullable Set<Resource> actualResources) throws BeanDefinitionStoreException {
		ResourceLoader resourceLoader = getResourceLoader();
		if (resourceLoader == null) {
			throw new BeanDefinitionStoreException(
					"Cannot import bean definitions from location [" + location + "]: no ResourceLoader available");
		}

		if (resourceLoader instanceof ResourcePatternResolver) {
			// Resource pattern matching available.
			try {
				Resource[] resources = ((ResourcePatternResolver) resourceLoader).getResources(location);
				int loadCount = loadBeanDefinitions(resources);
				if (actualResources != null) {
					for (Resource resource : resources) {
						actualResources.add(resource);
					}
				}
				if (logger.isDebugEnabled()) {
					logger.debug("Loaded " + loadCount + " bean definitions from location pattern [" + location + "]");
				}
				return loadCount;
			}
			catch (IOException ex) {
				throw new BeanDefinitionStoreException(
						"Could not resolve bean definition resource pattern [" + location + "]", ex);
			}
		}
		else {
			// Can only load single resources by absolute URL.
			Resource resource = resourceLoader.getResource(location);
			int loadCount = loadBeanDefinitions(resource);
			if (actualResources != null) {
				actualResources.add(resource);
			}
			if (logger.isDebugEnabled()) {
				logger.debug("Loaded " + loadCount + " bean definitions from location [" + location + "]");
			}
			return loadCount;
		}
	}


@Override
	public int loadBeanDefinitions(Resource... resources) throws BeanDefinitionStoreException {
		Assert.notNull(resources, "Resource array must not be null");
		int counter = 0;
		for (Resource resource : resources) {
			counter += loadBeanDefinitions(resource);
		}
		return counter;
	}
```

通过获取上面定义的`ResourceLoader`资源加载器(`DefaultResourceLoader`)，调用`getResources`方法获取资源。因为`FileSystemXmlApplicationContext`本身就是``DefaultResourceLoader``的实现类，所以又回到了`FileSystemXmlApplicationContext`中读取资源。

```java

```

