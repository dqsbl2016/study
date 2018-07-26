# Spring IOC

>在Spring应用中，所有的beans生存于Spring容器中，Spring容器负责创建，装配，管理它们的整个生命周期，从生存到死亡，这个容器称为IOC容器。

Spring容器并不是只有一个，可以分为二种类型。

### BeanFactory

  `org.springframework.beans.factory.BeanFactory` 是最简单的容器，提供基本的DI支持。

![image](https://github.com/dqsbl2016/study/blob/master/Spring/img/1532489938612.jpg)


>其中 BeanFactory 作为最顶层的一个接口类，它定义了 IOC 容器的基本功能规范，BeanFactory 有三个子类：ListableBeanFactory、HierarchicalBeanFactory 和 AutowireCapableBeanFactory。
>但是从上图中我们可以发现最终的默认实现类是DefaultListableBeanFactory，他实现了所有的接口。那为何要定义这么多层次的接口呢？查阅这些接口的源码和说明>发现，每个接口都有他使用的场合，它主要是为了区分在Spring内部在操作过程中对象的传递和转化过程中，对对象的数据访问所做的限制。例如ListableBeanFactory接口表示这些Bean 是集合列表的，而HierarchicalBeanFactory表示的是这些Bean是有继承关系的，也就是每个Bean有可能有父Bean。AutowireCapableBeanFactory接口定义Bean的自动装配规则。这四个接口共同定义了Bean的集合、Bean之间的关系、以及Bean行为。


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

Spring IOC容器管理了我们定义的各种Bean对象及相互关系，Bean对象在Spring实现中是以`BeanDefinition`来描述的。`BeanDefinition`的这种方式就是装饰器设计模式，对Bean的扩展和增强后依然保留OOP关系。

### 注册

这个过程就是向IOC容器中注册这些`BeanDefinition`的过程，通过调用`BeanDefinitionRegistry`接口来实现完成的。实际上IOC容器就是`DefaultListableBeanFactory`中的`beanDefinitionMap` 是一个`ConcurrentHashMap`。



> 在Spring IOC的设计中，Bean的载入和依赖注入是两个独立的过程。依赖注册是第一次通过`getBean()`向容器索取Bean的时候发生，但是又一个例外，如果某个Bean设置了`lazyinit`属性，那么Bean的依赖注入会在IOC容器初始化时就也会完成。



### FileSystemXmlApplicationContext入口源码流程

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

#### 资源定位

调用父类构造函数，获取**资源加载器**。 使用的是`DefaultResourceLoader`(但是class类型是`AbstractApplicationContext`),另外`FileSystemXmlApplicationContext`复写了`DefaultResourceLoader`中的`getResourceByPath`方法，所以获取资源类型逻辑有变化。

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

返回一个`PathMatchingResourcePatternResolver`实例, 通过构造方法初始化传入参数`AbstractApplicationContext`，所以采用的`resourceLoader`资源加载器为`AbstractApplicationContext`。不过因为`AbstractApplicationContext`继承`DefaultResourceLoader`，所以采用资源加载器也可以说是`DefaultResourceLoader`。

```java
public PathMatchingResourcePatternResolver(ResourceLoader resourceLoader) {
		Assert.notNull(resourceLoader, "ResourceLoader must not be null");
		this.resourceLoader = resourceLoader;
	}
```

其中继承关系如下：

* `org.springframework.core.io.DefaultResourceLoader`
  * `org.springframework.context.support.AbstractApplicationContext`

    >对上下文的一些操作及定义。
    >
    >**`refresh()`**
    >
    >包括IOC容器初始化，事件初始化等等过程。

    * `org.springframework.context.support.AbstractRefreshableApplicationContext`

      >存储容器，并验证是否存在，创建，关闭等过程的类
      >
      >**`private DefaultListableBeanFactory beanFactory;`**
      >
      >ioc容器
      >
      >**`refreshBeanFactory()`**
      >
      >复合操作，判断容器是否存在，存在就销毁，然后重新创建容器。

      * `org.springframework.context.support.AbstractRefreshableConfigApplicationContext`

        >记录资源的类
        >
        >**`private String[] configLocations;`**
        >
        >定义的存储容器
        >
        >**`setConfigLocations(@Nullable String... locations) `**
        >
        >将资源文件存储到容器中
        >
        >**`getConfigLocations()`**
        >
        >返回当前资源内容

        * `org.springframework.context.support.AbstractXmlApplicationContext`

          >针对XML文件解析的类
          >
          >**`loadBeanDefinitions(DefaultListableBeanFactory beanFactory) `**
          >
          >创建一个针对XML文件的bean读取器`XmlBeanDefinitionReader `。
          >
          >**`loadBeanDefinitions(XmlBeanDefinitionReader reader) `**
          >
          >通过读取器读取所有资源

          * `org.springframework.context.support.FileSystemXmlApplicationContext`

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

>这里说明下为什么`loadBeanDefinitions(beanFactory);`会掉用`AbstractXmlApplicationContext`中的`loadBeanDefinitions`实现呢？
>
>因为程序入口是`FileSystemXmlApplicationContext`，通过上面的继承关系可以了解到`FileSystemXmlApplicationContext`->`AbstractXmlApplicationContext`->`AbstractRefreshableConfigApplicationContext`->`AbstractRefreshableApplicationContext`,所以在`AbstractRefreshableApplicationContext`中调用`loadBeanDefinitions`方法时（在`AbstractRefreshableApplicationContext`中定义的`loadBeanDefinitions`只是个抽象方法），会逐级向子类中寻找实现，所以找到了`AbstractXmlApplicationContext`中的实现。这个就是模板设计模式，父类中定义方法，子类中进行实现，不同子类可以进行不同业务的实现处理。

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

这里会先创建一个`XmlBeanDefinitionReader`针对于XML文件类的读取器，通过一些参数配置后，调用`loadBeanDefinitions`开始资源加载工作。

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

因为是`FileSystemXmlApplicationContext`作为入口，所以`getConfigResources`返回的是null，会执行`getConfigLocations`分支。因为`XmlBeanDefinitionReader`中并没有`loadBeanDefinitions(configLocations)`的实现，所以会调用其父类`AbstractBeanDefinitionReader`中`loadBeanDefinitions`读取bean定义资源。

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
```

通过获取上面定义的`ResourceLoader`资源加载器(`AbstractApplicationContext`)，所以是调用`AbstractApplicationContext`中的`getResources`方法。

```java
@Override
	public Resource[] getResources(String locationPattern) throws IOException {
		return this.resourcePatternResolver.getResources(locationPattern);
	}
```

在这里这个`resourcePatternResolver`是在最初定位的时候选择资源加载器的时候进行过赋值，参考上面的步骤，所以这个是调用`PathMatchingResourcePatternResolver`中的`getResources`方法。

```java
@Override
	public Resource[] getResources(String locationPattern) throws IOException {
		Assert.notNull(locationPattern, "Location pattern must not be null");
		if (locationPattern.startsWith(CLASSPATH_ALL_URL_PREFIX)) {
			// a class path resource (multiple resources for same name possible)
			if (getPathMatcher().isPattern(locationPattern.substring(CLASSPATH_ALL_URL_PREFIX.length()))) {
				// a class path resource pattern
				return findPathMatchingResources(locationPattern);
			}
			else {
				// all class path resources with the given name
				return findAllClassPathResources(locationPattern.substring(CLASSPATH_ALL_URL_PREFIX.length()));
			}
		}
		else {
			// Generally only look for a pattern after a prefix here,
			// and on Tomcat only after the "*/" separator for its "war:" protocol.
			int prefixEnd = (locationPattern.startsWith("war:") ? locationPattern.indexOf("*/") + 1 :
					locationPattern.indexOf(':') + 1);
			if (getPathMatcher().isPattern(locationPattern.substring(prefixEnd))) {
				// a file pattern
				return findPathMatchingResources(locationPattern);
			}
			else {
				// a single resource with the given name
				return new Resource[] {getResourceLoader().getResource(locationPattern)};
			}
		}
	}
```

这个方法中先针对配置的是否以`classpath*:`开头分别处理 ,如果不是还会有一些其他开头验证，如果都不存在会执行`getResourceLoader().getResource(locationPattern)`操作，在这里就会进入到`DefaultResourceLoader`中的`getResource`方法。

```java
@Override
	public Resource getResource(String location) {
		Assert.notNull(location, "Location must not be null");

		for (ProtocolResolver protocolResolver : this.protocolResolvers) {
			Resource resource = protocolResolver.resolve(location, this);
			if (resource != null) {
				return resource;
			}
		}
		if (location.startsWith("/")) {
			return getResourceByPath(location);
		}
		else if (location.startsWith(CLASSPATH_URL_PREFIX)) {
			return new ClassPathResource(location.substring(CLASSPATH_URL_PREFIX.length()), getClassLoader());
		}
		else {
			try {
				// Try to parse the location as a URL...
				URL url = new URL(location);
				return (ResourceUtils.isFileURL(url) ? new FileUrlResource(url) : new UrlResource(url));
			}
			catch (MalformedURLException ex) {
				// No URL -> resolve as resource path.
				return getResourceByPath(location);
			}
		}
	}
```

在调用`getResourceByPath`方法时，由于`FileSystemXmlApplicationContext`中复写了`getResourceByPath`的实现，就是为了处理既不是`classpath`标识,又不是`URL`标识的`Resource`资源定位的情况，提供了从文件系统得到配置文件的资源定义。所以会调用`FileSystemXmlApplicationContext`中`getResourceByPath`方法。

```java
@Override
	protected Resource getResourceByPath(String path) {
		if (path.startsWith("/")) {
			path = path.substring(1);
		}
		return new FileSystemResource(path);
	}
```

这样，就可以从文件系统路径上对 配置文件进行加载，当然我们可以按照这个逻辑从任何地方加载，在 spring 中 我 们 看 到 它 提 供 的 各 种 资 源 抽 象 ， 比 如`ClassPathResource`,`URLResource`,`FileSystemResource `等来供我们使用。继续回到`AbstractBeanDefinitionReader`中，会继续调用`loadBeanDefinitions(resources)`方法。

```java
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

因为获取的`Resource`是多个，这里会对进行遍历处理。而`loadBeanDefinitions`这个方法在本类中只定义了抽象方法，所以还是从子类中寻找实现，就是`XmlBeanDefinitionReader`中的实现。

```java
	@Override
	public int loadBeanDefinitions(Resource resource) throws BeanDefinitionStoreException {
		return loadBeanDefinitions(new EncodedResource(resource));
	}
...
    public int loadBeanDefinitions(EncodedResource encodedResource) throws BeanDefinitionStoreException {
		Assert.notNull(encodedResource, "EncodedResource must not be null");
		if (logger.isInfoEnabled()) {
			logger.info("Loading XML bean definitions from " + encodedResource.getResource());
		}

		Set<EncodedResource> currentResources = this.resourcesCurrentlyBeingLoaded.get();
		if (currentResources == null) {
			currentResources = new HashSet<>(4);
			this.resourcesCurrentlyBeingLoaded.set(currentResources);
		}
		if (!currentResources.add(encodedResource)) {
			throw new BeanDefinitionStoreException(
					"Detected cyclic loading of " + encodedResource + " - check your import definitions!");
		}
		try {
			InputStream inputStream = encodedResource.getResource().getInputStream();
			try {
				InputSource inputSource = new InputSource(inputStream);
				if (encodedResource.getEncoding() != null) {
					inputSource.setEncoding(encodedResource.getEncoding());
				}
				return doLoadBeanDefinitions(inputSource, encodedResource.getResource());
			}
			finally {
				inputStream.close();
			}
		}
		catch (IOException ex) {
			throw new BeanDefinitionStoreException(
					"IOException parsing XML document from " + encodedResource.getResource(), ex);
		}
		finally {
			currentResources.remove(encodedResource);
			if (currentResources.isEmpty()) {
				this.resourcesCurrentlyBeingLoaded.remove();
			}
		}
	}
```

会先对`Resource`进行特殊编码处理，转化为`InputStream`，调用`doLoadBeanDefinitions(inputSource, encodedResource.getResource())`开始进行处理。

```java
protected int doLoadBeanDefinitions(InputSource inputSource, Resource resource)
			throws BeanDefinitionStoreException {
		try {
			Document doc = doLoadDocument(inputSource, resource);
			return registerBeanDefinitions(doc, resource);
		}
		...
	}
```

最后一步将资源文件转换为`Document`对象,但是这些`Doument`对象并没有按照Spring的bean规则进行解析。

```java
protected Document doLoadDocument(InputSource inputSource, Resource resource) throws Exception {
		return this.documentLoader.loadDocument(inputSource, getEntityResolver(), this.errorHandler,
				getValidationModeForResource(resource), isNamespaceAware());
	}
```

其中`documentLoader`可以从定义中看到具体类型，再定义变量时就已经进行赋值。

`private DocumentLoader documentLoader = new DefaultDocumentLoader();`所以会进入`DefaultDocumentLoader`中的`loadDocument`方法。

```java
@Override
	public Document loadDocument(InputSource inputSource, EntityResolver entityResolver,
			ErrorHandler errorHandler, int validationMode, boolean namespaceAware) throws Exception {

		DocumentBuilderFactory factory = createDocumentBuilderFactory(validationMode, namespaceAware);
		if (logger.isDebugEnabled()) {
			logger.debug("Using JAXP provider [" + factory.getClass().getName() + "]");
		}
		DocumentBuilder builder = createDocumentBuilder(factory, entityResolver, errorHandler);
		return builder.parse(inputSource);
	}
...
protected DocumentBuilderFactory createDocumentBuilderFactory(int validationMode, boolean namespaceAware)
			throws ParserConfigurationException {

		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(namespaceAware);

		if (validationMode != XmlValidationModeDetector.VALIDATION_NONE) {
			factory.setValidating(true);
			if (validationMode == XmlValidationModeDetector.VALIDATION_XSD) {
				// Enforce namespace aware for XSD...
				factory.setNamespaceAware(true);
				try {
					factory.setAttribute(SCHEMA_LANGUAGE_ATTRIBUTE, XSD_SCHEMA_LANGUAGE);
				}
				catch (IllegalArgumentException ex) {
					ParserConfigurationException pcex = new ParserConfigurationException(
							"Unable to validate using XSD: Your JAXP provider [" + factory +
							"] does not support XML Schema. Are you running on Java 1.4 with Apache Crimson? " +
							"Upgrade to Apache Xerces (or Java 1.5) for full XSD support.");
					pcex.initCause(ex);
					throw pcex;
				}
			}
		}

		return factory;
	}
```

该解析过程调用`JavaEE` 标准的 `JAXP` 标准进行处理。
继续回到`XmlBeanDefinitionReader`中的`doLoadBeanDefinitions`方法，将继续执行`registerBeanDefinitions`操作。

```java
	public int registerBeanDefinitions(Document doc, Resource resource) throws BeanDefinitionStoreException {
		BeanDefinitionDocumentReader documentReader = createBeanDefinitionDocumentReader();
		int countBefore = getRegistry().getBeanDefinitionCount();
		documentReader.registerBeanDefinitions(doc, createReaderContext(resource));
		return getRegistry().getBeanDefinitionCount() - countBefore;
	}
```

通过`createBeanDefinitionDocumentReader`创建一个`BeanDefinitionDocumentReader`读取器，返回的是个`DefaultBeanDefinitionDocumentReader`对象。`BeanDefinitionDocumentReader`读取器主要实现按Spring的bean规则对`Document`对象进行解析。这里会调用`DefaultBeanDefinitionDocumentReader`中的`registerBeanDefinitions`方法。

```java
@Override
	public void registerBeanDefinitions(Document doc, XmlReaderContext readerContext) {
		this.readerContext = readerContext;
		logger.debug("Loading bean definitions");
		Element root = doc.getDocumentElement();
		doRegisterBeanDefinitions(root);
	}
...
    protected void doRegisterBeanDefinitions(Element root) {
		// Any nested <beans> elements will cause recursion in this method. In
		// order to propagate and preserve <beans> default-* attributes correctly,
		// keep track of the current (parent) delegate, which may be null. Create
		// the new (child) delegate with a reference to the parent for fallback purposes,
		// then ultimately reset this.delegate back to its original (parent) reference.
		// this behavior emulates a stack of delegates without actually necessitating one.
		BeanDefinitionParserDelegate parent = this.delegate;
		this.delegate = createDelegate(getReaderContext(), root, parent);

		if (this.delegate.isDefaultNamespace(root)) {
			String profileSpec = root.getAttribute(PROFILE_ATTRIBUTE);
			if (StringUtils.hasText(profileSpec)) {
				String[] specifiedProfiles = StringUtils.tokenizeToStringArray(
						profileSpec, BeanDefinitionParserDelegate.MULTI_VALUE_ATTRIBUTE_DELIMITERS);
				if (!getReaderContext().getEnvironment().acceptsProfiles(specifiedProfiles)) {
					if (logger.isInfoEnabled()) {
						logger.info("Skipped XML bean definition file due to specified profiles [" + profileSpec +
								"] not matching: " + getReaderContext().getResource());
					}
					return;
				}
			}
		}

		preProcessXml(root);
		parseBeanDefinitions(root, this.delegate);
		postProcessXml(root);

		this.delegate = parent;
	}
```

其中在具体操作`parseBeanDefinitions`方法的前后都加了`preProcessXml`方法。作用就是为了在解析Bean定义之前，增加一个可扩展的方法。进入`parseBeanDefinitions`方法。

```java
protected void parseBeanDefinitions(Element root, BeanDefinitionParserDelegate delegate) {
		if (delegate.isDefaultNamespace(root)) {
			NodeList nl = root.getChildNodes();
			for (int i = 0; i < nl.getLength(); i++) {
				Node node = nl.item(i);
				if (node instanceof Element) {
					Element ele = (Element) node;
					if (delegate.isDefaultNamespace(ele)) {
						parseDefaultElement(ele, delegate);
					}
					else {
						delegate.parseCustomElement(ele);
					}
				}
			}
		}
		else {
			delegate.parseCustomElement(root);
		}
	}
```

使用Spring的Bean规则从`Document`的根元素开始进行解析。如果当前元素节点使用的是Spring默认的`XML`命名空间进入`parseDefaultElement`方法，如果没有使用Spring默认的`XML`命名空间，则进入用户自定义的解析规则解析元素点`parseCustomElement`。这里只看`parseDefaultElement`方法。

```java
private void parseDefaultElement(Element ele, BeanDefinitionParserDelegate delegate) {
    	//如果元素节点是<Import>导入元素，进行导入解析
		if (delegate.nodeNameEquals(ele, IMPORT_ELEMENT)) {
			importBeanDefinitionResource(ele);
		}
   		 //如果元素节点是<Alias>别名元素，进行别名解析
		else if (delegate.nodeNameEquals(ele, ALIAS_ELEMENT)) {
			processAliasRegistration(ele);
		}
   		 //元素节点既不是导入元素，也不是别名元素，即普通的<Bean>元素，
		//按照 Spring 的 Bean 规则解析元素
		else if (delegate.nodeNameEquals(ele, BEAN_ELEMENT)) {
			processBeanDefinition(ele, delegate);
		}
		else if (delegate.nodeNameEquals(ele, NESTED_BEANS_ELEMENT)) {
			// recurse
			doRegisterBeanDefinitions(ele);
		}
	}
```

判断当前元素节点的命名空间，使用`BeanDefinitionParserDelegate`对Bean定义内容进行解析。对`<import>`元素节点的处理方法`importBeanDefinitionResource`。

```java
//解析<Import>导入元素，从给定的导入路径加载 Bean 定义资源到 Spring IOC 容器中
protected void importBeanDefinitionResource(Element ele) {
	//获取给定的导入元素的 location 属性
	String location = ele.getAttribute(RESOURCE_ATTRIBUTE);
	//如果导入元素的 location 属性值为空，则没有导入任何资源，直接返回
	if (!StringUtils.hasText(location)) {
		getReaderContext().error("Resource location must not be empty", ele);
		return;
	}
	//使用系统变量值解析 location 属性值
	location = getReaderContext().getEnvironment().resolveRequiredPlaceholders(location);
	Set<Resource> actualResources = new LinkedHashSet<>(4);
	//标识给定的导入元素的 location 是否是绝对路径
    boolean absoluteLocation = false;
	try {
		absoluteLocation = ResourcePatternUtils.isUrl(location) || 									ResourceUtils.toURI(location).isAbsolute();
    }
	catch (URISyntaxException ex) {
		//给定的导入元素的 location 不是绝对路径
	}
	// Absolute or relative?
	//给定的导入元素的 location 是绝对路径
	if (absoluteLocation) {
		try {
            //使用资源读入器加载给定路径的 Bean 定义资源
            int importCount = getReaderContext().getReader().loadBeanDefinitions(location, 				actualResources);
			if (logger.isDebugEnabled()) {
				logger.debug("Imported " + importCount + " bean definitions from URL location 					[" + location + "]");
            }
        }
        catch (BeanDefinitionStoreException ex) {
                getReaderContext().error("Failed to import bean definitions from URL location [" 				+ location + "]", ele,ex);
                }
        }
	else {
        //给定的导入元素的 location 是相对路径
        try {
            int importCount;
            //将给定导入元素的 location 封装为相对路径资源
            Resource relativeResource=getReaderContext().getResource().createRelative(location);
            //封装的相对路径资源存在
            if (relativeResource.exists()) {
                //使用资源读入器加载 Bean 定义资源
              importCount=getReaderContext().getReader().loadBeanDefinitions(relativeResource);
                actualResources.add(relativeResource);
            }
		   //封装的相对路径资源不存在
            else {
                //获取 Spring IOC 容器资源读入器的基本路径
                String baseLocation = getReaderContext().getResource().getURL().toString();
                //根据 Spring IOC 容器资源读入器的基本路径加载给定导入路径的资源
                importCount = getReaderContext().getReader().loadBeanDefinitions(
                StringUtils.applyRelativePath(baseLocation, location), actualResources);
                }
                    if (logger.isDebugEnabled()) {
                    logger.debug("Imported " + importCount + " bean definitions from relative location [" + location +
                    "]");
                    }
            }
            catch (IOException ex) {
           		 getReaderContext().error("Failed to resolve current resource location", ele, ex);
            }
            catch (BeanDefinitionStoreException ex) {
            	getReaderContext().error("Failed to import bean definitions from relative location [" + location + "]",
            ele, ex);
            }
            }
    Resource[] actResArray = actualResources.toArray(new Resource[actualResources.size()]);
    //在解析完<Import>元素之后，发送容器导入其他资源处理完成事件
    getReaderContext().fireImportProcessed(location, actResArray, extractSource(ele));
}
```

对于`<Alias>`元素节点的处理方法`processAliasRegistration`。

```java
protected void processAliasRegistration(Element ele) {
    //获取<Alias>别名元素中 name 的属性值
    String name = ele.getAttribute(NAME_ATTRIBUTE);
    //获取<Alias>别名元素中 alias 的属性值
    String alias = ele.getAttribute(ALIAS_ATTRIBUTE);
    boolean valid = true;
    //<alias>别名元素的 name 属性值为空
    if (!StringUtils.hasText(name)) {
        getReaderContext().error("Name must not be empty", ele);
        valid = false;
    }
    //<alias>别名元素的 alias 属性值为空
    if (!StringUtils.hasText(alias)) {
        getReaderContext().error("Alias must not be empty", ele);
        valid = false;
    }
    if (valid) {
        try {
            //向容器的资源读入器注册别名
            getReaderContext().getRegistry().registerAlias(name, alias);
        }
        catch (Exception ex) {
            getReaderContext().error("Failed to register alias '" + alias +
            "' for bean with name '" + name + "'", ele, ex);
        }
    //在解析完<Alias>元素之后，发送容器别名处理完成事件
    getReaderContext().fireAliasRegistered(name, alias, extractSource(ele));
    }
}
```

对`<bean>`的解析`processBeanDefinition`方法。

```java
//解析 Bean 定义资源 Document 对象的普通元素
protected void processBeanDefinition(Element ele, BeanDefinitionParserDelegate delegate) {
    BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele);
    // BeanDefinitionHolder 是对 BeanDefinition 的封装，即 Bean 定义的封装类
    //对 Document 对象中<Bean>元素的解析由 BeanDefinitionParserDelegate 实现
    // BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele);
    if (bdHolder != null) {
        bdHolder = delegate.decorateBeanDefinitionIfRequired(ele, bdHolder);
        try {
            //向 Spring IOC 容器注册解析得到的 Bean 定义，这是 Bean 定义向 IOC 容器注册的入口
            BeanDefinitionReaderUtils.registerBeanDefinition(bdHolder, getReaderContext().getRegistry());
        }
        catch (BeanDefinitionStoreException ex) {
            getReaderContext().error("Failed to register bean definition with name '" +
            bdHolder.getBeanName() + "'", ele, ex);
        }
        //在完成向 Spring IOC 容器注册解析得到的 Bean 定义之后，发送注册事件
        getReaderContext().fireComponentRegistered(new BeanComponentDefinition(bdHolder));
    }
}
```

其中通过`BeanDefinitionParserDelegate`中的`parseBeanDefinitionElement`方法来进行处理。

```java
@Nullable
public BeanDefinitionHolder parseBeanDefinitionElement(Element ele) {
	return parseBeanDefinitionElement(ele, null);
}
...
 @Nullable
public BeanDefinitionHolder parseBeanDefinitionElement(Element ele, @Nullable BeanDefinition containingBean) {
		String id = ele.getAttribute(ID_ATTRIBUTE);
		String nameAttr = ele.getAttribute(NAME_ATTRIBUTE);

		List<String> aliases = new ArrayList<>();
		if (StringUtils.hasLength(nameAttr)) {
			String[] nameArr = StringUtils.tokenizeToStringArray(nameAttr, MULTI_VALUE_ATTRIBUTE_DELIMITERS);
			aliases.addAll(Arrays.asList(nameArr));
		}

		String beanName = id;
		if (!StringUtils.hasText(beanName) && !aliases.isEmpty()) {
			beanName = aliases.remove(0);
			if (logger.isDebugEnabled()) {
				logger.debug("No XML 'id' specified - using '" + beanName +
						"' as bean name and " + aliases + " as aliases");
			}
		}

		if (containingBean == null) {
			checkNameUniqueness(beanName, aliases, ele);
		}

		AbstractBeanDefinition beanDefinition = parseBeanDefinitionElement(ele, beanName, containingBean);
		if (beanDefinition != null) {
			if (!StringUtils.hasText(beanName)) {
				try {
					if (containingBean != null) {
						beanName = BeanDefinitionReaderUtils.generateBeanName(
								beanDefinition, this.readerContext.getRegistry(), true);
					}
					else {
						beanName = this.readerContext.generateBeanName(beanDefinition);
						// Register an alias for the plain bean class name, if still possible,
						// if the generator returned the class name plus a suffix.
						// This is expected for Spring 1.2/2.0 backwards compatibility.
						String beanClassName = beanDefinition.getBeanClassName();
						if (beanClassName != null &&
								beanName.startsWith(beanClassName) && beanName.length() > beanClassName.length() &&
								!this.readerContext.getRegistry().isBeanNameInUse(beanClassName)) {
							aliases.add(beanClassName);
						}
					}
					if (logger.isDebugEnabled()) {
						logger.debug("Neither XML 'id' nor 'name' specified - " +
								"using generated bean name [" + beanName + "]");
					}
				}
				catch (Exception ex) {
					error(ex.getMessage(), ele);
					return null;
				}
			}
			String[] aliasesArray = StringUtils.toStringArray(aliases);
			return new BeanDefinitionHolder(beanDefinition, beanName, aliasesArray);
		}

		return null;
	}
```

其中通过`parseBeanDefinitionElement`开始进行`BeanDefinition`创建工作。

```java
@Nullable
	public AbstractBeanDefinition parseBeanDefinitionElement(
			Element ele, String beanName, @Nullable BeanDefinition containingBean) {

		this.parseState.push(new BeanEntry(beanName));

		String className = null;
		if (ele.hasAttribute(CLASS_ATTRIBUTE)) {
			className = ele.getAttribute(CLASS_ATTRIBUTE).trim();
		}
		String parent = null;
		if (ele.hasAttribute(PARENT_ATTRIBUTE)) {
			parent = ele.getAttribute(PARENT_ATTRIBUTE);
		}
		try {
			AbstractBeanDefinition bd = createBeanDefinition(className, parent);

			parseBeanDefinitionAttributes(ele, beanName, containingBean, bd);
			bd.setDescription(DomUtils.getChildElementValueByTagName(ele, DESCRIPTION_ELEMENT));

			parseMetaElements(ele, bd);
			parseLookupOverrideSubElements(ele, bd.getMethodOverrides());
			parseReplacedMethodSubElements(ele, bd.getMethodOverrides());

			parseConstructorArgElements(ele, bd);
			parsePropertyElements(ele, bd);
			parseQualifierElements(ele, bd);

			bd.setResource(this.readerContext.getResource());
			bd.setSource(extractSource(ele));

			return bd;
		}
	...
	}
```

通过`createBeanDefinition`进行创建操作。

```java
protected AbstractBeanDefinition createBeanDefinition(@Nullable String className, @Nullable String parentName)
			throws ClassNotFoundException {

		return BeanDefinitionReaderUtils.createBeanDefinition(
				parentName, className, this.readerContext.getBeanClassLoader());
	} 
```

调用`BeanDefinitionReaderUtils`的`createBeanDefinition`方法进行创建。

```java
public static AbstractBeanDefinition createBeanDefinition(
			@Nullable String parentName, @Nullable String className, @Nullable ClassLoader classLoader) throws ClassNotFoundException {

		GenericBeanDefinition bd = new GenericBeanDefinition();
		bd.setParentName(parentName);
		if (className != null) {
			if (classLoader != null) {
				bd.setBeanClass(ClassUtils.forName(className, classLoader));
			}
			else {
				bd.setBeanClassName(className);
			}
		}
		return bd;
	}
```

实例一个`GenericBeanDefinition`的`beanDefinition`对象。回到`parseBeanDefinitionElement`来，创建`beanDefinition`后开始对`Bean`中`<property>`,`<list>`等元素进行解析。其中`ref` 被封装为指向依赖对象一个引用。`value` 配置都会封装成一个字符串类型的对象。最后将所有Bean信息赋值到`BeanDefinition`中。至此载入工作结束。

#### 注册

当我们完成对`BeanDefinition`载入工作后，会将`BeanDefinition`再装配到`BeanDefinitionHolder`中。我们回到`DefaultBeanDefinitionDocumentReader`中，将继续通过`BeanDefinitionReaderUtils`中的`registerBeanDefinition`方法完成注册工作。

```java
public static void registerBeanDefinition(
			BeanDefinitionHolder definitionHolder, BeanDefinitionRegistry registry)
			throws BeanDefinitionStoreException {

		// Register bean definition under primary name.
		String beanName = definitionHolder.getBeanName();
		registry.registerBeanDefinition(beanName, definitionHolder.getBeanDefinition());

		// Register aliases for bean name, if any.
		String[] aliases = definitionHolder.getAliases();
		if (aliases != null) {
			for (String alias : aliases) {
				registry.registerAlias(beanName, alias);
			}
		}
	}
```

这里的`reqistry`具体调用的是`DefaultListableBeanFactory`，什么时候进行的赋值呢？在我们创建`XmlBeanDefinitionReader`的时候，通过实例化调用，进行了传参。

```java
protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
		// Create a new XmlBeanDefinitionReader for the given BeanFactory.
   XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);
    ...
}
```

可以进一步看下这个过程，传进去的就是`DefaultListableBeanFactory`。

```java
public XmlBeanDefinitionReader(BeanDefinitionRegistry registry) {
		super(registry);
	}
```

调用父类构造函数，并且将参数传递过去。父类是`AbstractBeanDefinitionReader`。

```java
protected AbstractBeanDefinitionReader(BeanDefinitionRegistry registry) {
		Assert.notNull(registry, "BeanDefinitionRegistry must not be null");
		this.registry = registry;

		// Determine ResourceLoader to use.
		if (this.registry instanceof ResourceLoader) {
			this.resourceLoader = (ResourceLoader) this.registry;
		}
		else {
			this.resourceLoader = new PathMatchingResourcePatternResolver();
		}

		// Inherit Environment if possible
		if (this.registry instanceof EnvironmentCapable) {
			this.environment = ((EnvironmentCapable) this.registry).getEnvironment();
		}
		else {
			this.environment = new StandardEnvironment();
		}
	}
```

在这里面将`DefaultListableBeanFactory`赋值给了`registry`变量。

所以继续回到上面进入`DefaultListableBeanFactory`中的`registerBeanDefinition`方法。

```java
@Override
	public void registerBeanDefinition(String beanName, BeanDefinition beanDefinition)
			throws BeanDefinitionStoreException {

		Assert.hasText(beanName, "Bean name must not be empty");
		Assert.notNull(beanDefinition, "BeanDefinition must not be null");

		if (beanDefinition instanceof AbstractBeanDefinition) {
			try {
				((AbstractBeanDefinition) beanDefinition).validate();
			}
			catch (BeanDefinitionValidationException ex) {
				throw new BeanDefinitionStoreException(beanDefinition.getResourceDescription(), beanName,
						"Validation of bean definition failed", ex);
			}
		}

		BeanDefinition oldBeanDefinition;

		oldBeanDefinition = this.beanDefinitionMap.get(beanName);
		if (oldBeanDefinition != null) {
			if (!isAllowBeanDefinitionOverriding()) {
				throw new BeanDefinitionStoreException(beanDefinition.getResourceDescription(), beanName,
						"Cannot register bean definition [" + beanDefinition + "] for bean '" + beanName +
						"': There is already [" + oldBeanDefinition + "] bound.");
			}
			else if (oldBeanDefinition.getRole() < beanDefinition.getRole()) {
				// e.g. was ROLE_APPLICATION, now overriding with ROLE_SUPPORT or ROLE_INFRASTRUCTURE
				if (this.logger.isWarnEnabled()) {
					this.logger.warn("Overriding user-defined bean definition for bean '" + beanName +
							"' with a framework-generated bean definition: replacing [" +
							oldBeanDefinition + "] with [" + beanDefinition + "]");
				}
			}
			else if (!beanDefinition.equals(oldBeanDefinition)) {
				if (this.logger.isInfoEnabled()) {
					this.logger.info("Overriding bean definition for bean '" + beanName +
							"' with a different definition: replacing [" + oldBeanDefinition +
							"] with [" + beanDefinition + "]");
				}
			}
			else {
				if (this.logger.isDebugEnabled()) {
					this.logger.debug("Overriding bean definition for bean '" + beanName +
							"' with an equivalent definition: replacing [" + oldBeanDefinition +
							"] with [" + beanDefinition + "]");
				}
			}
			this.beanDefinitionMap.put(beanName, beanDefinition);
		}
		else {
			if (hasBeanCreationStarted()) {
				// Cannot modify startup-time collection elements anymore (for stable iteration)
				synchronized (this.beanDefinitionMap) {
					this.beanDefinitionMap.put(beanName, beanDefinition);
					List<String> updatedDefinitions = new ArrayList<>(this.beanDefinitionNames.size() + 1);
					updatedDefinitions.addAll(this.beanDefinitionNames);
					updatedDefinitions.add(beanName);
					this.beanDefinitionNames = updatedDefinitions;
					if (this.manualSingletonNames.contains(beanName)) {
						Set<String> updatedSingletons = new LinkedHashSet<>(this.manualSingletonNames);
						updatedSingletons.remove(beanName);
						this.manualSingletonNames = updatedSingletons;
					}
				}
			}
			else {
				// Still in startup registration phase
				this.beanDefinitionMap.put(beanName, beanDefinition);
				this.beanDefinitionNames.add(beanName);
				this.manualSingletonNames.remove(beanName);
			}
			this.frozenBeanDefinitionNames = null;
		}

		if (oldBeanDefinition != null || containsSingleton(beanName)) {
			resetBeanDefinition(beanName);
		}
	}
```

这里面最主要做的工作就是`this.beanDefinitionMap.put(beanName, beanDefinition);`

将`beanDefinition`注册到IOC容器中，也就是`private final Map<String, BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<>(256);`变量中。至此整个初始化工作完成，当然还有一些事件等等未进行跟踪查看。

#### 总结

* **定位**  
  * `AbstractApplicationContext` 中变量`resourcePatternResolver`赋值`new PathMatchingResourcePatternResolver`。
  * `PathMatchingResourcePatternResolver`中属性`resourceLoader`赋值`AbstractApplicationContext`。（资源加载器）
  * `AbstractRefreshableConfigApplicationContext`中属性`configLocations`存储配置文件信息。
* **载入** 
  * 创建`DefaultListableBeanFactory`容器；
  * 创建`XmlBeanDefinitionReader`读取器；
  * 调用`XmlBeanDefinitionReader`读取器 `loadBeanDefinitions`方法；
  * 获取`AbstractApplicationContext`资源加载器，并通过`getResources`获取资源；
  * 将资源转为`Document`对象；
  * 创建`BeanDefinitionDocumentReader`读取器；
  * 调用 `BeanDefinitionDocumentReader`读取器`registerBeanDefinitions`方法；
  * 通过`BeanDefinitionParserDelegate`解析`bean`的定义信息，不同元素节点不同处理；
  * 创建`BeanDefinition`,将`Bean`内容放入`BeanDefinition`，再封装进`BeanDefinitionHolder`；
* **注册**
  * 通过`BeanDefinitionReaderUtils`中`registerBeanDefinition`开始注册；
  * 执行`DefaultListableBeanFactory`中`registerBeanDefinition`注册；
  * 将`BeanDefinition`添加到IOC容器`beanDefinitionMap`中；

### 关于其他入口

`FileSystemXmlApplicationContext`与`ClasspathXmlApplicationContext`主要是对文件（XML)类的初始化。

