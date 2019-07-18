AOP设计模式通常运用在日志，校验等业务场景，本文将简单介绍基于Spring的AOP代理模式的运用。

## 1. 代理模式

### 1.1 概念

代理(Proxy)是一种提供了对目标对象另外的访问方式，即通过代理对象访问目标对象。这样做的好处是:可以在目标对象实现的基础上，增强额外的功能操作，即扩展目标对象的功能。
这里使用到编程中的一个思想：不要随意去修改别人已经写好的代码或者方法，如果需改修改,可以通过代理的方式来扩展该方法。

### 1.2 静态代理

静态代理在使用时,需要定义接口或者父类，被代理对象与代理对象一起实现相同的接口或者是继承相同父类。

### 1.3 动态代理

#### 1.3.1 JDK代理

JDK动态代理有以下特点:
1.代理对象，不需要实现接口
2.代理对象的生成,是利用JDK的API,动态的在内存中构建代理对象(需要我们指定创建代理对象/目标对象实现的接口的类型)
3.动态代理也叫做:JDK代理,接口代理

#### 1.3.2 CGLib代理

Cglib代理,也叫作子类代理,它是在内存中构建一个子类对象从而实现对目标对象功能的扩展。

1. JDK的动态代理有一个限制,就是使用动态代理的对象必须实现一个或多个接口，如果想代理没有实现接口的类,就可以使用Cglib实现。
2. Cglib是一个强大的高性能的代码生成包，它可以在运行期扩展java类与实现java接口。它广泛的被许多AOP的框架使用，例如Spring AOP和synaop,为他们提供方法的interception(拦截)。
3. Cglib包的底层是通过使用一个小而块的字节码处理框架ASM来转换字节码并生成新的类。不鼓励直接使用ASM，因为它要求你必须对JVM内部结构包括class文件的格式和指令集都很熟悉。

## 2. Spring AOP

### 2.1 Spring AOP原理

AOP实现的关键在于AOP框架自动创建的AOP代理，AOP代理主要分为静态代理和动态代理，**静态代理的代表为AspectJ；而动态代理则以Spring AOP为代表**。本文以Spring AOP的实现进行分析和介绍。

Spring AOP使用的动态代理，所谓的动态代理就是说AOP框架不会去修改字节码，而是在内存中临时为方法生成一个AOP对象，这个AOP对象包含了目标对象的全部方法，并且在特定的切点做了增强处理，并回调原对象的方法。

Spring AOP中的动态代理主要有两种方式，`JDK动态代理`和`CGLIB动态代理`。JDK动态代理通过反射来接收被代理的类，并且要求被代理的类必须实现一个接口。JDK动态代理的核心是`InvocationHandler`接口和`Proxy`类。

如果目标类没有实现接口，那么Spring AOP会选择使用CGLIB来动态代理目标类。CGLIB（Code Generation Library），是一个代码生成的类库，可以在运行时动态的生成某个类的子类，注意，CGLIB是通过继承的方式做的动态代理，因此如果某个类被标记为`final`，那么它是无法使用CGLIB做动态代理的。

