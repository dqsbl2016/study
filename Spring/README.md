> **My way of study !**

# Spring 

官网: [spring.io](https://spring.io/)

## What is Spring Framework?

Spring是个Java企业级应用的开源开发框架。 它主要解决企业应用开发的复杂性，使团队专注于应用程序级的业务逻辑。

## Why use Spring Framework?

* Spring是一个轻量级框架，对系统开销不大 （随着Spring不断发展，也会变得越来越重）
* 通过依赖注入来实现松耦合（实现动态装配）
* 通过面向切面编程，把应用业务逻辑和系统服务逻辑分离
* Ioc容器统一管理bean生命周期和配置

## How to use Spring Framework?

<center> ![image](https://github.com/dqsbl2016/study/blob/master/Spring/1532486065585.jpg)  </center>

* **核心容器** 由 `spring-beans` ，`spring-core`，`spring-context`，`spring-expression(Spring Expression Language，SpEL)`4个模块组成。 

  >spring-beans 和 spring-core 模块是 Spring 框架的核心模块，包含了控制反转（Inversion of
  >Control, IOC）和依赖注入（Dependency Injection, DI）。BeanFactory 接口是 Spring 框架中
  >的核心接口，它是工厂模式的具体实现。BeanFactory 使用控制反转对应用程序的配置和依赖性规范与
  >实际的应用程序代码进行了分离。但 BeanFactory 容器实例化后并不会自动实例化 Bean，只有当 Bean
  >被使用时 BeanFactory 容器才会对该 Bean 进行实例化与依赖关系的装配。
  >spring-context 模块构架于核心模块之上，他扩展了 BeanFactory，为她添加了 Bean 生命周期
  >控制、框架事件体系以及资源加载透明化等功能。此外该模块还提供了许多企业级支持，如邮件访问、
  >远程访问、任务调度等，ApplicationContext 是该模块的核心接口，她是 BeanFactory 的超类，与
  >BeanFactory 不同，ApplicationContext 容器实例化后会自动对所有的单实例 Bean 进行实例化与
  >依赖关系的装配，使之处于待用状态。
  >spring-expression 模块是统一表达式语言（EL）的扩展模块，可以查询、管理运行中的对象，
  >同时也方便的可以调用对象方法、操作数组、集合等。它的语法类似于传统 EL，但提供了额外的功能，
  >最出色的要数函数调用和简单字符串的模板函数。这种语言的特性是基于 Spring 产品的需求而设计，
  >他可以非常方便地同 Spring IOC 进行交互。

* **Aop和设备支持**  由`spring-aop`，`spring-aspects`,`spring-instrument`3个模块组成。

  >spring-aop 是 Spring 的另一个核心模块，是 AOP 主要的实现模块。作为继 OOP 后，对程序员影
  >响最大的编程思想之一，AOP 极大地开拓了人们对于编程的思路。在 Spring 中，他是以 JVM 的动态代
  >理技术为基础，然后设计出了一系列的 AOP 横切实现，比如前置通知、返回通知、异常通知等，同时，
  >Pointcut 接口来匹配切入点，可以使用现有的切入点来设计横切面，也可以扩展相关方法根据需求进
  >行切入。
  >spring-aspects 模块集成自 AspectJ 框架，主要是为 Spring AOP 提供多种 AOP 实现方法。
  >spring-instrument 模块是基于 JAVA SE 中的"java.lang.instrument"进行设计的，应该算是
  >AOP 的一个支援模块，主要作用是在 JVM 启用时，生成一个代理类，程序员通过代理类在运行时修改类
  >的字节，从而改变一个类的功能，实现 AOP 的功能。

* **数据访问及集成**  由 `spring-jdbc`,`spring-tx`,`spring-orm`,`spring-jms`,`spring-oxm`5个模块组成。

  >spring-jdbc 模块是 Spring 提供的 JDBC 抽象框架的主要实现模块，用于简化 Spring JDBC。主
  >要是提供 JDBC 模板方式、关系数据库对象化方式、SimpleJdbc 方式、事务管理来简化 JDBC 编程，主
  >要实现类是 JdbcTemplate、SimpleJdbcTemplate 以及 NamedParameterJdbcTemplate。
  >
  >spring-tx 模块是 Spring JDBC 事务控制实现模块。使用 Spring 框架，它对事务做了很好的封装，
  >通过它的 AOP 配置，可以灵活的配置在任何一层；但是在很多的需求和应用，直接使用 JDBC 事务控制
  >还是有其优势的。其实，事务是以业务逻辑为基础的；一个完整的业务应该对应业务层里的一个方法；
  >如果业务操作失败，则整个事务回滚；所以，事务控制是绝对应该放在业务层的；但是，持久层的设计
  >则应该遵循一个很重要的原则：保证操作的原子性，即持久层里的每个方法都应该是不可以分割的。所
  >以，在使用 Spring JDBC 事务控制时，应该注意其特殊性。
  >spring-orm 模块是 ORM 框架支持模块，主要集成 Hibernate, Java Persistence API (JPA) 和
  >Java Data Objects (JDO) 用于资源管理、数据访问对象(DAO)的实现和事务策略。
  >spring-jms 模块（Java Messaging Service）能够发送和接受信息，自 Spring Framework 4.1
  >以后，他还提供了对 spring-messaging 模块的支撑。
  >spring-oxm 模块主要提供一个抽象层以支撑 OXM（OXM 是 Object-to-XML-Mapping 的缩写，它是
  >一个 O/M-mapper，将 java 对象映射成 XML 数据，或者将 XML 数据映射成 java 对象），例如：JAXB,
  >Castor, XMLBeans, JiBX 和 XStream 等。

* **Web** 由`spring-web`,`spring-webmvc`,`spring-websocket`,`spring-webflux` 4个模块组成。

  >spring-web 模块为 Spring 提供了最基础 Web 支持，主要建立于核心容器之上，通过 Servlet 或
  >者 Listeners 来初始化 IOC 容器，也包含一些与 Web 相关的支持。
  >spring-webmvc 模 块 众 所 周 知 是 一 个 的 Web-Servlet 模 块 ， 实 现 了 Spring MVC
  >（model-view-Controller）的 Web 应用。
  >spring-websocket 模块主要是与 Web 前端的全双工通讯的协议。（资料缺乏，这是个人理解）
  >spring-webflux 是一个新的非堵塞函数式 Reactive Web 框架，可以用来建立异步的，非阻塞，
  >事件驱动的服务，并且扩展性非常好。

* **报文发送** 即 `spring-messaging`模块。

  >spring-messaging 是从 Spring4 开始新加入的一个模块，主要职责是为 Spring 框架集成一些基
  >础的报文传送应用。

* **Test** 即`spring-test`模块。

  >spring-test 模块主要为测试提供支持的，毕竟在不需要发布（程序）到你的应用服务器或者连接
  >到其他企业设施的情况下能够执行一些集成测试或者其他测试对于任何企业都是非常重要的。



### Spring Ioc











​    

