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

##### init

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

###### initMultipartResolver

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

###### initLocaleResolver

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

###### initThemeResolver

通过主题改变页面风格。其中定义了4种解析器,  主题配置文件   summer.properties

* FixedThemeResolver  用于选择一个固定的主题

  ```xml
  <bean id ="themeResolver" class="org.Springframework.web.servlet.theme.FixedThemeResolver">
  	<proerty name="defaultThemeName" value="summer"/>
  </bean>
  ```

* CookieThemeResolver  用于实现用户所选的主题，以cookie的形式存放在客户端的机器上

  ```java
  <bean id ="themeResolver" class="org.Springframework.web.servlet.theme.CookieThemeResolver">
  	<proerty name="defaultThemeName" value="summer"/>
  </bean>
  ```

* SessionThemeResolver  用于主题保存在用户的HTTP Session中

  ```java
  <bean id="themeResolver" class="org.Springframework.web.servlet.theme.SessionThemeResolver">
  	<proerty name="defaultThemeName" value="summer"/>
  </bean>
  ```

* AbstractThemeResolver  一个抽象类，用户可以继承它实现自定义解析器。

如果想根据用户请求来改变主题，Spring提供了一个拦截器 ThemeChangeInterceptor 。

```xml
<bean id="themeChangeInterceptor" class="org.Springframework.web.servlet.theme.ThemeChangeInterceptor">
	<proerty name="paramName" value="themeName"/>
</bean>
```

其中用户的主题名称是themeName。 即 URL为？themeName=具体的主题名称。另外还需要在handlerMapping中配置拦截器。

```xml
<property name="interceptors">
	<list>
    	<ref local="themeChangeInterceptor"/>
    </list>
</property>
```

初始化过程也是根据用户的配置进行IOC初始化后，在这里通过getBean方式调用。

```java
private void initThemeResolver(ApplicationContext context) {
		try {
			this.themeResolver = context.getBean(THEME_RESOLVER_BEAN_NAME, ThemeResolver.class);
			if (logger.isDebugEnabled()) {
				logger.debug("Using ThemeResolver [" + this.themeResolver + "]");
			}
		}
  ... 
```

###### initHandlerMappings

handlermapping 主要的工作就是将用户请求的Request中URL与Controller中的方法进行映射。

先了解初始化内容

```java
private void initHandlerMappings(ApplicationContext context) {
		this.handlerMappings = null;

		if (this.detectAllHandlerMappings) {
			// Find all HandlerMappings in the ApplicationContext, including ancestor contexts.
			Map<String, HandlerMapping> matchingBeans =
					BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerMapping.class, true, false);
			if (!matchingBeans.isEmpty()) {
				this.handlerMappings = new ArrayList<>(matchingBeans.values());
				// We keep HandlerMappings in sorted order.
				AnnotationAwareOrderComparator.sort(this.handlerMappings);
			}
		}
		else {
			try {
				HandlerMapping hm = context.getBean(HANDLER_MAPPING_BEAN_NAME, HandlerMapping.class);
				this.handlerMappings = Collections.singletonList(hm);
			}
			catch (NoSuchBeanDefinitionException ex) {
				// Ignore, we'll add a default HandlerMapping later.
			}
		}

		// Ensure we have at least one HandlerMapping, by registering
		// a default HandlerMapping if no other mappings are found.
		if (this.handlerMappings == null) {
			this.handlerMappings = getDefaultStrategies(context, HandlerMapping.class);
			if (logger.isDebugEnabled()) {
				logger.debug("No HandlerMappings found in servlet '" + getServletName() + "': using default");
			}
		}
	}
```

首先会判断`detectAllHandlerMappings`这个标识，这个是判断用户是想加载所有的实现HandlerMapping接口的bean，还是期望Spring加载指定的HandlerMapping的判断。默认为true，加载全部的。如果想加载指定需要在web.xml中的DispatcherServlet中配置初始参数

```xml
<init-param>
	<param-name>detectAllHandlerMappings</param-name>
    <param-value>false</param-value>
</init-param>
```

我们先走加载全部的路线,会通过`BeanFactoryUtils`中的`beansOfTypeIncludingAncestors`方法进行查找。

```java
public static <T> Map<String, T> beansOfTypeIncludingAncestors(
			ListableBeanFactory lbf, Class<T> type, boolean includeNonSingletons, boolean allowEagerInit)
			throws BeansException {

		Assert.notNull(lbf, "ListableBeanFactory must not be null");
		Map<String, T> result = new LinkedHashMap<>(4);
		result.putAll(lbf.getBeansOfType(type, includeNonSingletons, allowEagerInit));
		if (lbf instanceof HierarchicalBeanFactory) {
			HierarchicalBeanFactory hbf = (HierarchicalBeanFactory) lbf;
			if (hbf.getParentBeanFactory() instanceof ListableBeanFactory) {
				Map<String, T> parentResult = beansOfTypeIncludingAncestors(
						(ListableBeanFactory) hbf.getParentBeanFactory(), type, includeNonSingletons, allowEagerInit);
				parentResult.forEach((beanName, beanType) -> {
					if (!result.containsKey(beanName) && !hbf.containsLocalBean(beanName)) {
						result.put(beanName, beanType);
					}
				});
			}
		}
		return result;
	}
```