`AnnotationConfigApplicationContext`是基于注解进行加载Spring的上下文。

## IOC容器 依赖注入（DI） 

初始化过程只是将bean的信息装载到IOC容器中，并没有对所有管理的Bean进行依赖注入，所以当前还无法使用。依赖注入包括两种情况。

### 配置`lazy-init`实现预实例

当`Bean`定义资源的`<Bean>`元素中配置了`lazy-init`属性时，容器将会在初始化的时候对所配置的`Bean`
进行预实例化，`Bean` 的依赖注入在容器初始化的时候就已经完成。这样，当应用程序第一次向容器索
取被管理的 `Bean` 时，就不用再初始化和对 `Bean` 进行依赖注入了，直接从容器中获取已经完成依赖注
入的现成 `Bean`，可以提高应用第一次向容器获取 `Bean` 的性能。

#### 源码流程

上面讲到初始化通过`AbstractApplicationContext`中的`refresh`方法。其中又通过`obtainFreshBeanFactory`方法完成了载入与注册的功能。而在之后的`finishBeanFactoryInitialization`方法就是除了配置`lazy-init`属性的`bean`的依赖注入操作。

```java
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
		// Initialize conversion service for this context.
		if (beanFactory.containsBean(CONVERSION_SERVICE_BEAN_NAME) &&
				beanFactory.isTypeMatch(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class)) {
			beanFactory.setConversionService(
					beanFactory.getBean(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class));
		}

		// Register a default embedded value resolver if no bean post-processor
		// (such as a PropertyPlaceholderConfigurer bean) registered any before:
		// at this point, primarily for resolution in annotation attribute values.
		if (!beanFactory.hasEmbeddedValueResolver()) {
			beanFactory.addEmbeddedValueResolver(strVal -> getEnvironment().resolvePlaceholders(strVal));
		}

		// Initialize LoadTimeWeaverAware beans early to allow for registering their transformers early.
		String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
		for (String weaverAwareName : weaverAwareNames) {
			getBean(weaverAwareName);
		}

		// Stop using the temporary ClassLoader for type matching.
		beanFactory.setTempClassLoader(null);

		// Allow for caching all bean definition metadata, not expecting further changes.
		beanFactory.freezeConfiguration();

		// Instantiate all remaining (non-lazy-init) singletons.
		beanFactory.preInstantiateSingletons();
	}
```

