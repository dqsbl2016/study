# Spring MVC

Spring MVC是基于 模型-视图-控制器（Model-View-Controller,MVC）模式实现的。

核心是  DispatcherServlet 类，先看下继承结构

* Object
  * GenericServlet
    * HttpServlet
      * HttpServletBean
        * FarmeworkServlet
          * DispatcherServlet

再了解下具体请求处理

![image](https://github.com/dqsbl2016/study/blob/master/Spring/xy/img/Spring MVC.jpg)





## 原理分析

Spring MVC利用servlet的生命周期特点，将容器的初始化融合在了servlet的初始化过程中。

servlet是一个Java编写的程序，此程序是基于HTTP协议的，在服务器端运行的（如Tomcat），是按照servlet规范编写的一个java类。主要是处理客户端的请求并将其结果发送到客户端。servlet的生命周期是由servlet的容器来控制的，它可以分为3个阶段：初始化，运行和销毁。 

* 初始化方法阶段    会通过调用init()方法完成初始化过程。

  * servlet容器加载servlet类，把servlet类的.class文件中的数据读到内存中。
  * servlet容器创建一个ServletConfig对象。ServletConfig对象包含了servlet的初始化配置信息。
  * servlet容器创建一个servlet对象
  * servlet容器调用servlet对象的init方法进行初始化

* 使用阶段  通过调用service()方法完成服务请求。

  当servlet容器接收到一个请求时，servlet容器会针对这个请求创建serlvetRequest和servletResponse对象，然后调用service方法。并把这两个参数传递给service方法。service方法通过servletRequest对象获得请求的信息。并处理该请求。再通过servletResponse对象生成这个请求的相应结果。然后销毁servletResponse和servletRequest对象。 

* 销毁阶段  通过调用destroy()方法完成销毁操作。

  当web应用终止时，servlet容器会先调用servlet对象的destory方法，然后再销毁servlet对象，同时销毁servlet关联的ServletConfig对象。我们可以在destroy方法的实现中，释放servlet所占用的资源，如关闭数据库连接，关闭输入输出流等。

**具体细节需要了解servlet**



WEB容器初始化过程

![image](https://github.com/dqsbl2016/study/blob/master/Spring/xy/img/2017716110345216.jpg)





## 源码分析

首先从web.xml着手。

```java
<?xml version="1.0" encoding="UTF-8"?> 
<web-app version="2.5" xmlns="http://java.sun.com/xml/ns/javaee"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd"> 
  
 <context-param> 
  <param-name>contextConfigLocation</param-name> 
  <param-value>classpath:applicationContext.xml</param-value> 
 </context-param> 
  
 <listener> 
  <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class> 
 </listener> 
  
  
 <servlet> 
  <servlet-name>mvc-dispatcher</servlet-name> 
  <servlet-class> 
   org.springframework.web.servlet.DispatcherServlet 
  </servlet-class> 
  <load-on-startup>1</load-on-startup> 
 </servlet> 
                                    
 <servlet-mapping> 
  <servlet-name>mvc-dispatcher</servlet-name> 
  <url-pattern>/</url-pattern> 
 </servlet-mapping> 
  
</web-app>
```

### 加载过程

#### ContextLoaderListener

`ContextLoaderListener`的作用就是启动Web容器时，自动装配ApplicationContext的配置信息。

`ContextLoaderListener`实现了`ServletContextListener`接口，`ServletContextListener`是Java EE标准接口之一，类似tomcat，jetty的java容器启动时便会触发该接口的`contextInitialized`。 

触发`ContextLoaderListener`中的`contextInitialized`方法。

```java
public void contextInitialized(ServletContextEvent event) {
		initWebApplicationContext(event.getServletContext());
	}
```

会调用父类`ContextLoader` 中的`initWebApplicationContext`方法。

```java
public WebApplicationContext initWebApplicationContext(ServletContext servletContext) {
		if (servletContext.getAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE) != null) {
			throw new IllegalStateException(
					"Cannot initialize context because there is already a root application context present - " +
					"check whether you have multiple ContextLoader* definitions in your web.xml!");
		}

		Log logger = LogFactory.getLog(ContextLoader.class);
		servletContext.log("Initializing Spring root WebApplicationContext");
		if (logger.isInfoEnabled()) {
			logger.info("Root WebApplicationContext: initialization started");
		}
		long startTime = System.currentTimeMillis();

		try {
			// Store context in local instance variable, to guarantee that
			// it is available on ServletContext shutdown.
			if (this.context == null) {
				this.context = createWebApplicationContext(servletContext);
			}
			if (this.context instanceof ConfigurableWebApplicationContext) {
				ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) this.context;
				if (!cwac.isActive()) {
					// The context has not yet been refreshed -> provide services such as
					// setting the parent context, setting the application context id, etc
					if (cwac.getParent() == null) {
						// The context instance was injected without an explicit parent ->
						// determine parent for root web application context, if any.
						ApplicationContext parent = loadParentContext(servletContext);
						cwac.setParent(parent);
					}
					configureAndRefreshWebApplicationContext(cwac, servletContext);
				}
			}
			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, this.context);

			ClassLoader ccl = Thread.currentThread().getContextClassLoader();
			if (ccl == ContextLoader.class.getClassLoader()) {
				currentContext = this.context;
			}
			else if (ccl != null) {
				currentContextPerThread.put(ccl, this.context);
			}

			if (logger.isDebugEnabled()) {
				logger.debug("Published root WebApplicationContext as ServletContext attribute with name [" +
						WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE + "]");
			}
			if (logger.isInfoEnabled()) {
				long elapsedTime = System.currentTimeMillis() - startTime;
				logger.info("Root WebApplicationContext: initialization completed in " + elapsedTime + " ms");
			}

			return this.context;
		}
		catch (RuntimeException ex) {
			logger.error("Context initialization failed", ex);
			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, ex);
			throw ex;
		}
		catch (Error err) {
			logger.error("Context initialization failed", err);
			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, err);
			throw err;
		}
	}
```

调用`createWebApplicationContext`方法,创建一个`WebAoolicationContext`。

```java
protected WebApplicationContext createWebApplicationContext(ServletContext sc) {
		Class<?> contextClass = determineContextClass(sc);
		if (!ConfigurableWebApplicationContext.class.isAssignableFrom(contextClass)) {
			throw new ApplicationContextException("Custom context class [" + contextClass.getName() +
					"] is not of type [" + ConfigurableWebApplicationContext.class.getName() + "]");
		}
		return (ConfigurableWebApplicationContext) BeanUtils.instantiateClass(contextClass);
	}
```

在这里先调用`determineContextClass`方法确定`contextclass`实例。

```java
protected Class<?> determineContextClass(ServletContext servletContext) {
		String contextClassName = servletContext.getInitParameter(CONTEXT_CLASS_PARAM);
		if (contextClassName != null) {
			try {
				return ClassUtils.forName(contextClassName, ClassUtils.getDefaultClassLoader());
			}
			catch (ClassNotFoundException ex) {
				throw new ApplicationContextException(
						"Failed to load custom context class [" + contextClassName + "]", ex);
			}
		}
		else {
			contextClassName = defaultStrategies.getProperty(WebApplicationContext.class.getName());
			try {
				return ClassUtils.forName(contextClassName, ContextLoader.class.getClassLoader());
			}
			catch (ClassNotFoundException ex) {
				throw new ApplicationContextException(
						"Failed to load default context class [" + contextClassName + "]", ex);
			}
		}
	}
```

先尝试从配置中获取`contextClass`,通过反射实例后返回。如果未找到从`defaultStrategies`属性中获取。而这个属性的值是通过静态代码块中进行的赋值

```java
static {
		// Load default strategy implementations from properties file.
		// This is currently strictly internal and not meant to be customized
		// by application developers.
		try {
			ClassPathResource resource = new ClassPathResource(DEFAULT_STRATEGIES_PATH, ContextLoader.class);
			defaultStrategies = PropertiesLoaderUtils.loadProperties(resource);
		}
		catch (IOException ex) {
			throw new IllegalStateException("Could not load 'ContextLoader.properties': " + ex.getMessage());
		}
	}
```

使用`ClassPathResource`方式获取文件路径资源`ContextLoader.properties`。具体在`\spring-web\src\main\resources\org\springframework\web\context\ContextLoader.properties`路径下看到这个文件内容。

```properties
org.springframework.web.context.WebApplicationContext=org.springframework.web.context.support.XmlWebApplicationContext
```

所以获取到的contextClass为`XmlWebApplicationContext`。

```java
contextClassName = defaultStrategies.getProperty(WebApplicationContext.class.getName());
```

再返回到初始化的方法中，会满足`if (this.context instanceof ConfigurableWebApplicationContext)`这个判断，所以会执行`configureAndRefreshWebApplicationContext`方法。

```java
protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac, ServletContext sc) {
		if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
			// The application context id is still set to its original default value
			// -> assign a more useful id based on available information
			String idParam = sc.getInitParameter(CONTEXT_ID_PARAM);
			if (idParam != null) {
				wac.setId(idParam);
			}
			else {
				// Generate default id...
				wac.setId(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
						ObjectUtils.getDisplayString(sc.getContextPath()));
			}
		}

		wac.setServletContext(sc);
		String configLocationParam = sc.getInitParameter(CONFIG_LOCATION_PARAM);
		if (configLocationParam != null) {
			wac.setConfigLocation(configLocationParam);
		}

		// The wac environment's #initPropertySources will be called in any case when the context
		// is refreshed; do it eagerly here to ensure servlet property sources are in place for
		// use in any post-processing or initialization that occurs below prior to #refresh
		ConfigurableEnvironment env = wac.getEnvironment();
		if (env instanceof ConfigurableWebEnvironment) {
			((ConfigurableWebEnvironment) env).initPropertySources(sc, null);
		}

		customizeContext(sc, wac);
		wac.refresh();
	}
```

其中做了一些处理，会读取资源文件属性`contextConfigLocation`的内容，而在XML中可以看到``contextConfigLocation``的内容就是我们`applicationContext.xml`文件的classpath。

```xml
 <context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>
			classpath:applicationContext.xml
		</param-value>
  </context-param>
```

之后就会调用到`AbstractApplicationContext`中的`refresh`方法。这个就是执行了IOC初始化的过程，对`applicationContext.xml`文件进行解析初始化。

#### IntrospectorCleanupListener

主要负责处理由JavaBean Introspector使用而引起的缓冲泄露。

`IntrospectorCleanupListener`也是实现了`ServletContextListener`接口，所以也会调用`contextInitialized`方法。

```java
public void contextInitialized(ServletContextEvent event) {				  CachedIntrospectionResults.acceptClassLoader(Thread.currentThread().getContextClassLoader());
	}
```







#### DispatcherServlet

之后会执行servlet初始化工作。根据servlet生命周期会执行init方法，其中在DispatcherServlet中没有init方法，所以会调用父类`HttpServletBean`中init方法。

```java
public final void init() throws ServletException {
		if (logger.isDebugEnabled()) {
			logger.debug("Initializing servlet '" + getServletName() + "'");
		}

		// Set bean properties from init parameters.
		PropertyValues pvs = new ServletConfigPropertyValues(getServletConfig(), this.requiredProperties);
		if (!pvs.isEmpty()) {
			try {
				BeanWrapper bw = PropertyAccessorFactory.forBeanPropertyAccess(this);
				ResourceLoader resourceLoader = new ServletContextResourceLoader(getServletContext());
				bw.registerCustomEditor(Resource.class, new ResourceEditor(resourceLoader, getEnvironment()));
				initBeanWrapper(bw);
				bw.setPropertyValues(pvs, true);
			}
			catch (BeansException ex) {
				if (logger.isErrorEnabled()) {
					logger.error("Failed to set bean properties on servlet '" + getServletName() + "'", ex);
				}
				throw ex;
			}
		}

		// Let subclasses do whatever initialization they like.
		initServletBean();

		if (logger.isDebugEnabled()) {
			logger.debug("Servlet '" + getServletName() + "' configured successfully");
		}
	}

```

首先会进行解析`init-param`属性，会通过实例`ServletConfigPropertyValues`进入

```java
public ServletConfigPropertyValues(ServletConfig config, Set<String> requiredProperties)
				throws ServletException {

			Set<String> missingProps = (!CollectionUtils.isEmpty(requiredProperties) ?
					new HashSet<>(requiredProperties) : null);

			Enumeration<String> paramNames = config.getInitParameterNames();
			while (paramNames.hasMoreElements()) {
				String property = paramNames.nextElement();
				Object value = config.getInitParameter(property);
				addPropertyValue(new PropertyValue(property, value));
				if (missingProps != null) {
					missingProps.remove(property);
				}
			}

			// Fail if we are still missing properties.
			if (!CollectionUtils.isEmpty(missingProps)) {
				throw new ServletException(
						"Initialization from ServletConfig for servlet '" + config.getServletName() +
						"' failed; the following required properties were missing: " +
						StringUtils.collectionToDelimitedString(missingProps, ", "));
			}
		}
	}
```

首先会读取属性，也就是xml中的配置。

```java
<init-param>
      <param-name>contextConfigLocation</param-name>
      <param-value>/WEB-INF/servlet-iep.xml</param-value>
    </init-param>
```

然后调用`addPropertyValue`方法，将属性name与value存入到`propertyValueList`属性中

```java
public MutablePropertyValues addPropertyValue(PropertyValue pv) {
		for (int i = 0; i < this.propertyValueList.size(); i++) {
			PropertyValue currentPv = this.propertyValueList.get(i);
			if (currentPv.getName().equals(pv.getName())) {
				pv = mergeIfRequired(pv, currentPv);
				setPropertyValueAt(pv, i);
				return this;
			}
		}
		this.propertyValueList.add(pv);
		return this;
	}
```

再回到上面， 将当前的servlet类型实例转换为BeanWrapper类型实例，以便使用Spring中提供的注入功能进行对应属性注入。包括contextAttribute、contextClass、nameSpace等。之后注册一份属性编辑器`ResourceEditor`。然后执行属性注入方法。

这些准备工作都做完之后，开始进入servletBean的初始化工作，通过`initServletBean`方法

```java
protected final void initServletBean() throws ServletException {
		getServletContext().log("Initializing Spring FrameworkServlet '" + getServletName() + "'");
		if (this.logger.isInfoEnabled()) {
			this.logger.info("FrameworkServlet '" + getServletName() + "': initialization started");
		}
		long startTime = System.currentTimeMillis();

		try {
			this.webApplicationContext = initWebApplicationContext();
			initFrameworkServlet();
		}
		catch (ServletException | RuntimeException ex) {
			this.logger.error("Context initialization failed", ex);
			throw ex;
		}

		if (this.logger.isInfoEnabled()) {
			long elapsedTime = System.currentTimeMillis() - startTime;
			this.logger.info("FrameworkServlet '" + getServletName() + "': initialization completed in " +
					elapsedTime + " ms");
		}
	}
```

这里面最主要的就是执行` initWebApplicationContext`方法，另外还提供了一个`initFrameworkServlet`空的可扩展方法。

```java
protected WebApplicationContext initWebApplicationContext() {
		WebApplicationContext rootContext =
				WebApplicationContextUtils.getWebApplicationContext(getServletContext());
		WebApplicationContext wac = null;

		if (this.webApplicationContext != null) {
			// A context instance was injected at construction time -> use it
			wac = this.webApplicationContext;
			if (wac instanceof ConfigurableWebApplicationContext) {
				ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) wac;
				if (!cwac.isActive()) {
					// The context has not yet been refreshed -> provide services such as
					// setting the parent context, setting the application context id, etc
					if (cwac.getParent() == null) {
						// The context instance was injected without an explicit parent -> set
						// the root application context (if any; may be null) as the parent
						cwac.setParent(rootContext);
					}
					configureAndRefreshWebApplicationContext(cwac);
				}
			}
		}
		if (wac == null) {
			// No context instance was injected at construction time -> see if one
			// has been registered in the servlet context. If one exists, it is assumed
			// that the parent context (if any) has already been set and that the
			// user has performed any initialization such as setting the context id
			wac = findWebApplicationContext();
		}
		if (wac == null) {
			// No context instance is defined for this servlet -> create a local one
			wac = createWebApplicationContext(rootContext);
		}

		if (!this.refreshEventReceived) {
			// Either the context is not a ConfigurableApplicationContext with refresh
			// support or the context injected at construction time had already been
			// refreshed -> trigger initial onRefresh manually here.
			onRefresh(wac);
		}

		if (this.publishContext) {
			// Publish the context as a servlet context attribute.
			String attrName = getServletContextAttributeName();
			getServletContext().setAttribute(attrName, wac);
			if (this.logger.isDebugEnabled()) {
				this.logger.debug("Published WebApplicationContext of servlet '" + getServletName() +
						"' as ServletContext attribute with name [" + attrName + "]");
			}
		}

		return wac;
	}
```

首先判断`webApplicationContext`属性是否有值，因为DispatcherServlet只能被实例化一次，所以如果为空说媒没有实例化，要进行实例化。 如果不为空，则要对具体的资源文件进行spring IOC初始化。

```xml
 <init-param>
      <param-name>contextConfigLocation</param-name>
      <param-value>/WEB-INF/servlet-***.xml</param-value>
    </init-param>
```

然后会调用最重要的刷新方法`onRefresh`，具体在子类DispatcherServlet中实现。

```java
protected void onRefresh(ApplicationContext context) {
		initStrategies(context);
	}
...
 protected void initStrategies(ApplicationContext context) {
		initMultipartResolver(context);
		initLocaleResolver(context);
		initThemeResolver(context);
		initHandlerMappings(context);
		initHandlerAdapters(context);
		initHandlerExceptionResolvers(context);
		initRequestToViewNameTranslator(context);
		initViewResolvers(context);
		initFlashMapManager(context);
	}
```

这里面就是spring mvc中的9大组件初始化过程。

##### initMultipartResolver

主要用来处理文件上传，默认情况下Spring没有multipart的处理，因为之前ioc容器初始化工作都已经做完，所以这里会直接通过getBean获取具体的解析器赋值给multipartResolver属性。

```java
	private void initMultipartResolver(ApplicationContext context) {
		try {
			this.multipartResolver = context.getBean(MULTIPART_RESOLVER_BEAN_NAME, MultipartResolver.class);
			if (logger.isDebugEnabled()) {
				logger.debug("Using MultipartResolver [" + this.multipartResolver + "]");
			}
		}
     ...
```

##### initLocaleResolver

主要用来处理国际化配置。其中包括3种方式。

* 基于URl     例如 \<a href="?locale=zh_CN">简体中文\</a>方式，通过使用AcceptHeaderLocaleResolver解析器。

  ```xml
  <bean id="localeResolver" class="org.Springframework.web.servlet.i18n.AcceptHeaderLocaleResolver"/>
  ```

* 基于Session   一次会话中的语言设定

  ```java
  <bean id="localeResolver" class="org.Springframework.web.servlet.i18n.SessionLocaleResolver"/>
  ```

* 基于Cookie   基于浏览器cookie设置

  ```java
  <bean id="localeResolver" class="org.Springframework.web.servlet.i18n.CookieLocaleResolver"/>
  ```

初始化过程也是根据用户的配置进行IOC初始化后，在这里通过getBean方式调用。

```java
private void initLocaleResolver(ApplicationContext context) {
		try {
			this.localeResolver = context.getBean(LOCALE_RESOLVER_BEAN_NAME, LocaleResolver.class);
			if (logger.isDebugEnabled()) {
				logger.debug("Using LocaleResolver [" + this.localeResolver + "]");
			}
		}
    ...
```

##### initThemeResolver

通过主题改变页面风格。