首先会根据type类型来获取到所有的bean实例。其中type为传入类型`HandlerMapping.class`。

然后判断如果是IOC容器是`HierarchicalBeanFactory`类型的会再获取上级容器，再进行获取beans。然后都放入到一个集合中返回。

获取到这些beans后会放入到handlerMappings集合中。然后会通过Comparator方式进行排序。

这个其实就是获取HandlerMapping映射器。因为有多种映射器，获取到配置的所有映射器。

如果是加载指定的路线为

```java
	try {
				HandlerMapping hm = context.getBean(HANDLER_MAPPING_BEAN_NAME, HandlerMapping.class);
				this.handlerMappings = Collections.singletonList(hm);
			}
```

获取key是`handlerMapping`的HandlerMapping.class类型的beans，然后放入handlerMappings集合中。这里需要注意使用了Collections.singletonList(hm);做了处理，目的就是返回一个不可变的列表，一个只读的内容。这样就不会存在线程安全问题。

最后如果都没有找到配置的映射器，则获取默认的映射器，通过`getDefaultStrategies`方法。

```java
protected <T> List<T> getDefaultStrategies(ApplicationContext context, Class<T> strategyInterface) {
		String key = strategyInterface.getName();
		String value = defaultStrategies.getProperty(key);
		if (value != null) {
			String[] classNames = StringUtils.commaDelimitedListToStringArray(value);
			List<T> strategies = new ArrayList<>(classNames.length);
			for (String className : classNames) {
				try {
					Class<?> clazz = ClassUtils.forName(className, DispatcherServlet.class.getClassLoader());
					Object strategy = createDefaultStrategy(context, clazz);
					strategies.add((T) strategy);
				}
				catch (ClassNotFoundException ex) {
					throw new BeanInitializationException(
							"Could not find DispatcherServlet's default strategy class [" + className +
							"] for interface [" + key + "]", ex);
				}
				catch (LinkageError err) {
					throw new BeanInitializationException(
							"Unresolvable class definition for DispatcherServlet's default strategy class [" +
							className + "] for interface [" + key + "]", err);
				}
			}
			return strategies;
		}
		else {
			return new LinkedList<>();
		}
	}
```

会读取`DispatcherServlet.properties`文件内的映射器,然后通过实例返回。

```properties
org.springframework.web.servlet.HandlerMapping=org.springframework.web.servlet.handler.BeanNameUrlHandlerMapping,\
	org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping
```

###### initHandlerAdapters

HandlerAdapters的作用是对请求方法的参数及类型与用户的传参进行相应的匹配工作。

先了解初始化内容

```java
private void initHandlerAdapters(ApplicationContext context) {
		this.handlerAdapters = null;

		if (this.detectAllHandlerAdapters) {
			// Find all HandlerAdapters in the ApplicationContext, including ancestor contexts.
			Map<String, HandlerAdapter> matchingBeans =
					BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerAdapter.class, true, false);
			if (!matchingBeans.isEmpty()) {
				this.handlerAdapters = new ArrayList<>(matchingBeans.values());
				// We keep HandlerAdapters in sorted order.
				AnnotationAwareOrderComparator.sort(this.handlerAdapters);
			}
		}
		else {
			try {
				HandlerAdapter ha = context.getBean(HANDLER_ADAPTER_BEAN_NAME, HandlerAdapter.class);
				this.handlerAdapters = Collections.singletonList(ha);
			}
			catch (NoSuchBeanDefinitionException ex) {
				// Ignore, we'll add a default HandlerAdapter later.
			}
		}

		// Ensure we have at least some HandlerAdapters, by registering
		// default HandlerAdapters if no other adapters are found.
		if (this.handlerAdapters == null) {
			this.handlerAdapters = getDefaultStrategies(context, HandlerAdapter.class);
			if (logger.isDebugEnabled()) {
				logger.debug("No HandlerAdapters found in servlet '" + getServletName() + "': using default");
			}
		}
	}
```

看完代码发现，其实这里与`initHandlerMappings`的处理逻辑雷同。也是存在一个标识`detectAllHandlerAdapters`判断是加载所有HandlerAdapter类型的beans还是指定的beans。

这个其实就是获取HandlerAdapter适配器。因为有多种适配器器，获取到配置的所有适配器。

###### initHandlerExceptionResolvers

HandlerExceptionResolvers 主要是对异常的处理。

###### initRequestToViewNameTranslator

可以在处理器返回的View为空时使用它根据Request获取viewName。 

###### initViewResolvers

根据ModelAndView选择合适的视图进行渲染。

在xml中可以对ViewResolvers进行配置

```xml
<bean class="org.Springframework.web.servlet.view.InternalResourceViewResolver">
	<property name="prefix" value="/web-inf/views" />
    <property name="suffix" value=".jsp" />
</bean>
```

看一下初始化代码

