# Spring IOC

>在Spring应用中，所有的beans生存于Spring容器中，Spring容器负责创建，装配，管理它们的整个生命周期，从生存到死亡，这个容器称为IOC容器。

Spring容器并不是只有一个，可以分为二种类型。

### BeanFactory

  `org.springframework.beans.factory.BeanFactory` 是最简单的容器，提供基本的DI支持。

![1532489938612](C:\Users\ADMINI~1\AppData\Local\Temp\1532489938612.png)

```
其中 BeanFactory 作为最顶层的一个接口类，它定义了 IOC 容器的基本功能规范，BeanFactory 有三个子类：ListableBeanFactory、HierarchicalBeanFactory 和 AutowireCapableBeanFactory。
但是从上图中我们可以发现最终的默认实现类是DefaultListableBeanFactory，他实现了所有的接口。那为何要定义这么多层次的接口呢？查阅这些接口的源码和说明发现，每个接口都有他使用的场合，它主要是为了区分在Spring内部在操作过程中对象的传递和转化过程中，对对象的数据访问所做的限制。例如ListableBeanFactory接口表示这些Bean 是可列表的，而HierarchicalBeanFactory表示的是这些Bean是有继承关系的，也就是每个Bean有可能有父Bean。AutowireCapableBeanFactory接口定义Bean的自动装配规则。这四个接口共同定义了Bean的集合、Bean之间的关系、以及Bean行为.
```

### ApplicationContext

`org.springframework.context.ApplicationContext`基于BeanFactory构建，提供应用框架级别的服务，例如从属性文件解析文本信息以及发布应用事件给事件监听者。

![1532494390919](C:\Users\ADMINI~1\AppData\Local\Temp\1532494390919.png)

``` 
ApplicationContext允许上下文嵌套，通过保持父上下文可以维持一个上下文体系。对于Bean的查找可以在这个上下文体系中发生，首先检查当前上下文，其次是父上下文，逐级向上，这样为不同的Spring应用提供了一个共享的Bean定义环境。
```



## IOC容器初始化，加载上下文

Spring自带了多种类型的应用上下文，其中包括 `FileSystemXmlApplicationContext`,`ClassPathXmlApplicationContext`等。无论哪种方式都是通过调用`AbstractApplicationContext`中的`refresh()`方法开始IOC容器初始化工作。IOC容器的初始化就是`Bean`的`Resource`定位、载入和注册这三个基本的过程。Spring把这三个过程分开，使用不同的模块来完成，通过这样的设计让用户更灵活的对三个过程进行剪裁或扩展，定义出自己最合适的IOC容器初始化过程。

###定位

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

####ResourceLoader

`ResourceLoader`接口定义了一个用于获取`Resource`的`getResource`方法。它包含很多实现类，例如`DefaultResourceLoader`实现的策略是：首先判断指定的`location`是否含有`classpath:`前缀，如果有则把`location`去掉`classpath:`前缀返回对应的`ClassPathResource`；否则就把它当做一个`URL`来处理，封装成一个`UrlResource`进行返回；如果当成`URL`处理也失败的话就把`location`对应的资源当成是一个`ClassPathResource`进行返回。 

`ApplicationContext`接口也继承了`ResourceLoader`接口，所以它的实现类也可以获取`Resource`。

* ***ClassPathXmlApplicationContext* **  它在获取`Resource`时继承的是它的父类`DefaultResourceLoader`的策略。 可以从`Class Path`载入`Resource`。

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

载入过程是把用户定义好的Bean封装成IOC容器内部的数据结构，就是`BeanDefinition`。

####BeanDefinition

Spring IOC容器管理了我们定义的各种Bean对象及相互关系，Bean对象在Spring实现中是以`BeanDefinition`来描述的。