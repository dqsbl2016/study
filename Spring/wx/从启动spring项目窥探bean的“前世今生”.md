## 从启动spring项目窥探bean的“前世今生”

### 预备知识

#### 【1】ServletContextListener

1、定义

在 Servlet API 中有一个 ServletContextListener 接口，它能够监听 ServletContext 对象的生命周期，实际上就是监听 Web 应用的生命周期。

　　当Servlet 容器启动或终止Web 应用时，会触发ServletContextEvent 事件，该事件由ServletContextListener 来处理。在 ServletContextListener 接口中定义了处理ServletContextEvent 事件的两个方法。

  ServletContextListener是对ServeltContext的一个监听.servelt容器启动,serveltContextListener就会调用contextInitialized方法.在方法里面调用event.getServletContext()可以获取ServletContext,ServeltContext是一个上下文对象,他的数据供所有的应用程序共享,进行一些业务的初始化servelt容器关闭,serveltContextListener就会调用contextDestroyed.

  实际上ServeltContextListener是生成ServeltContext对象之后调用的.生成ServeltContext对象之后,这些代码在我们业务实现之前就写好,它怎么知道我们生成类的名字.实际上它并不需要知道我们的类名,类里面有是方法.他们提供一个规范,就一个接口,ServeltContextListner,只要继承这个接口就必须实现这个方法.然后这个类在web.xml中Listener节点配置好.Servelt容器先解析web.xml,获取Listener的值.通过反射生成对象放进缓存.然后创建ServeltContext对象和ServletContextEvent对象.然后在调用ServletContextListener的contextInitialized方法,然后方法可以把用户的业务需求写进去.struts和spring框架就是类似这样的实现,我们以后写一些框架也可以在用.

### 【2】**HttpServlet** 

1、定义

大家都知道Servlet，但是不一定很清楚servlet框架，这个框架是由两个Java包组成:javax.servlet和javax.servlet.http. 在javax.servlet包中定义了所有的Servlet类都必须实现或扩展的的通用接口和类.在javax.servlet.http包中定义了采用HTTP通信协议的HttpServlet类.

Servlet的框架的核心是javax.servlet.Servlet接口,所有的Servlet都必须实现这一接口.在Servlet接口中定义了5个方法,其中有3个方法代表了Servlet的声明周期:

init方法,负责初始化Servlet对象 
service方法,负责相应客户的请求 
destory方法,当Servlet对象退出声明周期时,负责释放占有的资源

### 【3】组件加载顺序

init-param  >>listener>>filter>>servlet





## 开始解析项目加载过程

在接下来就会使用上面介绍的东东了，在项目中通常都会有web.xml配置文件，它是在项目启动过程中被自动加载的，步骤如下

tomcat启动

找到所有实现了servletContextListener接口的实现类，并且调用其初始化方法contextInitialized方法，在我们的项目中可以看到ContextLoadLisener实现了该接口，则在启动过程中就会执行该方法，那么bean的定位、加载初始化、注册过程就此拉开了帷幕

首先要简单看一下类图结构，这个从全局展示了 bean的层次结构 继承关系 实现关系，帮助我们从更高层次去理解它的概念。

1、概览一下切入点的ContextLoaderListener的类图结构

![](C:\Users\ADMINI~1\AppData\Local\Temp\1535299342809.png)

2、实现了初始化方法的定义，在源码中可以看到执行了initWebApplicationContext方法

```java
	/**
	 * Initialize the root web application context.
	 */
	@Override
	public void contextInitialized(ServletContextEvent event) {
		initWebApplicationContext(event.getServletContext());
	}
```

但是在此类中我们没有看到它的实现，那么根据继承关系我们找到了定义它的父类ContextLoader，在此类中实现了该方法的逻辑，那么接下来我们看一下，究竟执行了什么操作，还是源码为依据，一些不重要的我屏蔽了

> ```java
> //判断该应用是否已经初始化了如果有了则抛出异常
> if (servletContext.getAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE) != null) {
> 			throw new IllegalStateException(
> 					"Cannot initialize context because there is already a root application context present - " +
> 					"check whether you have multiple ContextLoader* definitions in your web.xml!");
> 		}
>     
> 		long startTime = System.currentTimeMillis();
> 
> 		try {
> 		             //创建应用上下文
> 			if (this.context == null) {
> 				this.context = createWebApplicationContext(servletContext);
> 			}
> 			if (this.context instanceof ConfigurableWebApplicationContext) {
> 				ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) this.context;
> 				if (!cwac.isActive()) {
> 					// The context has not yet been refreshed -> provide services such as
> 					// setting the parent context, setting the application context id, etc
> 					if (cwac.getParent() == null) {
> 						// The context instance was injected without an explicit parent ->
> 						// determine parent for root web application context, if any.
> 						ApplicationContext parent = loadParentContext(servletContext);
> 						cwac.setParent(parent);
> 					}
>                     //配置刷新web应用上下文【重点】
> 					configureAndRefreshWebApplicationContext(cwac, servletContext);
> 				}
> 			}
> //设置应用根标示，			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, this.context);
> 
> 			ClassLoader ccl = Thread.currentThread().getContextClassLoader();
> 			if (ccl == ContextLoader.class.getClassLoader()) {
> 				currentContext = this.context;
> 			}
> 			else if (ccl != null) {
> 				currentContextPerThread.put(ccl, this.context);
> 			}
> 
> 			return this.context;
> 		}
> 		
> ```

上面定义了初始化方法执行的逻辑 ，在其中执行createWebApplicationContext方法做了什么呢，我们继续跟进代码

```java
	Class<?> contextClass = determineContextClass(sc);
		if (!ConfigurableWebApplicationContext.class.isAssignableFrom(contextClass)) {
			throw new ApplicationContextException("Custom context class [" + contextClass.getName() +
					"] is not of type [" + ConfigurableWebApplicationContext.class.getName() + "]");
		}
		return (ConfigurableWebApplicationContext) BeanUtils.instantiateClass(contextClass);
```