```java
private void initViewResolvers(ApplicationContext context) {
		this.viewResolvers = null;

		if (this.detectAllViewResolvers) {
			// Find all ViewResolvers in the ApplicationContext, including ancestor contexts.
			Map<String, ViewResolver> matchingBeans =
					BeanFactoryUtils.beansOfTypeIncludingAncestors(context, ViewResolver.class, true, false);
			if (!matchingBeans.isEmpty()) {
				this.viewResolvers = new ArrayList<>(matchingBeans.values());
				// We keep ViewResolvers in sorted order.
				AnnotationAwareOrderComparator.sort(this.viewResolvers);
			}
		}
		else {
			try {
				ViewResolver vr = context.getBean(VIEW_RESOLVER_BEAN_NAME, ViewResolver.class);
				this.viewResolvers = Collections.singletonList(vr);
			}
			catch (NoSuchBeanDefinitionException ex) {
				// Ignore, we'll add a default ViewResolver later.
			}
		}

		// Ensure we have at least one ViewResolver, by registering
		// a default ViewResolver if no other resolvers are found.
		if (this.viewResolvers == null) {
			this.viewResolvers = getDefaultStrategies(context, ViewResolver.class);
			if (logger.isDebugEnabled()) {
				logger.debug("No ViewResolvers found in servlet '" + getServletName() + "': using default");
			}
		}
	}
```

获取到所有的视图解析器，与上面逻辑雷同。

###### initFlashMapManager

Spring MVC中 Flash attributes提供了一个请求存储属性，在重定向之前暂存，以便重定向之后还能使用。

而FlashMap 保存Flash attributes，FlashMapManager保存FlashMap 。



### 请求过程

请求入口根据Servlet特性，执行do方法调用，doGet或doPost等。DispatcherServlet中无实现，所以看父类FarmeWorkServlet中。

```java
	protected final void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		processRequest(request, response);
	}

	protected final void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		processRequest(request, response);
	}
```

具体调用都一样，看一下`processRequest`处理

```java
protected final void processRequest(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		long startTime = System.currentTimeMillis();
		Throwable failureCause = null;

		LocaleContext previousLocaleContext = LocaleContextHolder.getLocaleContext();
		LocaleContext localeContext = buildLocaleContext(request);

		RequestAttributes previousAttributes = RequestContextHolder.getRequestAttributes();
		ServletRequestAttributes requestAttributes = buildRequestAttributes(request, response, previousAttributes);

		WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);
		asyncManager.registerCallableInterceptor(FrameworkServlet.class.getName(), new RequestBindingInterceptor());

		initContextHolders(request, localeContext, requestAttributes);

		try {
			doService(request, response);
		}
		catch (ServletException | IOException ex) {
			failureCause = ex;
			throw ex;
		}
		catch (Throwable ex) {
			failureCause = ex;
			throw new NestedServletException("Request processing failed", ex);
		}

		finally {
			resetContextHolders(request, previousLocaleContext, previousAttributes);
			if (requestAttributes != null) {
				requestAttributes.requestCompleted();
			}

			if (logger.isDebugEnabled()) {
				if (failureCause != null) {
					this.logger.debug("Could not complete request", failureCause);
				}
				else {
					if (asyncManager.isConcurrentHandlingStarted()) {
						logger.debug("Leaving response open for concurrent processing");
					}
					else {
						this.logger.debug("Successfully completed request");
					}
				}
			}

			publishRequestHandledEvent(request, response, startTime, failureCause);
		}
	}
```

* 首先保证当前线程的 localeContext以及RequestAttributes可以在当前请求后还能恢复，提取当前线程的两个属性。
* 根据当前Request创建对应的 localeContext以及RequestAttributes，并绑定到当前线程。
* 执行doService
* 恢复线程到原始状态
* 发布事件通知

继续了解doService方法，会调DispatcherServlet中的doService方法

#### doService

```java
protected void doService(HttpServletRequest request, HttpServletResponse response) throws Exception {
		if (logger.isDebugEnabled()) {
			String resumed = WebAsyncUtils.getAsyncManager(request).hasConcurrentResult() ? " resumed" : "";
			logger.debug("DispatcherServlet with name '" + getServletName() + "'" + resumed +
					" processing " + request.getMethod() + " request for [" + getRequestUri(request) + "]");
		}

		// Keep a snapshot of the request attributes in case of an include,
		// to be able to restore the original attributes after the include.
		Map<String, Object> attributesSnapshot = null;
		if (WebUtils.isIncludeRequest(request)) {
			attributesSnapshot = new HashMap<>();
			Enumeration<?> attrNames = request.getAttributeNames();
			while (attrNames.hasMoreElements()) {
				String attrName = (String) attrNames.nextElement();
				if (this.cleanupAfterInclude || attrName.startsWith(DEFAULT_STRATEGIES_PREFIX)) {
					attributesSnapshot.put(attrName, request.getAttribute(attrName));
				}
			}
		}

		// Make framework objects available to handlers and view objects.
		request.setAttribute(WEB_APPLICATION_CONTEXT_ATTRIBUTE, getWebApplicationContext());
		request.setAttribute(LOCALE_RESOLVER_ATTRIBUTE, this.localeResolver);
		request.setAttribute(THEME_RESOLVER_ATTRIBUTE, this.themeResolver);
		request.setAttribute(THEME_SOURCE_ATTRIBUTE, getThemeSource());

		if (this.flashMapManager != null) {
			FlashMap inputFlashMap = this.flashMapManager.retrieveAndUpdate(request, response);
			if (inputFlashMap != null) {
				request.setAttribute(INPUT_FLASH_MAP_ATTRIBUTE, Collections.unmodifiableMap(inputFlashMap));
			}
			request.setAttribute(OUTPUT_FLASH_MAP_ATTRIBUTE, new FlashMap());
			request.setAttribute(FLASH_MAP_MANAGER_ATTRIBUTE, this.flashMapManager);
		}

		try {
			doDispatch(request, response);
		}
		finally {
			if (!WebAsyncUtils.getAsyncManager(request).isConcurrentHandlingStarted()) {
				// Restore the original attribute snapshot, in case of an include.
				if (attributesSnapshot != null) {
					restoreAttributesAfterInclude(request, attributesSnapshot);
				}
			}
		}
	}
```