> 注意：以上片段引用自文章[Spring AOP的实现原理](http://www.importnew.com/24305.html)，如有冒犯，请联系笔者删除之，谢谢！

Spring AOP判断是JDK代理还是CGLib代理的源码如下（来自`org.springframework.aop.framework.DefaultAopProxyFactory`）：

```
@Override
public AopProxy createAopProxy(AdvisedSupport config) throws AopConfigException {
    if (config.isOptimize() || config.isProxyTargetClass() || hasNoUserSuppliedProxyInterfaces(config)) {
        Class<?> targetClass = config.getTargetClass();
        if (targetClass == null) {
            throw new AopConfigException("TargetSource cannot determine target class: " +
                                         "Either an interface or a target is required for proxy creation.");
        }
        if (targetClass.isInterface() || Proxy.isProxyClass(targetClass)) {
            return new JdkDynamicAopProxy(config);
        }
        return new ObjenesisCglibAopProxy(config);
    }
    else {
        return new JdkDynamicAopProxy(config);
    }
}
```

由代码发现，如果配置`proxyTargetClass = true`了并且目标类非接口的情况，则会使用CGLib代理，否则使用JDK代理。

### 2.2 Spring AOP配置

Spring AOP的配置有两种方式，XML和注解方式。

#### 2.2.1 XML配置

首先需要引入AOP相关的DTD配置，如下：

```
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="
        http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-4.1.xsd
        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop-3.2.xsd
        ">
```

然后需要引入AOP自动代理配置：

```
<!-- 自动扫描(自动注入) -->
<context:component-scan base-package="org.landy" />
<!-- 指定proxy-target-class为true可强制使用cglib -->
<aop:aspectj-autoproxy proxy-target-class="true"></aop:aspectj-autoproxy>
```

#### 2.2.2 注解配置

Java配置类如下：

```
/**
 * 相当于Spring.xml配置文件的作用
 * @author landyl
 * @create 2:44 PM 09/30/2018
 */
@Configuration
//@EnableLoadTimeWeaving(aspectjWeaving = EnableLoadTimeWeaving.AspectJWeaving.ENABLED)
@EnableAspectJAutoProxy(proxyTargetClass = true)
//@EnableAspectJAutoProxy
@ComponentScan(basePackages = "org.landy")
public class ApplicationConfigure {

    @Bean
    public ApplicationUtil getApplicationUtil() {
        return new ApplicationUtil();
    }

}
```

#### 2.2.3 依赖包

需要使用Spring AOP需要引入以下Jar包：

```
<properties>
    <spring.version>5.0.8.RELEASE</spring.version>
    <aspectj.version>1.8.7</aspectj.version>
</properties>
<!-- aspectjrt.jar包主要是提供运行时的一些注解，静态方法等等东西，通常我们要使用aspectJ的时候都要使用这个包。 -->
<dependency>
    <groupId>org.aspectj</groupId>
    <artifactId>aspectjrt</artifactId>
    <version>${aspectj.version}</version>
</dependency>
<!-- aspectjweaverjar包主要是提供了一个java agent用于在类加载期间织入切面(Load time weaving)。
    并且提供了对切面语法的相关处理等基础方法，供ajc使用或者供第三方开发使用。这个包一般我们不需要显式引用，除非需要使用LTW。
     -->
<dependency>
    <groupId>org.aspectj</groupId>
    <artifactId>aspectjweaver</artifactId>
    <version>${aspectj.version}</version>
</dependency>
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-aop</artifactId>
    <version>${spring.version}</version>
    <scope>compile</scope>
</dependency>
```

#### 2.2.4 配置单元测试

以上两种配置方式，单元测试需要注意一个地方就是引入配置的方式不一样，区别如下：

1. XML方式

   ```
   @ContextConfiguration(locations = { "classpath:spring.xml" }) //加载配置文件
   @RunWith(SpringJUnit4ClassRunner.class)  //使用junit4进行测试
   public class SpringTestBase extends AbstractJUnit4SpringContextTests {
   }
   ```

2. 注解方式

```
@ContextConfiguration(classes = ApplicationConfigure.class)
@RunWith(SpringJUnit4ClassRunner.class)  //使用junit4进行测试
public class SpringTestBase extends AbstractJUnit4SpringContextTests {
}
```

配置好了以后，以后所有的测试类都继承`SpringTestBase`类即可。

## 3. 项目演示

### 3.1 逻辑梳理

本文将以校验某个业务逻辑为例说明Spring AOP代理模式的运用。

按照惯例，还是以客户信息更新校验为例，假设有个校验类如下：

```
/**
 * @author landyl
 * @create 2:22 PM 09/30/2018
 */
@Component
public class CustomerUpdateRule implements UpdateRule {

    //利用自定义注解，进行AOP切面编程，进行其他业务逻辑的校验操作
    @StatusCheck
    public CheckResult check(String updateStatus, String currentStatus) {
        System.out.println("CustomerUpdateRule:在此还有其他业务校验逻辑。。。。"+updateStatus + "____" + currentStatus);
        return new CheckResult();
    }

}
```

此时我们需要定义一个注解`StatusCheck`类，如下：

```
/**
 * @author landyl
 * @create 2:37 PM 09/23/2018
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface StatusCheck {

}
```

此注解仅为一个标记注解。最为主要的就是定义一个更新校验的切面类，定义好切入点。

```
@Component
@Aspect
public class StatusCheckAspect {
    private static final int VALID_UPDATE = Constants.UPDATE_STATUS_VALID_UPDATE;

    private static final Logger LOGGER = LoggerFactory.getLogger(StatusCheckAspect.class);


    //定义切入点:定义一个方法，用于声明切面表达式，一般地，该方法中不再需要添加其他的代码
    @Pointcut("execution(* org.landy.business.rules..*(..)) && @annotation(org.landy.business.rules.annotation.StatusCheck)")
    public void declareJoinPointExpression() {}

    /**
     * 前置通知
     * @param joinPoint
     */
    @Before("declareJoinPointExpression()")
    public void beforeCheck(JoinPoint joinPoint) {
        System.out.println("before statusCheck method start ...");
        System.out.println(joinPoint.getSignature());
        //获得自定义注解的参数
        String methodName = joinPoint.getSignature().getName();
        List<Object> args = Arrays.asList(joinPoint.getArgs());
        System.out.println("The method " + methodName + " begins with " + args);
        System.out.println("before statusCheck method end ...");
    }
}    
```

具体代码请参见[github](https://github.com/landy8530/DesignPatterns)。

### 3.2 逻辑测试

#### 3.2.1 JDK动态代理

JDK动态代理必须实现一个接口，本文实现`UpdateRule`为例，

```
public interface UpdateRule {
    CheckResult check(String updateStatus, String currentStatus);
}
```

并且AOP需要做如下配置：

XML方式：

```
<!-- 指定proxy-target-class为true可强制使用cglib -->
<aop:aspectj-autoproxy proxy-target-class="false"></aop:aspectj-autoproxy>
```

注解方式：

```
@Configuration
@EnableAspectJAutoProxy
@ComponentScan(basePackages = "org.landy")
public class ApplicationConfigure {

}
```

在测试类中，必须使用接口方式注入：

```
/**
 * @author landyl
 * @create 2:32 PM 09/30/2018
 */
public class CustomerUpdateRuleTest extends SpringTestBase {

    @Autowired
    private UpdateRule customerUpdateRule; //JDK代理方式必须以接口方式注入

    @Test
    public void customerCheckTest() {
        System.out.println("proxy class:" + customerUpdateRule.getClass());
        CheckResult checkResult = customerUpdateRule.check("2","currentStatus");
        AssertUtil.assertTrue(checkResult.getCheckResult() == 0,"与预期结果不一致");
    }

}
```

测试结果如下：

```
proxy class:class com.sun.proxy.$Proxy34
2018-10-05  14:18:17.515 [main] INFO  org.landy.business.rules.aop.StatusCheckAspect - Status check around method start ....
before statusCheck method start ...
CheckResult org.landy.business.rules.stategy.UpdateRule.check(String,String)
The method check begins with [2, currentStatus]
before statusCheck method end ...
CustomerUpdateRule:在此还有其他业务校验逻辑。。。。2____currentStatus
2018-10-05  14:18:17.526 [main] INFO  org.landy.business.rules.aop.StatusCheckAspect - execute the target method,the return result_msg:null
2018-10-05  14:18:17.526 [main] INFO  org.landy.business.rules.aop.StatusCheckAspect - Status check around method end ....
```

以上结果说明它生成的代理类为$Proxy34，说明是JDK代理。

#### 3.2.2 CGLib动态代理

使用CGlib可以不用接口（经测试，用了接口好像也没问题）。在测试类中，必须使用实现类方式注入：

```
 @Autowired
 private CustomerUpdateRule customerUpdateRule;
```

并且AOP需要做如下配置：

XML方式：

```
<!-- 指定proxy-target-class为true可强制使用cglib -->
<aop:aspectj-autoproxy proxy-target-class="true"></aop:aspectj-autoproxy>
```

注解方式：

```
@Configuration
@EnableAspectJAutoProxy(proxyTargetClass = true)
@ComponentScan(basePackages = "org.landy")
public class ApplicationConfigure {

}
```

不过发现我并未配置`proxyTargetClass = true`也可以正常运行，有点奇怪。（按理说，默认是为false）

运行结果生成的代理类为：

```
proxy class:class org.landy.business.rules.stategy.CustomerUpdateRule$$EnhancerBySpringCGLIB$$d1075aca
```

说明是CGLib代理。

经过进一步测试，发现如果我实现接口`UpdateRule`，但是注入方式使用类注入方式：

```
@Autowired
private CustomerUpdateRule customerUpdateRule;
```

并且把`proxyTargetClass`设置为false，则运行就报如下错误：

```
严重: Caught exception while allowing TestExecutionListener [org.springframework.test.context.support.DependencyInjectionTestExecutionListener@6a024a67] to prepare test instance [org.landy.business.rules.CustomerUpdateRuleTest@7fcf2fc1]
org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'org.landy.business.rules.CustomerUpdateRuleTest': Unsatisfied dependency expressed through field 'customerUpdateRule'; nested exception is org.springframework.beans.factory.BeanNotOfRequiredTypeException: Bean named 'customerUpdateRule' is expected to be of type 'org.landy.business.rules.stategy.CustomerUpdateRule' but was actually of type 'com.sun.proxy.$Proxy34'
    at org.springframework.beans.factory.annotation.AutowiredAnnotationBeanPostProcessor$AutowiredFieldElement.inject(AutowiredAnnotationBeanPostProcessor.java:586)
```

以上说明了一个问题，使用接口实现的方式则会被默认为JDK代理方式，如果需要使用CGLib代理，需要把`proxyTargetClass`设置为`true`。

#### 3.2.3 综合测试

为了再次验证Spring AOP如何选择JDK代理还是CGLib代理，在此进行一个综合测试。

测试前提：

1. 实现`UpdateRule`接口

2. 测试类使用接口方式注入

   ```
   @Autowired
   private UpdateRule customerUpdateRule; //JDK代理方式必须以接口方式注入
   ```

测试：

配置`proxyTargetClass`为`true`，运行结果如下：

```
customerCheckTest
proxy class:class org.landy.business.rules.stategy.CustomerUpdateRule$$EnhancerBySpringCGLIB$$f5a34953
2018-10-05  15:28:42.820 [main] INFO  org.landy.business.rules.aop.StatusCheckAspect - Status check around method start ....
2018-10-05  15:28:42.823 [main] INFO  org.landy.business.rules.aop.StatusCheckAspect - Status check dynamic AOP,paramValues:2
AOP实际校验逻辑。。。。2----currentStatus
before statusCheck method start ...
target class:org.landy.business.rules.stategy.CustomerUpdateRule@7164ca4c
```

说明为CGLIb代理。

配置`proxyTargetClass`为`false`，运行结果如下：

```
proxy class:class com.sun.proxy.$Proxy34
2018-10-05  15:20:59.894 [main] INFO  org.landy.business.rules.aop.StatusCheckAspect - Status check around method start ....
before statusCheck method start ...
target class:org.landy.business.rules.stategy.CustomerUpdateRule@ae3540e
```

说明为JDK代理。

以上测试说明，指定proxy-target-class为true可强制使用cglib。

### 3.3 常见问题

如果使用JDK动态代理，未使用接口方式注入（或者使用接口实现，并未配置`proxyTargetClass`为true），则会出现以下异常信息：

```
严重: Caught exception while allowing TestExecutionListener [org.springframework.test.context.support.DependencyInjectionTestExecutionListener@6a024a67] to prepare test instance [org.landy.business.rules.CustomerUpdateRuleTest@7fcf2fc1]
org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'org.landy.business.rules.CustomerUpdateRuleTest': Unsatisfied dependency expressed through field 'customerUpdateRule'; nested exception is org.springframework.beans.factory.BeanNotOfRequiredTypeException: Bean named 'customerUpdateRule' is expected to be of type 'org.landy.business.rules.stategy.CustomerUpdateRule' but was actually of type 'com.sun.proxy.$Proxy34'
```

与生成的代理类型不一致，有兴趣的同学可以Debug `DefaultAopProxyFactory`类中的`createAopProxy`方法即可知道两种动态代理的区别。

事例代码地址：<https://github.com/landy8530/DesignPatterns>