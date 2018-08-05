# Spring IOC

>在Spring应用中，所有的beans生存于Spring容器中，Spring容器负责创建，装配，管理它们的整个生命周期，从生存到死亡，这个容器称为IOC容器。

Spring容器并不是只有一个，可以分为二种类型。

### BeanFactory

  `org.springframework.beans.factory.BeanFactory` 是最简单的容器，提供基本的DI支持。

![image](https://github.com/dqsbl2016/study/blob/master/Spring/xy/img/1532489938612.jpg)


>其中 BeanFactory 作为最顶层的一个接口类，它定义了 IOC 容器的基本功能规范，BeanFactory 有三个子类：ListableBeanFactory、HierarchicalBeanFactory 和 AutowireCapableBeanFactory。
>但是从上图中我们可以发现最终的默认实现类是DefaultListableBeanFactory，他实现了所有的接口。那为何要定义这么多层次的接口呢？查阅这些接口的源码和说明>发现，每个接口都有他使用的场合，它主要是为了区分在Spring内部在操作过程中对象的传递和转化过程中，对对象的数据访问所做的限制。例如ListableBeanFactory接口表示这些Bean 是集合列表的，而HierarchicalBeanFactory表示的是这些Bean是有继承关系的，也就是每个Bean有可能有父Bean。AutowireCapableBeanFactory接口定义Bean的自动装配规则。这四个接口共同定义了Bean的集合、Bean之间的关系、以及Bean行为。


### ApplicationContext

`org.springframework.context.ApplicationContext`基于BeanFactory构建，提供应用框架级别的服务，例如从属性文件解析文本信息以及发布应用事件给事件监听者。

![image](https://github.com/dqsbl2016/study/blob/master/Spring/xy/img/1532494390919.jpg)


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

##### 设置资源加载器

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

##### 父类调用的关系

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

##### 记录资源文件

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

##### 创建IOC容器

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

>这里说明下为什么`loadBeanDefinitions(beanFactory)`会掉用`AbstractXmlApplicationContext`中的`loadBeanDefinitions`实现呢？
>
>因为程序入口是`FileSystemXmlApplicationContext`，通过上面的继承关系可以了解到`FileSystemXmlApplicationContext`->`AbstractXmlApplicationContext`->`AbstractRefreshableConfigApplicationContext`->`AbstractRefreshableApplicationContext`,所以在`AbstractRefreshableApplicationContext`中调用`loadBeanDefinitions`方法时（在`AbstractRefreshableApplicationContext`中定义的`loadBeanDefinitions`只是个抽象方法），会逐级向子类中寻找实现，所以找到了`AbstractXmlApplicationContext`中的实现。这个就是模板设计模式，父类中定义方法，子类中进行实现，不同子类可以进行不同业务的实现处理。

##### 创建`XmlBeanDefinitionReader`对资源读取

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

##### 将资源转换为`Document`对象

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

##### 创建`BeanDefinitionDocumentReader`对`Document`对象解析

```java
	public int registerBeanDefinitions(Document doc, Resource resource) throws BeanDefinitionStoreException {
		BeanDefinitionDocumentReader documentReader = createBeanDefinitionDocumentReader();
		int countBefore = getRegistry().getBeanDefinitionCount();
		documentReader.registerBeanDefinitions(doc, createReaderContext(resource));
		return getRegistry().getBeanDefinitionCount() - countBefore;
	}
```

通过`createBeanDefinitionDocumentReader`创建一个`BeanDefinitionDocumentReader`读取器，返回的是个`DefaultBeanDefinitionDocumentReader`对象。`BeanDefinitionDocumentReader`读取器主要实现按Spring的bean规则对`Document`对象进行解析。这里会调用`DefaultBeanDefinitionDocumentReader`中的`registerBeanDefinitions`方法。

##### 委托`BeanDefinitionParserDelegate`对`Element`进行解析，并创建`beanDefinition`存储`Bean`信息

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

###### Spring默认`XML`命名空间的`bean`标签解析

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

`<import>`标签主要是用于当Spring配置文件过于庞大时，进行分模块创建配置文件时使用。

```XML
<import resource="classpath:/dubbo.xml" />
<import resource="${datasource.url}" />
```

所以上面方法主要的处理思路主要包括：

* 获取`resource`属性对应的路径；
* 解析路径中的系统属性，格式如`classpath:/dubbo.xml`，`${datasource.url}`;
* 判断`location`是绝对路径还是相对路径；
* 如果是绝对路径则递归调用`bean`的解析过程，进行另一次的解析；
* 如果是相对路径则计算出绝对路径并进行解析；
* 通知监听器，解析完成；

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

`<alias>`标签是对`bean`别名的处理。具体应用方式有多种。

```xml
<bean id="testBean" name="testBean,testBean2" class="com.test" />
或
<bean  id="testBean"  class="com.test"/>
<alias name="testBean" alias="testBean,testBean2"/>
```

上面方法具体处理方式就是将别名与`beanname`组成一对注册至`registy`中。

而对`<beans>`标签的处理就是递归调用`<bean>`的处理过程。

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

其中通过`BeanDefinitionParserDelegate`中的`parseBeanDefinitionElement`方法来进行元素解析。

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

实例一个`GenericBeanDefinition`的`beanDefinition`对象后，再回到`parseBeanDefinitionElement`中。当获得到一个`beanDefinition`对象后，继续下一步`parseBeanDefinitionAttributes`。这个方法中解析了各种属性。

```java
public AbstractBeanDefinition parseBeanDefinitionAttributes(Element ele, String beanName,
			@Nullable BeanDefinition containingBean, AbstractBeanDefinition bd) {

		if (ele.hasAttribute(SINGLETON_ATTRIBUTE)) {
			error("Old 1.x 'singleton' attribute in use - upgrade to 'scope' declaration", ele);
		}
		else if (ele.hasAttribute(SCOPE_ATTRIBUTE)) {
			bd.setScope(ele.getAttribute(SCOPE_ATTRIBUTE));
		}
		else if (containingBean != null) {
			// Take default from containing bean in case of an inner bean definition.
			bd.setScope(containingBean.getScope());
		}

		if (ele.hasAttribute(ABSTRACT_ATTRIBUTE)) {
			bd.setAbstract(TRUE_VALUE.equals(ele.getAttribute(ABSTRACT_ATTRIBUTE)));
		}

		String lazyInit = ele.getAttribute(LAZY_INIT_ATTRIBUTE);
		if (DEFAULT_VALUE.equals(lazyInit)) {
			lazyInit = this.defaults.getLazyInit();
		}
		bd.setLazyInit(TRUE_VALUE.equals(lazyInit));

		String autowire = ele.getAttribute(AUTOWIRE_ATTRIBUTE);
		bd.setAutowireMode(getAutowireMode(autowire));

		if (ele.hasAttribute(DEPENDS_ON_ATTRIBUTE)) {
			String dependsOn = ele.getAttribute(DEPENDS_ON_ATTRIBUTE);
			bd.setDependsOn(StringUtils.tokenizeToStringArray(dependsOn, MULTI_VALUE_ATTRIBUTE_DELIMITERS));
		}

		String autowireCandidate = ele.getAttribute(AUTOWIRE_CANDIDATE_ATTRIBUTE);
		if ("".equals(autowireCandidate) || DEFAULT_VALUE.equals(autowireCandidate)) {
			String candidatePattern = this.defaults.getAutowireCandidates();
			if (candidatePattern != null) {
				String[] patterns = StringUtils.commaDelimitedListToStringArray(candidatePattern);
				bd.setAutowireCandidate(PatternMatchUtils.simpleMatch(patterns, beanName));
			}
		}
		else {
			bd.setAutowireCandidate(TRUE_VALUE.equals(autowireCandidate));
		}

		if (ele.hasAttribute(PRIMARY_ATTRIBUTE)) {
			bd.setPrimary(TRUE_VALUE.equals(ele.getAttribute(PRIMARY_ATTRIBUTE)));
		}

		if (ele.hasAttribute(INIT_METHOD_ATTRIBUTE)) {
			String initMethodName = ele.getAttribute(INIT_METHOD_ATTRIBUTE);
			bd.setInitMethodName(initMethodName);
		}
		else if (this.defaults.getInitMethod() != null) {
			bd.setInitMethodName(this.defaults.getInitMethod());
			bd.setEnforceInitMethod(false);
		}

		if (ele.hasAttribute(DESTROY_METHOD_ATTRIBUTE)) {
			String destroyMethodName = ele.getAttribute(DESTROY_METHOD_ATTRIBUTE);
			bd.setDestroyMethodName(destroyMethodName);
		}
		else if (this.defaults.getDestroyMethod() != null) {
			bd.setDestroyMethodName(this.defaults.getDestroyMethod());
			bd.setEnforceDestroyMethod(false);
		}

		if (ele.hasAttribute(FACTORY_METHOD_ATTRIBUTE)) {
			bd.setFactoryMethodName(ele.getAttribute(FACTORY_METHOD_ATTRIBUTE));
		}
		if (ele.hasAttribute(FACTORY_BEAN_ATTRIBUTE)) {
			bd.setFactoryBeanName(ele.getAttribute(FACTORY_BEAN_ATTRIBUTE));
		}

		return bd;
	}
```

其中包括`scope属性`，`singleton属性`，`abstract属性`，`lazy-init属性`，`autowire属性`，`dependency-check属性`，`depends-on属性`,`autowire-candidate属性`，`primary属性`，`init-method属性`，`destroy-method属性`，`factory-method属性`,`factory-bean属性`的解析。

然后通过`parseMetaElements`方法开始对`meta`子元素的解析。

```java
public void parseMetaElements(Element ele, BeanMetadataAttributeAccessor attributeAccessor) {
		NodeList nl = ele.getChildNodes();
		for (int i = 0; i < nl.getLength(); i++) {
			Node node = nl.item(i);
			if (isCandidateElement(node) && nodeNameEquals(node, META_ELEMENT)) {
				Element metaElement = (Element) node;
				String key = metaElement.getAttribute(KEY_ATTRIBUTE);
				String value = metaElement.getAttribute(VALUE_ATTRIBUTE);
				BeanMetadataAttribute attribute = new BeanMetadataAttribute(key, value);
				attribute.setSource(extractSource(metaElement));
				attributeAccessor.addMetadataAttribute(attribute);
			}
		}
	}
```

`meta`元素的使用方式

```xml
<bean id = "myBean" class="com.test">
	<meta key="testStr" value="aaa" />
</bean>
```

解析读取到`key`,`value`后，通过构造函数`BeanMetadataAttribute`放入这对象内。最后放入`BeanMetadataAttributeAccessor`对象中。这里`BeanMetadataAttributeAccessor`就是`beandefinition`对象，他们存在继承关系。

后面继续解析`<lookup-method>`，`<replaced-method>`，`constructor-arg`，`property`，`qualifier`子元素的解析，这里先不做说明。

所以解析之后（会将解析内容存入`bendefinition`中），会再封装到`beandefinitionHodler`中，我们再回到`parseBeanDefinitionElement`方法中准备调用注册方法。

###### 用户自定义命名空间的`bean`标签解析

在`DefaultBeanDefinitionDocumentReader`中`parseBeanDefinitions`解析`bean`中通过`delegate.parseCustomElement(ele)`对用户自定义命名空间的`bean`标签进行解析。

首先先了解下Spring的自定义`XML`标签。  ***此处待加入链接***

具体`BeanDefinitionParserDelegate`中逻辑。

```java
@Nullable
	public BeanDefinition parseCustomElement(Element ele) {
		return parseCustomElement(ele, null);
	}
...
  @Nullable
	public BeanDefinition parseCustomElement(Element ele, @Nullable BeanDefinition containingBd) {
		String namespaceUri = getNamespaceURI(ele);
		if (namespaceUri == null) {
			return null;
		}
		NamespaceHandler handler = this.readerContext.getNamespaceHandlerResolver().resolve(namespaceUri);
		if (handler == null) {
			error("Unable to locate Spring NamespaceHandler for XML schema namespace [" + namespaceUri + "]", ele);
			return null;
		}
		return handler.parse(ele, new ParserContext(this.readerContext, this, containingBd));
	}
```

其中具体的思路为根据对应的`bean`获取对应的命名空间，根据命名空间解析对应的处理器，然后根据自定义处理器进行解析。具体实现先通过`getNamespaceURI(ele)`获取命名空间。

```java
@Nullable
	public String getNamespaceURI(Node node) {
		return node.getNamespaceURI();
	}
```

获取到命名空间后，就可以进行`namespaceHandler`的提取了，通过`this.readerContext.getNamespaceHandlerResolver().resolve(namespaceUri)`会调用`DefaultNamespaceHandlerResolver`中的`resolve`方法。

```java
@Override
	@Nullable
	public NamespaceHandler resolve(String namespaceUri) {
		Map<String, Object> handlerMappings = getHandlerMappings();
		Object handlerOrClassName = handlerMappings.get(namespaceUri);
		if (handlerOrClassName == null) {
			return null;
		}
		else if (handlerOrClassName instanceof NamespaceHandler) {
			return (NamespaceHandler) handlerOrClassName;
		}
		else {
			String className = (String) handlerOrClassName;
			try {
				Class<?> handlerClass = ClassUtils.forName(className, this.classLoader);
				if (!NamespaceHandler.class.isAssignableFrom(handlerClass)) {
					throw new FatalBeanException("Class [" + className + "] for namespace [" + namespaceUri +
							"] does not implement the [" + NamespaceHandler.class.getName() + "] interface");
				}
				NamespaceHandler namespaceHandler = (NamespaceHandler) BeanUtils.instantiateClass(handlerClass);
				namespaceHandler.init();
				handlerMappings.put(namespaceUri, namespaceHandler);
				return namespaceHandler;
			}
			catch (ClassNotFoundException ex) {
				throw new FatalBeanException("Could not find NamespaceHandler class [" + className +
						"] for namespace [" + namespaceUri + "]", ex);
			}
			catch (LinkageError err) {
				throw new FatalBeanException("Unresolvable class definition for NamespaceHandler class [" +
						className + "] for namespace [" + namespaceUri + "]", err);
			}
		}
	}
```

先通过`getHandlerMappings` 读取`Spring.handlers`配置文件并将配置文件放到缓存`map`中。  然后获取自定义`Namespacehandler`后进行初始化并放入到`handlerMappings`中。

再通过上面的方法中`handler.parse(ele, new ParserContext(this.readerContext, this, containingBd))`进行解析。此时的`handler`已经被实例我们自定义的``Namespacehandler``对象，但是我们自定义处理器中并没有实现`parse`方法，所以会执行父类`NamespaceHandlerSupport`中的`parse`方法。

```java
@Override
	@Nullable
	public BeanDefinition parse(Element element, ParserContext parserContext) {
		BeanDefinitionParser parser = findParserForElement(element, parserContext);
		return (parser != null ? parser.parse(element, parserContext) : null);
	}
```

这里会通过`findParserForElement`方法先找元素对应的解析器，然后通过调用解析器的`parse`方法进行解析。

```java
@Nullable
	private BeanDefinitionParser findParserForElement(Element element, ParserContext parserContext) {
		String localName = parserContext.getDelegate().getLocalName(element);
		BeanDefinitionParser parser = this.parsers.get(localName);
		if (parser == null) {
			parserContext.getReaderContext().fatal(
					"Cannot locate BeanDefinitionParser for element [" + localName + "]", element);
		}
		return parser;
	}
```

具体可以看父类`AbstractBeanDefinitionParser`中的`parse`实现。

```java
@Override
	@Nullable
	public final BeanDefinition parse(Element element, ParserContext parserContext) {
		AbstractBeanDefinition definition = parseInternal(element, parserContext);
		if (definition != null && !parserContext.isNested()) {
			try {
				String id = resolveId(element, definition, parserContext);
				if (!StringUtils.hasText(id)) {
					parserContext.getReaderContext().error(
							"Id is required for element '" + parserContext.getDelegate().getLocalName(element)
									+ "' when used as a top-level tag", element);
				}
				String[] aliases = null;
				if (shouldParseNameAsAliases()) {
					String name = element.getAttribute(NAME_ATTRIBUTE);
					if (StringUtils.hasLength(name)) {
						aliases = StringUtils.trimArrayElements(StringUtils.commaDelimitedListToStringArray(name));
					}
				}
				BeanDefinitionHolder holder = new BeanDefinitionHolder(definition, id, aliases);
				registerBeanDefinition(holder, parserContext.getRegistry());
				if (shouldFireEvents()) {
					BeanComponentDefinition componentDefinition = new BeanComponentDefinition(holder);
					postProcessComponentDefinition(componentDefinition);
					parserContext.registerComponent(componentDefinition);
				}
			}
			catch (BeanDefinitionStoreException ex) {
				String msg = ex.getMessage();
				parserContext.getReaderContext().error((msg != null ? msg : ex.toString()), element);
				return null;
			}
		}
		return definition;
	}
```

这里的执行过程，依然先创建`beanDefinition`对象。通过`parseInternal`方法。

```java
@Override
	protected final AbstractBeanDefinition parseInternal(Element element, ParserContext parserContext) {
		BeanDefinitionBuilder builder = BeanDefinitionBuilder.genericBeanDefinition();
		String parentName = getParentName(element);
		if (parentName != null) {
			builder.getRawBeanDefinition().setParentName(parentName);
		}
		Class<?> beanClass = getBeanClass(element);
		if (beanClass != null) {
			builder.getRawBeanDefinition().setBeanClass(beanClass);
		}
		else {
			String beanClassName = getBeanClassName(element);
			if (beanClassName != null) {
				builder.getRawBeanDefinition().setBeanClassName(beanClassName);
			}
		}
		builder.getRawBeanDefinition().setSource(parserContext.extractSource(element));
		BeanDefinition containingBd = parserContext.getContainingBeanDefinition();
		if (containingBd != null) {
			// Inner bean definition must receive same scope as containing bean.
			builder.setScope(containingBd.getScope());
		}
		if (parserContext.isDefaultLazyInit()) {
			// Default-lazy-init applies to custom bean definitions as well.
			builder.setLazyInit(true);
		}
		doParse(element, parserContext, builder);
		return builder.getBeanDefinition();
	}
```

对定义的`Bean`做了一系列数据准备，包括`beanClass`，`scope`,`lazyinit`等属性的准备，之后执行`doParse`会通过自定义的子类完成。

至此完成载入工作。

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

### 通过第一次`getBean`完成依赖注入

当用户第一次通过`getBean`方法向`IOC`容器索要`Bean`时,触发该`bean`的依赖注入。

具体通过`AbstractBeanFactory`的`getBean`开始。

```java
@Override
	public Object getBean(String name) throws BeansException {
		return doGetBean(name, null, null, false);
	}
...
    protected <T> T doGetBean(final String name, @Nullable final Class<T> requiredType,
			@Nullable final Object[] args, boolean typeCheckOnly) throws BeansException {
		
    	//提取对应的beanName
		final String beanName = transformedBeanName(name);
		Object bean;

		// Eagerly check singleton cache for manually registered singletons.
         //单例模式的bean只会创建一次，所以先从缓存中获取是否已经创建过
    	//在创建单例bean的时候会存在依赖注入的情况，而创建依赖的时候为了避免循环依赖，
    	//spring创建bean原则是不等到bean创建完成就会将创建bean的objectFactory提早曝光
    	//也就是将objectFactory加入到缓存，一旦下一个bean创建的时候需要依赖上一个bean的时候
    	//直接使用objectFactory
        //直接尝试从缓存或者singletonFactories中的ObjectFactory中获取
		Object sharedInstance = getSingleton(beanName);
		if (sharedInstance != null && args == null) {
			if (logger.isDebugEnabled()) {
				if (isSingletonCurrentlyInCreation(beanName)) {
					logger.debug("Returning eagerly cached instance of singleton bean '" + beanName +
							"' that is not fully initialized yet - a consequence of a circular reference");
				}
				else {
					logger.debug("Returning cached instance of singleton bean '" + beanName + "'");
				}
			}
            //获取给定 Bean 的实例对象，主要是完成 FactoryBean 的相关处理
			//注意：BeanFactory 是管理容器中 Bean 的工厂，而 FactoryBean 是
			//创建创建对象的工厂 Bean，两者之间有区别
            //有时候存在例如BeanFactory的情况并不是直接返回实例本身而是返回指定方法返回的实例
			bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
		}

		else {
			// Fail if we're already creating this bean instance:
			// We're assumably within a circular reference.
            //缓存没有正在创建的单例模式 Bean
			//缓存中已经有已经创建的原型模式 Bean
			//但是由于循环引用的问题导致实例化对象失败
            //只有单例情况下才会尝试解决循环依赖。
            // 这个原型模式下，如果出现循环依赖则抛出异常
            // 循环依赖是 A中有B的属性，B中有A的属性
			if (isPrototypeCurrentlyInCreation(beanName)) {
				throw new BeanCurrentlyInCreationException(beanName);
			}

			// Check if bean definition exists in this factory.
            //对 IOC 容器中是否存在指定名称的 BeanDefinition 进行检查，首先检查是否
			//能在当前的 BeanFactory 中获取的所需要的 Bean，如果不能则委托当前容器
			//的父级容器去查找，如果还是找不到则沿着容器的继承体系向父级容器查找
			BeanFactory parentBeanFactory = getParentBeanFactory();
            //当前容器的父级容器存在，且当前容器中不存在指定名称的 Bean
			if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
				// Not found -> check parent.
                //解析指定 Bean 名称的原始名称
				String nameToLookup = originalBeanName(name);
				if (parentBeanFactory instanceof AbstractBeanFactory) {
					return ((AbstractBeanFactory) parentBeanFactory).doGetBean(
							nameToLookup, requiredType, args, typeCheckOnly);
				}
				else if (args != null) {
					// Delegation to parent with explicit args.
                    //委派父级容器根据指定名称和显式的参数查找
					return (T) parentBeanFactory.getBean(nameToLookup, args);
				}
				else {
					// No args -> delegate to standard getBean method.
                    //委派父级容器根据指定名称和类型查找
					return parentBeanFactory.getBean(nameToLookup, requiredType);
				}
			}
			//创建的 Bean 是否需要进行类型验证，一般不需要
			if (!typeCheckOnly) {
                //向容器标记指定的 Bean 已经被创建
				markBeanAsCreated(beanName);
			}

			try {
                //根据指定 Bean 名称获取其父级的 Bean 定义
				 //主要解决 Bean 继承时子类合并父类公共属性问题
				final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
				checkMergedBeanDefinition(mbd, beanName, args);

				// Guarantee initialization of beans that the current bean depends on.
                //获取当前 Bean 所有依赖 Bean 的名称
				String[] dependsOn = mbd.getDependsOn();
                //如果当前 Bean 有依赖 Bean
				if (dependsOn != null) {
					for (String dep : dependsOn) {
						if (isDependent(beanName, dep)) {
							throw new BeanCreationException(mbd.getResourceDescription(), beanName,
									"Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
						}
                        //递归调用 getBean 方法，获取当前 Bean 的依赖 Bean
						registerDependentBean(dep, beanName);
						try {
                            //把被依赖 Bean 注册给当前依赖的 Bean
							getBean(dep);
						}
						catch (NoSuchBeanDefinitionException ex) {
							throw new BeanCreationException(mbd.getResourceDescription(), beanName,
									"'" + beanName + "' depends on missing bean '" + dep + "'", ex);
						}
					}
				}

				// Create bean instance.
                //创建单例模式 Bean 的实例对象
				if (mbd.isSingleton()) {
                    //这里使用了一个匿名内部类，创建 Bean 实例对象，并且注册给所依赖的对象
					sharedInstance = getSingleton(beanName, () -> {
						try {
							//主线进入 创建bean
                            //创建一个指定 Bean 实例对象，如果有父级继承，则合并子类和父类的定义
							return createBean(beanName, mbd, args);
						}
						catch (BeansException ex) {
							// Explicitly remove instance from singleton cache: It might have been put there
							// eagerly by the creation process, to allow for circular reference resolution.
							// Also remove any beans that received a temporary reference to the bean.
                            //显式地从容器单例模式 Bean 缓存中清除实例对象
							destroySingleton(beanName);
							throw ex;
						}
					});
                    //获取给定 Bean 的实例对象
					bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
				}

                //IOC 容器创建原型模式 Bean 实例对象
				else if (mbd.isPrototype()) {
					// It's a prototype -> create a new instance.
                    //原型模式(Prototype)是每次都会创建一个新的对象
					Object prototypeInstance = null;
					try {
                         //回调 beforePrototypeCreation 方法，默认的功能是注册当前创建的原型对象
						beforePrototypeCreation(beanName);
                        //创建指定 Bean 对象实例
						prototypeInstance = createBean(beanName, mbd, args);
					}
					finally {
                        //回调 afterPrototypeCreation 方法，默认的功能告诉 IOC 容器指定 Bean 的原型对象不再创建
						afterPrototypeCreation(beanName);
					}
                    //获取给定 Bean 的实例对象
					bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
				}
                //要创建的 Bean 既不是单例模式，也不是原型模式，则根据 Bean 定义资源中
                //配置的生命周期范围，选择实例化 Bean 的合适方法，这种在 Web 应用程序中
                //比较常用，如：request、session、application 等生命周期
				else {
					String scopeName = mbd.getScope();
					final Scope scope = this.scopes.get(scopeName);
                    //Bean 定义资源中没有配置生命周期范围，则 Bean 定义不合法
					if (scope == null) {
						throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
					}
					try {
                        //这里又使用了一个匿名内部类，获取一个指定生命周期范围的实例
						Object scopedInstance = scope.get(beanName, () -> {
							beforePrototypeCreation(beanName);
							try {
								return createBean(beanName, mbd, args);
							}
							finally {
								afterPrototypeCreation(beanName);
							}
						});
                        //获取给定 Bean 的实例对象
						bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
					}
					catch (IllegalStateException ex) {
						throw new BeanCreationException(beanName,
								"Scope '" + scopeName + "' is not active for the current thread; consider " +
								"defining a scoped proxy for this bean if you intend to refer to it from a singleton",
								ex);
					}
				}
			}
			catch (BeansException ex) {
				cleanupAfterBeanCreationFailure(beanName);
				throw ex;
			}
		}

		// Check if required type matches the type of the actual bean instance.
    //对创建的 Bean 实例对象进行类型检查
		if (requiredType != null && !requiredType.isInstance(bean)) {
			try {
				T convertedBean = getTypeConverter().convertIfNecessary(bean, requiredType);
				if (convertedBean == null) {
					throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
				}
				return convertedBean;
			}
			catch (TypeMismatchException ex) {
				if (logger.isDebugEnabled()) {
					logger.debug("Failed to convert bean '" + name + "' to required type '" +
							ClassUtils.getQualifiedName(requiredType) + "'", ex);
				}
				throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
			}
		}
		return (T) bean;
	}
```

`bean`加载的过程很复杂，涉及各种各样的考虑，对过程进行一下梳理：

* 转换对应beanName(通过`transformedBeanName`方法)

  > 因为通过`getbean`传入的参数不只是`bean`的名称，还有可能是别名，也有可能是`FactoryBean`，所以需要进行一系列的解析。具体处理内容如下：
  >
  > * 去除`FactoryBean`的修饰符，也就是`name=&aa`，要去除`&`。
  > * 取指定`alias`所表示的最终`beanName`。

* 尝试从缓存中加载单例（通过`getSingleton`方法）

  > 单例模式的`bean`在Spring的同一个容器内只会被创建一次，后续再获取`bean`，就直接从单例缓存集合中获取。如果缓存中获取失败，则再尝试从`singletonFactories`中加载。因为创建单例`bean`时会存在依赖注入的情况，而在创建依赖的时候为了避免循环依赖，在Spring中创建`bean`的原则是不等`bean`创建完成就会将`bean`提早加入到缓存中。

* bean的实例化 （通过`getObjectForBeanInstance`）

  >因为从缓存中得到的`bean`是最原始的状态，并不一定是我们想要的`bean`。所以需要通过`getObjectForBeanInstance`来完成这个工作。

* 原型模式的依赖检查 (通过`isPrototypeCurrentlyInCreation`)

  > 只有单例模式下才会去解决循环依赖的问题，原型模式下直接抛出异常。

* 检查`parentBeanFactory`  （通过`getParentBeanFactory`）

  > 如果缓存没有数据，直接转到父类工厂上去加载。 其中一个判断是如果加载的`xml`配置文件中不包含`beanname`所对应的配置，就只能到`parentBeanFactory`去尝试。

* 将存储`bean`的`GernericBeanDefinition`转换为`RootBeanDefinition` (通过`getMergedLocalBeanDefinition`)

  > `bean`的信息都存储在`GernericBeanDefinition`中，但是对`bean`的后续处理都是针对于`RootBeanDefinition`的，所以需要转换一下

* 寻找依赖 （通过`getDependsOn`）

  > `bean`中有些属性存在依赖其他`bean`的关系，所以需要先加载依赖的`bean`。

* 针对不同的`scope`进行`bean`的创建

  > `bean`在spring中存在不同的`scope`，其中默认是`singleton`，会根据不同配置进行不同**初始化策略**，也就是依赖注入工作。
  >
  > 作用域包括以下几种：
  >
  > * `singleton`单例：在每个` Spring IoC` 容器中有且只有一个实例，而且其完整生命周期完全由 Spring 容器管理。对于所有获取该 `Bean` 的操作 Spring 容器将只返回同一个 `Bean`。 
  > * `prototype` 原型：每次向 `Spring IoC `容器请求获取 `Bean` 都返回一个全新的`Bean`。相对于 `singleton `来说就是不缓存 `Bean`，每次都是一个根据 `Bean` 定义创建的全新 `Bean`。 
  > * `request`:表示每个请求需要容器创建一个全新Bean。 
  > * `session`:表示每个会话需要容器创建一个全新 Bean。 
  > * `globalSession`:类似于`session `作用域，只是其用于` portlet` 环境的` web `应用。如果在非`portlet `环境将视为` session `作用域。 

* 类型转换 (通过`getTypeConverter().convertIfNecessary(bean, requiredType)`)

  > 如果调用参数`requiredType`是非空的，会进入这个处理。将`bean`类型装换成需要的类型

#### 创建Bean

上面分析很多的判断，而其中完成依赖注入的入口就是`CreateBean`方法。通过`AbstractAutowireCapableBeanFactory`中的`createBean`方法进入。

```java
@Override
	protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
			throws BeanCreationException {
		if (logger.isDebugEnabled()) {
			logger.debug("Creating instance of bean '" + beanName + "'");
		}
		RootBeanDefinition mbdToUse = mbd;

		// Make sure bean class is actually resolved at this point, and
		// clone the bean definition in case of a dynamically resolved Class
		// which cannot be stored in the shared merged bean definition.
		//锁定class，  根据class属性或name 解析class
		Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
		if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
			mbdToUse = new RootBeanDefinition(mbd);
			mbdToUse.setBeanClass(resolvedClass);
		}

		// Prepare method overrides.
		//验证及准备覆盖的方法
		try {
			mbdToUse.prepareMethodOverrides();
		}
		catch (BeanDefinitionValidationException ex) {
			throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(),
					beanName, "Validation of method overrides failed", ex);
		}

		try {
			// Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
			//给beanPostProcessors一个机会来返回代理来替代正在的实例
			Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
			if (bean != null) {
				return bean;
			}
		}
		catch (Throwable ex) {
			throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName,
					"BeanPostProcessor before instantiation of bean failed", ex);
		}

		try {
            //创建bean的入口
			Object beanInstance = doCreateBean(beanName, mbdToUse, args);
			if (logger.isDebugEnabled()) {
				logger.debug("Finished creating instance of bean '" + beanName + "'");
			}
			return beanInstance;
		}
		catch (BeanCreationException | ImplicitlyAppearedSingletonException ex) {
			// A previously detected exception with proper bean creation context already,
			// or illegal singleton state to be communicated up to DefaultSingletonBeanRegistry.
			throw ex;
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					mbdToUse.getResourceDescription(), beanName, "Unexpected exception during bean creation", ex);
		}
	}
```

其中先根据设置的`class`属性或者`classname`来解析`class`。然后通过`prepareMethodOverrides`方法对`override`属性进行标记及验证。因为spring配置里根本就没有`override-method`之类的配置，而这个是在初始化的时候将`lookup-method`和`replace-method`的配置统一放到`beanDefinition`的`methodOverrides`属性里。然后通过`resolveBeforeInstantiation`这个方法的注释为给`beanpost`处理器一个返回代理而不是目标`bean`实例的机会。  这个就是`bean`实例化之前的处理。而在后面的判断`if (bean != null) {return bean;}`这个判断的意思就是如果前置处理后返回的结果不为空，那么直接不进行`Bean`的实例化创建工作而直接返回结果。AOP功能就是基于这里判断的。看一下前置处理的具体内容：

```java
@Nullable
	protected Object resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd) {
		Object bean = null;
		if (!Boolean.FALSE.equals(mbd.beforeInstantiationResolved)) {
			// Make sure bean class is actually resolved at this point.
			if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
				Class<?> targetType = determineTargetType(beanName, mbd);
				if (targetType != null) {
					bean = applyBeanPostProcessorsBeforeInstantiation(targetType, beanName);
					if (bean != null) {
						bean = applyBeanPostProcessorsAfterInitialization(bean, beanName);
					}
				}
			}
			mbd.beforeInstantiationResolved = (bean != null);
		}
		return bean;
	}
```

这里是为在`bean`实例化之前进行的扩展点设置，而会先判断如果实现`InstantiationAwareBeanPostProcessor `接口，将执行`InstantiationAwareBeanPostProcessor `中的`postProcessBeforeInstantiation`方法，如果存在返回结果将再调用`BeanPostProcessor `中的`postProcessAfterInitialization`方法。***此处需要深入了解***

下面继续看`bean`创建过程。执行`doCreateBean`方法。

```java
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
			throws BeanCreationException {

		// Instantiate the bean.
		BeanWrapper instanceWrapper = null;
		if (mbd.isSingleton()) {
			instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
		}
		if (instanceWrapper == null) {
			instanceWrapper = createBeanInstance(beanName, mbd, args);
		}
		final Object bean = instanceWrapper.getWrappedInstance();
		Class<?> beanType = instanceWrapper.getWrappedClass();
		if (beanType != NullBean.class) {
			mbd.resolvedTargetType = beanType;
		}

		// Allow post-processors to modify the merged bean definition.
		synchronized (mbd.postProcessingLock) {
			if (!mbd.postProcessed) {
				try {
					applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
				}
				catch (Throwable ex) {
					throw new BeanCreationException(mbd.getResourceDescription(), beanName,
							"Post-processing of merged bean definition failed", ex);
				}
				mbd.postProcessed = true;
			}
		}

		// Eagerly cache singletons to be able to resolve circular references
		// even when triggered by lifecycle interfaces like BeanFactoryAware.
		boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
				isSingletonCurrentlyInCreation(beanName));
		if (earlySingletonExposure) {
			if (logger.isDebugEnabled()) {
				logger.debug("Eagerly caching bean '" + beanName +
						"' to allow for resolving potential circular references");
			}
			//aop 在这里将advice 动态编入bean中
			addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
		}

		// Initialize the bean instance.
		Object exposedObject = bean;
		try {
			//对bean进行填充   各个属性值  依赖bean等
			populateBean(beanName, mbd, instanceWrapper);
			//调用初始化   这个判断 aware init-method 等主要流程
			exposedObject = initializeBean(beanName, exposedObject, mbd);
		}
		catch (Throwable ex) {
			if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
				throw (BeanCreationException) ex;
			}
			else {
				throw new BeanCreationException(
						mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
			}
		}

		if (earlySingletonExposure) {
			Object earlySingletonReference = getSingleton(beanName, false);
			if (earlySingletonReference != null) {
				if (exposedObject == bean) {
					exposedObject = earlySingletonReference;
				}
				else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
					String[] dependentBeans = getDependentBeans(beanName);
					Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
					for (String dependentBean : dependentBeans) {
						if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
							actualDependentBeans.add(dependentBean);
						}
					}
					if (!actualDependentBeans.isEmpty()) {
						throw new BeanCurrentlyInCreationException(beanName,
								"Bean with name '" + beanName + "' has been injected into other beans [" +
								StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
								"] in its raw version as part of a circular reference, but has eventually been " +
								"wrapped. This means that said other beans do not use the final version of the " +
								"bean. This is often the result of over-eager type matching - consider using " +
								"'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
					}
				}
			}
		}
		// Register bean as disposable.
		try {
			//根据 scopse 注册bean
			registerDisposableBeanIfNecessary(beanName, bean, mbd);
		}
		catch (BeanDefinitionValidationException ex) {
			throw new BeanCreationException(
					mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
		}

		return exposedObject;
	}
```

这个方法也执行了很多操作，具体包括：

* 如果是单例，需要清除缓存  (通过`this.factoryBeanInstanceCache.remove(beanName);`)
* 实例化`bean`，并转换成`beanWrapper`类型。 （通过`createBeanInstance`）
* 执行扩展点，实现`MergedBeanDefinitionPostProcessor`接口的调用`postProcessMergedBeanDefinition`方法。  (通过`applyMergedBeanDefinitionPostProcessors`)
* 依赖处理  (通过`(mbd.isSingleton() && this.allowCircularReferences &&      isSingletonCurrentlyInCreation(beanName))`)
* 属性填充  将所有属性填充到`bean`实例中。 (通过`populateBean`)
* 循环依赖检查 验证是否存在循环依赖，做相应处理 (通过`getSingleton`) 
* 注册`DisposableBean` 如果配置了 `destroy-method`方法，执行销毁操作。 (通过`registerDisposableBeanIfNecessary`)
* 完成创建返回

#### Bean实例化

下面深入了解`Bean`实例化

```java
protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) {
		// Make sure bean class is actually resolved at this point.
		Class<?> beanClass = resolveBeanClass(mbd, beanName);

		if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) {
			throw new BeanCreationException(mbd.getResourceDescription(), beanName,
					"Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
		}

		Supplier<?> instanceSupplier = mbd.getInstanceSupplier();
		if (instanceSupplier != null) {
			return obtainFromSupplier(instanceSupplier, beanName);
		}
		//如果工厂方法不为空，则使用工厂方法初始化策略
		if (mbd.getFactoryMethodName() != null)  {
			return instantiateUsingFactoryMethod(beanName, mbd, args);
		}

		// Shortcut when re-creating the same bean...
		boolean resolved = false;
		boolean autowireNecessary = false;
		if (args == null) {
			synchronized (mbd.constructorArgumentLock) {
				if (mbd.resolvedConstructorOrFactoryMethod != null) {
					resolved = true;
					autowireNecessary = mbd.constructorArgumentsResolved;
				}
			}
		}
		if (resolved) {
			if (autowireNecessary) {
				//构造函数自动注入
				return autowireConstructor(beanName, mbd, null, null);
			}
			else {
				//使用默认构造函数构造
				return instantiateBean(beanName, mbd);
			}
		}

		// Need to determine the constructor...
		//需要根据参数解析构造函数
		Constructor<?>[] ctors = determineConstructorsFromBeanPostProcessors(beanClass, beanName);
		if (ctors != null ||
				mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_CONSTRUCTOR ||
				mbd.hasConstructorArgumentValues() || !ObjectUtils.isEmpty(args))  {
			return autowireConstructor(beanName, mbd, ctors, args);
		}

		// No special handling: simply use no-arg constructor.
		return instantiateBean(beanName, mbd);
	}
```

通过构造函数进行实例化，因为一个`bean`对应的类中可能会有多个构造函数，而且参数也不同，所以spring会根据参数及类型去判断最终使用哪个构造函数实例化。但是判断过程比较消耗性能，所以采用缓存机制。

带有参数的实例化过程非常复杂，会对参数做大量判断工作。具体调用`ConstructorResolver`中的`autowireConstructor`方法。

```java
public BeanWrapper autowireConstructor(final String beanName, final RootBeanDefinition mbd,
			@Nullable Constructor<?>[] chosenCtors, @Nullable final Object[] explicitArgs) {

		BeanWrapperImpl bw = new BeanWrapperImpl();
		this.beanFactory.initBeanWrapper(bw);

		Constructor<?> constructorToUse = null;
		ArgumentsHolder argsHolderToUse = null;
		Object[] argsToUse = null;
		//explicitArgs参数为 getbean调用时传入
		if (explicitArgs != null) {
			argsToUse = explicitArgs;
		}
		else {
            //如果没有传入参数 
			Object[] argsToResolve = null;
            //尝试从缓存中获取
			synchronized (mbd.constructorArgumentLock) {
				constructorToUse = (Constructor<?>) mbd.resolvedConstructorOrFactoryMethod;
				if (constructorToUse != null && mbd.constructorArgumentsResolved) {
					// Found a cached constructor...
                    //缓存中获取
					argsToUse = mbd.resolvedConstructorArguments;
					if (argsToUse == null) {
                         //配置的构造函数参数
						argsToResolve = mbd.preparedConstructorArguments;
					}
				}
			}
            //缓存中存在
			if (argsToResolve != null) {
                //解析参数类型，做相应处理
				argsToUse = resolvePreparedArguments(beanName, mbd, bw, constructorToUse, argsToResolve);
			}
		}
		//没有被缓存
		if (constructorToUse == null) {
			// Need to resolve the constructor.
			boolean autowiring = (chosenCtors != null ||
					mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_CONSTRUCTOR);
			ConstructorArgumentValues resolvedValues = null;

			int minNrOfArgs;
			if (explicitArgs != null) {
				minNrOfArgs = explicitArgs.length;
			}
			else {
                //提取配置文件中 配置的构造函数参数
				ConstructorArgumentValues cargs = mbd.getConstructorArgumentValues();
				resolvedValues = new ConstructorArgumentValues();
				minNrOfArgs = resolveConstructorArguments(beanName, mbd, bw, cargs, resolvedValues);
			}

			// Take specified constructors, if any.
			Constructor<?>[] candidates = chosenCtors;
			if (candidates == null) {
				Class<?> beanClass = mbd.getBeanClass();
				try {
					candidates = (mbd.isNonPublicAccessAllowed() ?
							beanClass.getDeclaredConstructors() : beanClass.getConstructors());
				}
				catch (Throwable ex) {
					throw new BeanCreationException(mbd.getResourceDescription(), beanName,
							"Resolution of declared constructors on bean Class [" + beanClass.getName() +
							"] from ClassLoader [" + beanClass.getClassLoader() + "] failed", ex);
				}
			}
            //排序给定的构造函数
			AutowireUtils.sortConstructors(candidates);
			int minTypeDiffWeight = Integer.MAX_VALUE;
			Set<Constructor<?>> ambiguousConstructors = null;
			LinkedList<UnsatisfiedDependencyException> causes = null;

			for (Constructor<?> candidate : candidates) {
				Class<?>[] paramTypes = candidate.getParameterTypes();

				if (constructorToUse != null && argsToUse.length > paramTypes.length) {
					// Already found greedy constructor that can be satisfied ->
					// do not look any further, there are only less greedy constructors left.
					break;
				}
				if (paramTypes.length < minNrOfArgs) {
					continue;
				}

				ArgumentsHolder argsHolder;
				if (resolvedValues != null) {
					try {
						String[] paramNames = ConstructorPropertiesChecker.evaluate(candidate, paramTypes.length);
						if (paramNames == null) {
							ParameterNameDiscoverer pnd = this.beanFactory.getParameterNameDiscoverer();
							if (pnd != null) {
								paramNames = pnd.getParameterNames(candidate);
							}
						}
						argsHolder = createArgumentArray(beanName, mbd, resolvedValues, bw, paramTypes, paramNames,
								getUserDeclaredConstructor(candidate), autowiring);
					}
					catch (UnsatisfiedDependencyException ex) {
						if (this.beanFactory.logger.isTraceEnabled()) {
							this.beanFactory.logger.trace(
									"Ignoring constructor [" + candidate + "] of bean '" + beanName + "': " + ex);
						}
						// Swallow and try next constructor.
						if (causes == null) {
							causes = new LinkedList<>();
						}
						causes.add(ex);
						continue;
					}
				}
				else {
					// Explicit arguments given -> arguments length must match exactly.
					if (paramTypes.length != explicitArgs.length) {
						continue;
					}
					argsHolder = new ArgumentsHolder(explicitArgs);
				}

				int typeDiffWeight = (mbd.isLenientConstructorResolution() ?
						argsHolder.getTypeDifferenceWeight(paramTypes) : argsHolder.getAssignabilityWeight(paramTypes));
				// Choose this constructor if it represents the closest match.
				if (typeDiffWeight < minTypeDiffWeight) {
					constructorToUse = candidate;
					argsHolderToUse = argsHolder;
					argsToUse = argsHolder.arguments;
					minTypeDiffWeight = typeDiffWeight;
					ambiguousConstructors = null;
				}
				else if (constructorToUse != null && typeDiffWeight == minTypeDiffWeight) {
					if (ambiguousConstructors == null) {
						ambiguousConstructors = new LinkedHashSet<>();
						ambiguousConstructors.add(constructorToUse);
					}
					ambiguousConstructors.add(candidate);
				}
			}

			if (constructorToUse == null) {
				if (causes != null) {
					UnsatisfiedDependencyException ex = causes.removeLast();
					for (Exception cause : causes) {
						this.beanFactory.onSuppressedException(cause);
					}
					throw ex;
				}
				throw new BeanCreationException(mbd.getResourceDescription(), beanName,
						"Could not resolve matching constructor " +
						"(hint: specify index/type/name arguments for simple parameters to avoid type ambiguities)");
			}
			else if (ambiguousConstructors != null && !mbd.isLenientConstructorResolution()) {
				throw new BeanCreationException(mbd.getResourceDescription(), beanName,
						"Ambiguous constructor matches found in bean '" + beanName + "' " +
						"(hint: specify index/type/name arguments for simple parameters to avoid type ambiguities): " +
						ambiguousConstructors);
			}

			if (explicitArgs == null) {
				argsHolderToUse.storeCache(mbd, constructorToUse);
			}
		}

		try {
			final InstantiationStrategy strategy = beanFactory.getInstantiationStrategy();
			Object beanInstance;

			if (System.getSecurityManager() != null) {
				final Constructor<?> ctorToUse = constructorToUse;
				final Object[] argumentsToUse = argsToUse;
				beanInstance = AccessController.doPrivileged((PrivilegedAction<Object>) () ->
						strategy.instantiate(mbd, beanName, beanFactory, ctorToUse, argumentsToUse),
						beanFactory.getAccessControlContext());
			}
			else {
				beanInstance = strategy.instantiate(mbd, beanName, this.beanFactory, constructorToUse, argsToUse);
			}

			bw.setBeanInstance(beanInstance);
			return bw;
		}
		catch (Throwable ex) {
			throw new BeanCreationException(mbd.getResourceDescription(), beanName,
					"Bean instantiation via constructor failed", ex);
		}
	}
```

逻辑非常复杂，开始分析步骤：

* 构造参数确定
* 从缓存中获取
* 从文件中获取
* 确定构造函数
* 构造函数参数处理
* 根据实例化策略进行实例化

Spring默认使用的是`CglibSubclassingInstantiationStrategy`策略；

```
final InstantiationStrategy strategy = beanFactory.getInstantiationStrategy();

private InstantiationStrategy instantiationStrategy = new CglibSubclassingInstantiationStrategy();
```

而在`CglibSubclassingInstantiationStrategy`中未复写`instantiate`方法，所以会进入父类`SimpleInstantiationStrategy`中的`instantiate`方法。

```java
@Override
	public Object instantiate(RootBeanDefinition bd, @Nullable String beanName, BeanFactory owner,
			final Constructor<?> ctor, @Nullable Object... args) {

		if (!bd.hasMethodOverrides()) {
			if (System.getSecurityManager() != null) {
				// use own privileged to change accessibility (when security is on)
				AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
					ReflectionUtils.makeAccessible(ctor);
					return null;
				});
			}
			return (args != null ? BeanUtils.instantiateClass(ctor, args) : BeanUtils.instantiateClass(ctor));
		}
		else {
			return instantiateWithMethodInjection(bd, beanName, owner, ctor, args);
		}
	}
```

这个方法中Spring会判断用户有没有使用`replace`或者`lookup`的配置方法，就是通过`!bd.hasMethodOverrides()`判断。如果没有则会通过java的反射方式直接实例化。

```java
public static <T> T instantiateClass(Constructor<T> ctor, Object... args) throws BeanInstantiationException {
		Assert.notNull(ctor, "Constructor must not be null");
		try {
			ReflectionUtils.makeAccessible(ctor);
			return (KotlinDetector.isKotlinType(ctor.getDeclaringClass()) ?
					KotlinDelegate.instantiateClass(ctor, args) : ctor.newInstance(args));
		}
    ...
}
```

否则会通过动态代理方式将`replace`或者`lookup`特性的逻辑增强设置进去，返回包含拦截器增强的代理实例。

这种是带参数的实例化处理方式，那么上面的无参数实例化方式会更简单些，是通过`instantiateBean`方法进入。

```java
protected BeanWrapper instantiateBean(final String beanName, final RootBeanDefinition mbd) {
		try {
			Object beanInstance;
			final BeanFactory parent = this;
			if (System.getSecurityManager() != null) {
				beanInstance = AccessController.doPrivileged((PrivilegedAction<Object>) () ->
						getInstantiationStrategy().instantiate(mbd, beanName, parent),
						getAccessControlContext());
			}
			else {
				beanInstance = getInstantiationStrategy().instantiate(mbd, beanName, parent);
			}
			BeanWrapper bw = new BeanWrapperImpl(beanInstance);
			initBeanWrapper(bw);
			return bw;
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					mbd.getResourceDescription(), beanName, "Instantiation of bean failed", ex);
		}
	}
```

同样会根据策略判断采用哪种方式进行实例化。将实例化对象封装到`BeanWrapper`中返回。到这里实例化的过程结束了，我们回到上面的`doCreateBean`方法中，继续下一步分析。通过`applyMergedBeanDefinitionPostProcessors`调用，完成对扩展点的支持调用工作。之后会做一步依赖处理，这是处理aop的功能，将在aop中详细描述。处理完这些就进入到了属性注入环节，通过`populateBean`方法。

#### 参数注入

```java
protected void populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) {
		if (bw == null) {
			if (mbd.hasPropertyValues()) {
				throw new BeanCreationException(
						mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
			}
			else {
				// Skip property population phase for null instance.
				return;
			}
		}

		// Give any InstantiationAwareBeanPostProcessors the opportunity to modify the
		// state of the bean before properties are set. This can be used, for example,
		// to support styles of field injection.
         //给InstantiationAwareBeanPostProcessors最后一次机会在属性注入前来改变bean
		boolean continueWithPropertyPopulation = true;

		if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
			for (BeanPostProcessor bp : getBeanPostProcessors()) {
				if (bp instanceof InstantiationAwareBeanPostProcessor) {
					InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
					if (!ibp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
						continueWithPropertyPopulation = false;
						break;
					}
				}
			}
		}

		if (!continueWithPropertyPopulation) {
			return;
		}

		PropertyValues pvs = (mbd.hasPropertyValues() ? mbd.getPropertyValues() : null);

		if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME ||
				mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
			MutablePropertyValues newPvs = new MutablePropertyValues(pvs);

			// Add property values based on autowire by name if applicable.
			if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_NAME) {
				autowireByName(beanName, mbd, bw, newPvs);
			}

			// Add property values based on autowire by type if applicable.
			if (mbd.getResolvedAutowireMode() == RootBeanDefinition.AUTOWIRE_BY_TYPE) {
				autowireByType(beanName, mbd, bw, newPvs);
			}

			pvs = newPvs;
		}

		boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
		boolean needsDepCheck = (mbd.getDependencyCheck() != RootBeanDefinition.DEPENDENCY_CHECK_NONE);

		if (hasInstAwareBpps || needsDepCheck) {
			if (pvs == null) {
				pvs = mbd.getPropertyValues();
			}
			PropertyDescriptor[] filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
			if (hasInstAwareBpps) {
				for (BeanPostProcessor bp : getBeanPostProcessors()) {
					if (bp instanceof InstantiationAwareBeanPostProcessor) {
						InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
						pvs = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
						if (pvs == null) {
							return;
						}
					}
				}
			}
			if (needsDepCheck) {
				checkDependencies(beanName, mbd, filteredPds, pvs);
			}
		}

		if (pvs != null) {
			applyPropertyValues(beanName, mbd, bw, pvs);
		}
	}
```

在这个方法中主要提供这些流程：

* `InstantiationAwareBeanPostProcessors` 处理器的`postProcessAfterInstantiation`的调用
* 根据注入类型`byname`或`byType`，提取依赖的bean,并存入`PropertyValues`中。
* `InstantiationAwareBeanPostProcessors` 处理器中`postProcessPropertyValues`的调用；
* 将所有`PropertyValues`填充至`beanwrapper`中。

如何将`PropertyValues`填充到属性中呢，详细跟踪`applyPropertyValues`方法的调用。

```java
protected void applyPropertyValues(String beanName, BeanDefinition mbd, BeanWrapper bw, PropertyValues pvs) {
		if (pvs.isEmpty()) {
			return;
		}

		if (System.getSecurityManager() != null && bw instanceof BeanWrapperImpl) {
			((BeanWrapperImpl) bw).setSecurityContext(getAccessControlContext());
		}

		MutablePropertyValues mpvs = null;
		List<PropertyValue> original;

		if (pvs instanceof MutablePropertyValues) {
			mpvs = (MutablePropertyValues) pvs;
			if (mpvs.isConverted()) {
				// Shortcut: use the pre-converted values as-is.
				try {
					bw.setPropertyValues(mpvs);
					return;
				}
				catch (BeansException ex) {
					throw new BeanCreationException(
							mbd.getResourceDescription(), beanName, "Error setting property values", ex);
				}
			}
			original = mpvs.getPropertyValueList();
		}
		else {
			original = Arrays.asList(pvs.getPropertyValues());
		}

		TypeConverter converter = getCustomTypeConverter();
		if (converter == null) {
			converter = bw;
		}
		BeanDefinitionValueResolver valueResolver = new BeanDefinitionValueResolver(this, beanName, mbd, converter);

		// Create a deep copy, resolving any references for values.
		List<PropertyValue> deepCopy = new ArrayList<>(original.size());
		boolean resolveNecessary = false;
		for (PropertyValue pv : original) {
			if (pv.isConverted()) {
				deepCopy.add(pv);
			}
			else {
				String propertyName = pv.getName();
				Object originalValue = pv.getValue();
				Object resolvedValue = valueResolver.resolveValueIfNecessary(pv, originalValue);
				Object convertedValue = resolvedValue;
				boolean convertible = bw.isWritableProperty(propertyName) &&
						!PropertyAccessorUtils.isNestedOrIndexedProperty(propertyName);
				if (convertible) {
					convertedValue = convertForProperty(resolvedValue, propertyName, bw, converter);
				}
				// Possibly store converted value in merged bean definition,
				// in order to avoid re-conversion for every created bean instance.
				if (resolvedValue == originalValue) {
					if (convertible) {
						pv.setConvertedValue(convertedValue);
					}
					deepCopy.add(pv);
				}
				else if (convertible && originalValue instanceof TypedStringValue &&
						!((TypedStringValue) originalValue).isDynamic() &&
						!(convertedValue instanceof Collection || ObjectUtils.isArray(convertedValue))) {
					pv.setConvertedValue(convertedValue);
					deepCopy.add(pv);
				}
				else {
					resolveNecessary = true;
					deepCopy.add(new PropertyValue(pv, convertedValue));
				}
			}
		}
		if (mpvs != null && !resolveNecessary) {
			mpvs.setConverted();
		}

		// Set our (possibly massaged) deep copy.
		try {
			bw.setPropertyValues(new MutablePropertyValues(deepCopy));
		}
		catch (BeansException ex) {
			throw new BeanCreationException(
					mbd.getResourceDescription(), beanName, "Error setting property values", ex);
		}
	}
```

#### 初始化bean

当属性注入完成后，会对bean进行初始化工作，通过`initializeBean`方法进入。

```java
protected Object initializeBean(final String beanName, final Object bean, @Nullable RootBeanDefinition mbd) {
		if (System.getSecurityManager() != null) {
			AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
				invokeAwareMethods(beanName, bean);
				return null;
			}, getAccessControlContext());
		}
		else {
			invokeAwareMethods(beanName, bean);
		}

		Object wrappedBean = bean;
		if (mbd == null || !mbd.isSynthetic()) {
			wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
		}

		try {
			invokeInitMethods(beanName, wrappedBean, mbd);
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					(mbd != null ? mbd.getResourceDescription() : null),
					beanName, "Invocation of init method failed", ex);
		}
		if (mbd == null || !mbd.isSynthetic()) {
			wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
		}

		return wrappedBean;
	}
```

具体处理步骤

* 激活`Aware`方法，通过`invokeAwareMethods`方法。判断是否实现指定接口，则调用指定方法。

  ```java
  private void invokeAwareMethods(final String beanName, final Object bean) {
  		if (bean instanceof Aware) {
  			if (bean instanceof BeanNameAware) {
  				((BeanNameAware) bean).setBeanName(beanName);
  			}
  			if (bean instanceof BeanClassLoaderAware) {
  				ClassLoader bcl = getBeanClassLoader();
  				if (bcl != null) {
  					((BeanClassLoaderAware) bean).setBeanClassLoader(bcl);
  				}
  			}
  			if (bean instanceof BeanFactoryAware) {
  				((BeanFactoryAware) bean).setBeanFactory(AbstractAutowireCapableBeanFactory.this);
  			}
  		}
  	}
  
  ```

* 判断扩展点是否使用，调用前置处理`postProcessBeforeInitialization`;

* 执行初始化方法`invokeInitMethods`

  ```java
  protected void invokeInitMethods(String beanName, final Object bean, @Nullable RootBeanDefinition mbd)
  			throws Throwable {
  
  		boolean isInitializingBean = (bean instanceof InitializingBean);
  		if (isInitializingBean && (mbd == null || !mbd.isExternallyManagedInitMethod("afterPropertiesSet"))) {
  			if (logger.isDebugEnabled()) {
  				logger.debug("Invoking afterPropertiesSet() on bean with name '" + beanName + "'");
  			}
  			if (System.getSecurityManager() != null) {
  				try {
  					AccessController.doPrivileged((PrivilegedExceptionAction<Object>) () -> {
  						((InitializingBean) bean).afterPropertiesSet();
  						return null;
  					}, getAccessControlContext());
  				}
  				catch (PrivilegedActionException pae) {
  					throw pae.getException();
  				}
  			}
  			else {
  				((InitializingBean) bean).afterPropertiesSet();
  			}
  		}
  
  		if (mbd != null && bean.getClass() != NullBean.class) {
  			String initMethodName = mbd.getInitMethodName();
  			if (StringUtils.hasLength(initMethodName) &&
  					!(isInitializingBean && "afterPropertiesSet".equals(initMethodName)) &&
  					!mbd.isExternallyManagedInitMethod(initMethodName)) {
  				invokeCustomInitMethod(beanName, bean, mbd);
  			}
  		}
  	}
  ```

  先判断是否实现`InitializingBean`接口，执行`afterPropertiesSet`方法，然后判断是否有`init-method`方法，有则执行。

* 再一次判断扩展点是否使用，调用后置处理`postProcessAfterInitialization`;

#### 注册`DisposableBean`

通过`registerDisposableBeanIfNecessary`方法，完成销毁方法扩展入口的绑定。

#### 总结

依赖注入的整个过程，差不多就是`bean`的生命周期，所以也可以用`bean`生命周期 来进行理解；

* 实例化  采用策略模式来决定使用`cglib`或者java反射来实例化，以`BeanWrapper`对构造完成的对象实例进行包裹，返回相应的`BeanWrapper`实例。 
* 为bean注入属性。
* 判断是否实现了 `Aware`相关接口
  * 如果实现了`BeanNameAware `接口，会调用`setBeanName `方法；
  * 如果实现了`BeanFactoryAware `接口，会调用`setBeanFactory `方法；
  * 如果实现了`ApplicationContextAware `接口，会调用`setApplicationContext`方法；
* 判断是否实现`BeanPostProcessor `接口，执行`postProcessBeforeInitialization `前置方法；
* 判断是否实现`InitializingBean `接口，执行`afterPropertiesSet `方法；
* 判断是否配置了`init-method`方法，配置了则执行；
* 判断是否实现`BeanPostProcessor `接口，执行`postProcessAfterInitialization `前置方法；
* bean容器处理正常工作情况，可以进行使用；
* 容器关闭时，判断是否实现`DisposableBean `接口，调用`destroy`方法；
* 如果配置了`destroy-method`方法，执行配置的方法；