这里面主要是做一些初始化工作，然后调用处理方法doDispatch,这个是整个请求的核心处理方法。

#### doDispatch

```java
protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
		HttpServletRequest processedRequest = request;
		HandlerExecutionChain mappedHandler = null;
		boolean multipartRequestParsed = false;

		WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);

		try {
			ModelAndView mv = null;
			Exception dispatchException = null;

			try {
				processedRequest = checkMultipart(request);
				multipartRequestParsed = (processedRequest != request);

				// Determine handler for the current request.
				mappedHandler = getHandler(processedRequest);
				if (mappedHandler == null) {
					noHandlerFound(processedRequest, response);
					return;
				}

				// Determine handler adapter for the current request.
				HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());

				// Process last-modified header, if supported by the handler.
				String method = request.getMethod();
				boolean isGet = "GET".equals(method);
				if (isGet || "HEAD".equals(method)) {
					long lastModified = ha.getLastModified(request, mappedHandler.getHandler());
					if (logger.isDebugEnabled()) {
						logger.debug("Last-Modified value for [" + getRequestUri(request) + "] is: " + lastModified);
					}
					if (new ServletWebRequest(request, response).checkNotModified(lastModified) && isGet) {
						return;
					}
				}

				if (!mappedHandler.applyPreHandle(processedRequest, response)) {
					return;
				}

				// Actually invoke the handler.
				mv = ha.handle(processedRequest, response, mappedHandler.getHandler());

				if (asyncManager.isConcurrentHandlingStarted()) {
					return;
				}

				applyDefaultViewName(processedRequest, mv);
				mappedHandler.applyPostHandle(processedRequest, response, mv);
			}
			catch (Exception ex) {
				dispatchException = ex;
			}
			catch (Throwable err) {
				// As of 4.3, we're processing Errors thrown from handler methods as well,
				// making them available for @ExceptionHandler methods and other scenarios.
				dispatchException = new NestedServletException("Handler dispatch failed", err);
			}
			processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
		}
		catch (Exception ex) {
			triggerAfterCompletion(processedRequest, response, mappedHandler, ex);
		}
		catch (Throwable err) {
			triggerAfterCompletion(processedRequest, response, mappedHandler,
					new NestedServletException("Handler processing failed", err));
		}
		finally {
			if (asyncManager.isConcurrentHandlingStarted()) {
				// Instead of postHandle and afterCompletion
				if (mappedHandler != null) {
					mappedHandler.applyAfterConcurrentHandlingStarted(processedRequest, response);
				}
			}
			else {
				// Clean up any resources used by a multipart request.
				if (multipartRequestParsed) {
					cleanupMultipart(processedRequest);
				}
			}
		}
	}
```

##### checkMultipart

首先检查Multipart处理，是否有上传文件请求。

```java
protected HttpServletRequest checkMultipart(HttpServletRequest request) throws MultipartException {
		if (this.multipartResolver != null && this.multipartResolver.isMultipart(request)) {
			if (WebUtils.getNativeRequest(request, MultipartHttpServletRequest.class) != null) {
				logger.debug("Request is already a MultipartHttpServletRequest - if not in a forward, " +
						"this typically results from an additional MultipartFilter in web.xml");
			}
			else if (hasMultipartException(request) ) {
				logger.debug("Multipart resolution failed for current request before - " +
						"skipping re-resolution for undisturbed error rendering");
			}
			else {
				try {
					return this.multipartResolver.resolveMultipart(request);
				}
				catch (MultipartException ex) {
					if (request.getAttribute(WebUtils.ERROR_EXCEPTION_ATTRIBUTE) != null) {
						logger.debug("Multipart resolution failed for error dispatch", ex);
						// Keep processing error dispatch with regular request handle below
					}
					else {
						throw ex;
					}
				}
			}
		}
		// If not returned before: return original request.
		return request;
	}
```

首先判断如果存在multipartResolver解析器并且当前请求中有上传文件请求，则通过`this.multipartResolver.resolveMultipart(request)`进行解析。否则不做请求，直接将request内容返回。