具体通过调用`DefaultListableBeanFactory`中`preInstantiateSingletons`方法开始对Bean进行预实例化处理。

```java
@Override
	public void preInstantiateSingletons() throws BeansException {
		if (this.logger.isDebugEnabled()) {
			this.logger.debug("Pre-instantiating singletons in " + this);
		}
		// Iterate over a copy to allow for init methods which in turn register new bean definitions.
		// While this may not be part of the regular factory bootstrap, it does otherwise work fine.
		List<String> beanNames = new ArrayList<>(this.beanDefinitionNames);
		// Trigger initialization of all non-lazy singleton beans...
		for (String beanName : beanNames) {
			RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);
			if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
				if (isFactoryBean(beanName)) {
					Object bean = getBean(FACTORY_BEAN_PREFIX + beanName);
					if (bean instanceof FactoryBean) {
						final FactoryBean<?> factory = (FactoryBean<?>) bean;
						boolean isEagerInit;
						if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
							isEagerInit = AccessController.doPrivileged((PrivilegedAction<Boolean>)
											((SmartFactoryBean<?>) factory)::isEagerInit,
									getAccessControlContext());
						}
						else {
							isEagerInit = (factory instanceof SmartFactoryBean &&
									((SmartFactoryBean<?>) factory).isEagerInit());
						}
						if (isEagerInit) {
							getBean(beanName);
						}
					}
				}
				else {
					getBean(beanName);
				}
			}
		}
		// Trigger post-initialization callback for all applicable beans...
		for (String beanName : beanNames) {
			Object singletonInstance = getSingleton(beanName);
			if (singletonInstance instanceof SmartInitializingSingleton) {
				final SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
				if (System.getSecurityManager() != null) {
					AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
						smartSingleton.afterSingletonsInstantiated();
						return null;
					}, getAccessControlContext());
				}
				else {
					smartSingleton.afterSingletonsInstantiated();
				}
			}
		}
	}
```

如果Bean设置了`lazy-init`属性，则会调用`getBean(beanName)`方法进行依赖注入。所以配置`lazy-init`属性的方式只不过是系统会做第一次`getBean`操作达到依赖注入的效果。

### 通过第一次`getBean`

当用户第一次通过`getBean`方法向`IOC`容器索要`Bean`时,触发该`bean`的依赖注入。