##### getHandler

然后通过HandlerMapping获取对应handler

```java
protected HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception {
		if (this.handlerMappings != null) {
			for (HandlerMapping hm : this.handlerMappings) {
				if (logger.isTraceEnabled()) {
					logger.trace(
							"Testing handler map [" + hm + "] in DispatcherServlet with name '" + getServletName() + "'");
				}
				HandlerExecutionChain handler = hm.getHandler(request);
				if (handler != null) {
					return handler;
				}
			}
		}
		return null;
	}
```

通过初始化时设置的`handlerMappings`，遍历使用映射器来执行其中的`getHandler`方法。会调用抽象类。

```java
public final HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception {
		Object handler = getHandlerInternal(request);
		if (handler == null) {
			handler = getDefaultHandler();
		}
		if (handler == null) {
			return null;
		}
		// Bean name or resolved handler?
		if (handler instanceof String) {
			String handlerName = (String) handler;
			handler = obtainApplicationContext().getBean(handlerName);
		}

		HandlerExecutionChain executionChain = getHandlerExecutionChain(handler, request);
		if (CorsUtils.isCorsRequest(request)) {
			CorsConfiguration globalConfig = this.globalCorsConfigSource.getCorsConfiguration(request);
			CorsConfiguration handlerConfig = getCorsConfiguration(handler, request);
			CorsConfiguration config = (globalConfig != null ? globalConfig.combine(handlerConfig) : handlerConfig);
			executionChain = getCorsHandlerExecutionChain(request, executionChain, config);
		}
		return executionChain;
	}

```

首先获取handler

```java
protected Object getHandlerInternal(HttpServletRequest request) throws Exception {
		String lookupPath = getUrlPathHelper().getLookupPathForRequest(request);
		Object handler = lookupHandler(lookupPath, request);
		if (handler == null) {
			// We need to care for the default handler directly, since we need to
			// expose the PATH_WITHIN_HANDLER_MAPPING_ATTRIBUTE for it as well.
			Object rawHandler = null;
			if ("/".equals(lookupPath)) {
				rawHandler = getRootHandler();
			}
			if (rawHandler == null) {
				rawHandler = getDefaultHandler();
			}
			if (rawHandler != null) {
				// Bean name or resolved handler?
				if (rawHandler instanceof String) {
					String handlerName = (String) rawHandler;
					rawHandler = obtainApplicationContext().getBean(handlerName);
				}
				validateHandler(rawHandler, request);
				handler = buildPathExposingHandler(rawHandler, lookupPath, lookupPath, null);
			}
		}
		if (handler != null && logger.isDebugEnabled()) {
			logger.debug("Mapping [" + lookupPath + "] to " + handler);
		}
		else if (handler == null && logger.isTraceEnabled()) {
			logger.trace("No handler mapping found for [" + lookupPath + "]");
		}
		return handler;
	}
```

先截取url的有效路径，然后根据路径进行获取，通过`lookupHandler`方法。

```java
protected Object lookupHandler(String urlPath, HttpServletRequest request) throws Exception {
		// Direct match?
		Object handler = this.handlerMap.get(urlPath);
		if (handler != null) {
			// Bean name or resolved handler?
			if (handler instanceof String) {
				String handlerName = (String) handler;
				handler = obtainApplicationContext().getBean(handlerName);
			}
			validateHandler(handler, request);
			return buildPathExposingHandler(handler, urlPath, urlPath, null);
		}

		// Pattern match?
		List<String> matchingPatterns = new ArrayList<>();
		for (String registeredPattern : this.handlerMap.keySet()) {
			if (getPathMatcher().match(registeredPattern, urlPath)) {
				matchingPatterns.add(registeredPattern);
			}
			else if (useTrailingSlashMatch()) {
				if (!registeredPattern.endsWith("/") && getPathMatcher().match(registeredPattern + "/", urlPath)) {
					matchingPatterns.add(registeredPattern +"/");
				}
			}
		}

		String bestMatch = null;
		Comparator<String> patternComparator = getPathMatcher().getPatternComparator(urlPath);
		if (!matchingPatterns.isEmpty()) {
			matchingPatterns.sort(patternComparator);
			if (logger.isDebugEnabled()) {
				logger.debug("Matching patterns for request [" + urlPath + "] are " + matchingPatterns);
			}
			bestMatch = matchingPatterns.get(0);
		}
		if (bestMatch != null) {
			handler = this.handlerMap.get(bestMatch);
			if (handler == null) {
				if (bestMatch.endsWith("/")) {
					handler = this.handlerMap.get(bestMatch.substring(0, bestMatch.length() - 1));
				}
				if (handler == null) {
					throw new IllegalStateException(
							"Could not find handler for best pattern match [" + bestMatch + "]");
				}
			}
			// Bean name or resolved handler?
			if (handler instanceof String) {
				String handlerName = (String) handler;
				handler = obtainApplicationContext().getBean(handlerName);
			}
			validateHandler(handler, request);
			String pathWithinMapping = getPathMatcher().extractPathWithinPattern(bestMatch, urlPath);

			// There might be multiple 'best patterns', let's make sure we have the correct URI template variables
			// for all of them
			Map<String, String> uriTemplateVariables = new LinkedHashMap<>();
			for (String matchingPattern : matchingPatterns) {
				if (patternComparator.compare(bestMatch, matchingPattern) == 0) {
					Map<String, String> vars = getPathMatcher().extractUriTemplateVariables(matchingPattern, urlPath);
					Map<String, String> decodedVars = getUrlPathHelper().decodePathVariables(request, vars);
					uriTemplateVariables.putAll(decodedVars);
				}
			}
			if (logger.isDebugEnabled()) {
				logger.debug("URI Template variables for request [" + urlPath + "] are " + uriTemplateVariables);
			}
			return buildPathExposingHandler(handler, bestMatch, pathWithinMapping, uriTemplateVariables);
		}

		// No handler found...
		return null;
	}
```

首先是从`handlerMap`这个集合中判断获取，但是这个集合是什么时候进行的赋值呢？

###### 了解HandlerMapping初始化过程

根据代码调用情况，找到了最初的调用是通过`AbstractDetectingUrlHandlerMapping`中的`initApplicationContext`方法。

首先需要看一下`ApplicationObjectSupport`这个类

```java
public abstract class ApplicationObjectSupport implements ApplicationContextAware 
```

它实现了`ApplicationContextAware `接口，所以初始化的时候会调用`setApplicationContext`方法。

其中会调用`initApplicationContext`方法。而子类``AbstractDetectingUrlHandlerMapping``中实现了该方法，所以直接看这个方法。

```java
public void initApplicationContext() throws ApplicationContextException {
		super.initApplicationContext();
		detectHandlers();
	}
...
protected void detectHandlers() throws BeansException {
		ApplicationContext applicationContext = obtainApplicationContext();
		if (logger.isDebugEnabled()) {
			logger.debug("Looking for URL mappings in application context: " + applicationContext);
		}
		String[] beanNames = (this.detectHandlersInAncestorContexts ?
				BeanFactoryUtils.beanNamesForTypeIncludingAncestors(applicationContext, Object.class) :
				applicationContext.getBeanNamesForType(Object.class));

		// Take any bean name that we can determine URLs for.
		for (String beanName : beanNames) {
			String[] urls = determineUrlsForHandler(beanName);
			if (!ObjectUtils.isEmpty(urls)) {
				// URL paths found: Let's consider it a handler.
				registerHandler(urls, beanName);
			}
			else {
				if (logger.isDebugEnabled()) {
					logger.debug("Rejected bean name '" + beanName + "': no URL paths identified");
				}
			}
		}
	}
```

获取到所有的bean，然后通过遍历执行`determineUrlsForHandler`，进行处理转化成url

```java
protected String[] determineUrlsForHandler(String beanName) {
		List<String> urls = new ArrayList<>();
		if (beanName.startsWith("/")) {
			urls.add(beanName);
		}
		String[] aliases = obtainApplicationContext().getAliases(beanName);
		for (String alias : aliases) {
			if (alias.startsWith("/")) {
				urls.add(alias);
			}
		}
		return StringUtils.toStringArray(urls);
	}
```

**这个地方有问题，为什么判断是否已/开始呢，按理说beanName中有/吗？**

获取有效url路径，通过`registerHandler`方法进行处理

```java
protected void registerHandler(String[] urlPaths, String beanName) throws BeansException, IllegalStateException {
		Assert.notNull(urlPaths, "URL path array must not be null");
		for (String urlPath : urlPaths) {
			registerHandler(urlPath, beanName);
		}
	}
...
protected void registerHandler(String urlPath, Object handler) throws BeansException, IllegalStateException {
		Assert.notNull(urlPath, "URL path must not be null");
		Assert.notNull(handler, "Handler object must not be null");
		Object resolvedHandler = handler;

		// Eagerly resolve handler if referencing singleton via name.
		if (!this.lazyInitHandlers && handler instanceof String) {
			String handlerName = (String) handler;
			ApplicationContext applicationContext = obtainApplicationContext();
			if (applicationContext.isSingleton(handlerName)) {
				resolvedHandler = applicationContext.getBean(handlerName);
			}
		}

		Object mappedHandler = this.handlerMap.get(urlPath);
		if (mappedHandler != null) {
			if (mappedHandler != resolvedHandler) {
				throw new IllegalStateException(
						"Cannot map " + getHandlerDescription(handler) + " to URL path [" + urlPath +
						"]: There is already " + getHandlerDescription(mappedHandler) + " mapped.");
			}
		}
		else {
			if (urlPath.equals("/")) {
				if (logger.isInfoEnabled()) {
					logger.info("Root mapping to " + getHandlerDescription(handler));
				}
				setRootHandler(resolvedHandler);
			}
			else if (urlPath.equals("/*")) {
				if (logger.isInfoEnabled()) {
					logger.info("Default mapping to " + getHandlerDescription(handler));
				}
				setDefaultHandler(resolvedHandler);
			}
			else {
				this.handlerMap.put(urlPath, resolvedHandler);
				if (logger.isInfoEnabled()) {
					logger.info("Mapped URL path [" + urlPath + "] onto " + getHandlerDescription(handler));
				}
			}
		}
	}
```

其中逻辑首先对bean进行依赖注入，然后根据判断如果url不是"/"或“/*”,将url与对于bean存入集合。



继续回到上面分析，如果根据url获取到了对于handler。然后进行getbean依赖注入，之后调用`buildPathExposingHandler`方法

```java
protected Object buildPathExposingHandler(Object rawHandler, String bestMatchingPattern,
			String pathWithinMapping, @Nullable Map<String, String> uriTemplateVariables) {

		HandlerExecutionChain chain = new HandlerExecutionChain(rawHandler);
		chain.addInterceptor(new PathExposingHandlerInterceptor(bestMatchingPattern, pathWithinMapping));
		if (!CollectionUtils.isEmpty(uriTemplateVariables)) {
			chain.addInterceptor(new UriTemplateVariablesHandlerInterceptor(uriTemplateVariables));
		}
		return chain;
	}
```

这里是对handler对象构建个HandlerExecutionChain类型实例，然后加入两个拦截器，形成一个链路处理机制。

再回到上面如果集合中没有找到handler，则会遍历集合，做正则匹配操作。最后匹配的再执行上面的过程。

再回到上面执行`getHandlerExecutionChain`这个方法。

```java
protected HandlerExecutionChain getHandlerExecutionChain(Object handler, HttpServletRequest request) {
		HandlerExecutionChain chain = (handler instanceof HandlerExecutionChain ?
				(HandlerExecutionChain) handler : new HandlerExecutionChain(handler));

		String lookupPath = this.urlPathHelper.getLookupPathForRequest(request);
		for (HandlerInterceptor interceptor : this.adaptedInterceptors) {
			if (interceptor instanceof MappedInterceptor) {
				MappedInterceptor mappedInterceptor = (MappedInterceptor) interceptor;
				if (mappedInterceptor.matches(lookupPath, this.pathMatcher)) {
					chain.addInterceptor(mappedInterceptor.getInterceptor());
				}
			}
			else {
				chain.addInterceptor(interceptor);
			}
		}
		return chain;
	}
```

这个方法中是做了对于的拦截器加入执行链。

这样就将url对于的controller返回给前面。

但是如果最后没有找到handler，会调用`noHandlerFound`方法

```java
protected void noHandlerFound(HttpServletRequest request, HttpServletResponse response) throws Exception {
		if (pageNotFoundLogger.isWarnEnabled()) {
			pageNotFoundLogger.warn("No mapping found for HTTP request with URI [" + getRequestUri(request) +
					"] in DispatcherServlet with name '" + getServletName() + "'");
		}
		if (this.throwExceptionIfNoHandlerFound) {
			throw new NoHandlerFoundException(request.getMethod(), getRequestUri(request),
					new ServletServerHttpRequest(request).getHeaders());
		}
		else {
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
		}
	}
```

这里的逻辑就是是否有设置默认的handler处理，没有就返回错误信息。

##### getHandlerAdapter

获取到handler后要做的就是寻找对于的HandlerAdapter

```java
protected HandlerAdapter getHandlerAdapter(Object handler) throws ServletException {
		if (this.handlerAdapters != null) {
			for (HandlerAdapter ha : this.handlerAdapters) {
				if (logger.isTraceEnabled()) {
					logger.trace("Testing handler adapter [" + ha + "]");
				}
				if (ha.supports(handler)) {
					return ha;
				}
			}
		}
		throw new ServletException("No adapter for handler [" + handler +
				"]: The DispatcherServlet configuration needs to include a HandlerAdapter that supports this handler");
	}
```

首先依然是判断初始化阶段是否设置了适配器，遍历适配器，然后执行`supports`方法

```java
public final boolean supports(Object handler) {
		return (handler instanceof HandlerMethod && supportsInternal((HandlerMethod) handler));
	}
```

判断具体适配器支持handler则返回这个适配器

##### 缓存处理 Last-Modified缓存机制

* 当客户端第一次输入URL时，服务器端会返回内容和状态码200，表示请求成功，同时会添加一个“last_Modified”的响应头，表示文件再服务器上的最后更新时间。
* 客户端第二次请求此URL时，客户端会向服务器发送请求头“if-modified-since”,询问服务器该时间之后当前请求是否有被修改过，如果服务端内容没有变化，则会自动返回http 304状态码

Spring提供了对last-modified机制的支撑。

所以存在下面这样的判断处理

```java
boolean isGet = "GET".equals(method);
if (isGet || "HEAD".equals(method)) {
       long lastModified = ha.getLastModified(request, mappedHandler.getHandler());
    ...
}
```

如果是get和head请求，看检查这个handler（Controller）是否实现了Lastmodified接口。检查内容是否发生改变。

##### applyPreHandle 拦截器应用

Spring提供了标准的拦截器接口 HandlerInterceptor，如果想自定义拦截器需要实现这个接口。这个接口它包含三个方法：

* preHandle（）     程序处理请求之前调用
* postHandle（）   程序处理请求之后调用 ，这里还允许返回ModelAndView类型
* afterCompletion（）   所以请求处理完成之后调用

而具体这三个不同时期的处理就是在这个代码里进行设置的。

```java
// preHandle 调用
if (!mappedHandler.applyPreHandle(processedRequest, response)) {
					return;
				}
   //请求处理
	mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
...
//postHandle调用
mappedHandler.applyPostHandle(processedRequest, response, mv);


...
finally {
			if (asyncManager.isConcurrentHandlingStarted()) {
				// Instead of postHandle and afterCompletion
				if (mappedHandler != null) {
                    //最后拦截器的调用
					mappedHandler.applyAfterConcurrentHandlingStarted(processedRequest, response);
				}
			}
    ...
```

##### 具体请求处理

然后通过调用`handle`，开始具体处理

```
mv = ha.handle(processedRequest, response, mappedHandler.getHandler());

public final ModelAndView handle(HttpServletRequest request, HttpServletResponse response, Object handler)
			throws Exception {

		return handleInternal(request, response, (HandlerMethod) handler);
	}
```



```java
protected ModelAndView handleInternal(HttpServletRequest request,
			HttpServletResponse response, HandlerMethod handlerMethod) throws Exception {

		ModelAndView mav;
		checkRequest(request);

		// Execute invokeHandlerMethod in synchronized block if required.
		if (this.synchronizeOnSession) {
			HttpSession session = request.getSession(false);
			if (session != null) {
				Object mutex = WebUtils.getSessionMutex(session);
				synchronized (mutex) {
					mav = invokeHandlerMethod(request, response, handlerMethod);
				}
			}
			else {
				// No HttpSession available -> no mutex necessary
				mav = invokeHandlerMethod(request, response, handlerMethod);
			}
		}
		else {
			// No synchronization on session demanded at all...
			mav = invokeHandlerMethod(request, response, handlerMethod);
		}

		if (!response.containsHeader(HEADER_CACHE_CONTROL)) {
			if (getSessionAttributesHandler(handlerMethod).hasSessionAttributes()) {
				applyCacheSeconds(response, this.cacheSecondsForSessionAttributeHandlers);
			}
			else {
				prepareResponse(response);
			}
		}

		return mav;
	}
```

首先判断是否需要session内同步操作，然后调用处理逻辑`invokeHandlerMethod`。

```java
protected ModelAndView invokeHandlerMethod(HttpServletRequest request,
			HttpServletResponse response, HandlerMethod handlerMethod) throws Exception {

		ServletWebRequest webRequest = new ServletWebRequest(request, response);
		try {
			WebDataBinderFactory binderFactory = getDataBinderFactory(handlerMethod);
			ModelFactory modelFactory = getModelFactory(handlerMethod, binderFactory);

			ServletInvocableHandlerMethod invocableMethod = createInvocableHandlerMethod(handlerMethod);
			if (this.argumentResolvers != null) {
				invocableMethod.setHandlerMethodArgumentResolvers(this.argumentResolvers);
			}
			if (this.returnValueHandlers != null) {
				invocableMethod.setHandlerMethodReturnValueHandlers(this.returnValueHandlers);
			}
			invocableMethod.setDataBinderFactory(binderFactory);
			invocableMethod.setParameterNameDiscoverer(this.parameterNameDiscoverer);

			ModelAndViewContainer mavContainer = new ModelAndViewContainer();
			mavContainer.addAllAttributes(RequestContextUtils.getInputFlashMap(request));
			modelFactory.initModel(webRequest, mavContainer, invocableMethod);
			mavContainer.setIgnoreDefaultModelOnRedirect(this.ignoreDefaultModelOnRedirect);

			AsyncWebRequest asyncWebRequest = WebAsyncUtils.createAsyncWebRequest(request, response);
			asyncWebRequest.setTimeout(this.asyncRequestTimeout);

			WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);
			asyncManager.setTaskExecutor(this.taskExecutor);
			asyncManager.setAsyncWebRequest(asyncWebRequest);
			asyncManager.registerCallableInterceptors(this.callableInterceptors);
			asyncManager.registerDeferredResultInterceptors(this.deferredResultInterceptors);

			if (asyncManager.hasConcurrentResult()) {
				Object result = asyncManager.getConcurrentResult();
				mavContainer = (ModelAndViewContainer) asyncManager.getConcurrentResultContext()[0];
				asyncManager.clearConcurrentResult();
				if (logger.isDebugEnabled()) {
					logger.debug("Found concurrent result value [" + result + "]");
				}
				invocableMethod = invocableMethod.wrapConcurrentResult(result);
			}

			invocableMethod.invokeAndHandle(webRequest, mavContainer);
			if (asyncManager.isConcurrentHandlingStarted()) {
				return null;
			}

			return getModelAndView(mavContainer, modelFactory, webRequest);
		}
		finally {
			webRequest.requestCompleted();
		}
	}
```

这里的操作主要完成的就是将request的参数与方法参数进行数据绑定，然后会调用方法执行。

**需要细入**





