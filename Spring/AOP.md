# AOP

AOP是Aspect-Oriented Programming（面向方面编程或面向切面）的简称。提供另一种结构来补充面向对象编程。



## 概念

### Base(基础)

待增强对象或目标对象。面向对象编程(OOP)中存在一些弊端，当需要为多个无继承等关联关系的类中引用同一个行为时，例如日志，权限验证等，只能在每个类中加入引用的代码逻辑，这样对于某些业务场景，例如项目以及开发完成，但是需要对所有访问增加一种判断或验证时，直接修改源码不仅不符合面向对象的设计方法，而且对于改动代码后发生问题的风险及工作量也都是很大的问题。所以Spring提供（面向切面编程）AOP的方式来解决这种问题。而这些待增强的目标对象就是AOP概念中的基础。

### Aspect(切面)

对于基础的增强应用。切面中包括一些内部的其他概念定义。

* `aspect`切面    通常是一个类，里面可以定义切入点和通知
* `Join point` 连接点   在执行程序时的一个点，例如一个方法的执行或一个异常的处理。在Spring AOP中，连接点总是表示方法执行。 
* `advice`通知  对于特定的切入点上执行的增强处理
  * `before` 前置通知     执行切入点方法之前要执行的内容
  * `after returning`后置通知   执行方法后的后置内容（如果有报错就不会执行）
  * `after throwing` 异常通知   发生异常时执行的内容 
  * `after(Finally)` 后置通知   执行方法后的后置内容 (无论报不报错都会执行)
  * `around` 环绕通知   方法执行前后都会执行，环绕通知是最重要的通知类型,像事务,日志等都是环绕通知,注意编程中核心是一个ProceedingJoinPoint 
* `pointcut `切入点    带有通知的连接点
* AOP代理  AOP框架创建的对目标增强后的对象，可以使用JDK动态代理及CGLIB动用代理。

具体参考例子

```java
@Aspect
public class Operator {
    
    @Pointcut("execution(* com.aijava.springcode.service..*.*(..))")
    public void pointCut(){}
    
    @Before("pointCut()")
    public void doBefore(JoinPoint joinPoint){
        System.out.println("AOP Before Advice...");
    }
    
    @After("pointCut()")
    public void doAfter(JoinPoint joinPoint){
        System.out.println("AOP After Advice...");
    }
    
    @AfterReturning(pointcut="pointCut()",returning="returnVal")
    public void afterReturn(JoinPoint joinPoint,Object returnVal){
        System.out.println("AOP AfterReturning Advice:" + returnVal);
    }
    
    @AfterThrowing(pointcut="pointCut()",throwing="error")
    public void afterThrowing(JoinPoint joinPoint,Throwable error){
        System.out.println("AOP AfterThrowing Advice..." + error);
        System.out.println("AfterThrowing...");
    }
    
    @Around("pointCut()")
    public void around(ProceedingJoinPoint pjp){
        System.out.println("AOP Aronud before...");
        try {
            pjp.proceed();
        } catch (Throwable e) {
            e.printStackTrace();
        }
        System.out.println("AOP Aronud after...");
    }
    
}
```

### Configuration(配置)

可以看做是一种编织，通过配置把基础和切面结合起来。

使用过程需要在XML中开启AOP配置。

```xml
<aop:aspectj-autoproxy />
```

而具体配置可以使用XML配置也可以使用注解的方式，其中XML配置内容

```xml
<aop:config>
        <aop:aspect id="loggerAspect" ref="logger">
            <aop:around method="record" pointcut="(execution(* 					   com.aijava.distributed.ssh.service..*.add*(..))
                                              or   execution(* com.aijava.distributed.ssh.service..*.update*(..))
                                              or   execution(* com.aijava.distributed.ssh.service..*.delete*(..)))
                                            and !bean(logService)"/>
        </aop:aspect>
</aop:config>
```



## 源码分析

了解具体使用后，开始研究实现原理。

### 自定义标签(XML)解析

在研究原理之前，首先需要先了解一下自定义标签，因为XML中的AOP相关标签都属于自定义标签类型，所以Spring在处理时都是采用自定义标签处理的方式。

首先先从处理入手，具体在IOC容器初始化环节，有一步xml文件内元素的解析处理，回顾下`DefaultBeanDefinitionDocumentReader`中`parseBeanDefinitions`方法处理。

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

其中对于所有自定义标签的解析都是通过调用`BeanDefinitionParserDelegate`中的`parseCustomElement`方法。

```java
public BeanDefinition parseCustomElement(Element ele) {
		return parseCustomElement(ele, null);
	}
...
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

在这里进行分析，首先`String namespaceUri = getNamespaceURI(ele);`这个获取的就是XML文件中的命名空间类似`http://www.springframework.org/schema/aop `，然后通过`NamespaceHandler handler = this.readerContext.getNamespaceHandlerResolver().resolve(namespaceUri);`获取到用户自定义的命名空间解析器。看到这里我们可以看一下AOP自定义的解析器`AopNamespaceHandler`。

```java
public class AopNamespaceHandler extends NamespaceHandlerSupport {
	@Override
	public void init() {
		// In 2.0 XSD as well as in 2.1 XSD.
		registerBeanDefinitionParser("config", new ConfigBeanDefinitionParser());
		registerBeanDefinitionParser("aspectj-autoproxy", new AspectJAutoProxyBeanDefinitionParser());
		registerBeanDefinitionDecorator("scoped-proxy", new ScopedProxyBeanDefinitionDecorator());
		// Only in 2.0 XSD: moved to context namespace as of 2.1
		registerBeanDefinitionParser("spring-configured", new SpringConfiguredBeanDefinitionParser());
	}
}
```

在上面获取用户自定义的命名空间解析器`AopNamespaceHandler`时，就已经调用了`init`方法。

```java
public NamespaceHandler resolve(String namespaceUri) {
		...
				NamespaceHandler namespaceHandler = (NamespaceHandler) BeanUtils.instantiateClass(handlerClass);
				namespaceHandler.init();
				handlerMappings.put(namespaceUri, namespaceHandler);
				return namespaceHandler;
			}
		...
	}
```

而`registerBeanDefinitionParser`将配置的几种解析器加入到解析器集合中。

```java
private final Map<String, BeanDefinitionParser> parsers = new HashMap<>();
...
protected final void registerBeanDefinitionParser(String elementName, BeanDefinitionParser parser) {
		this.parsers.put(elementName, parser);
	}
```

选定好了解析器后，将进入解析工作，我们继续回到`BeanDefinitionParserDelegate`中的`parseCustomElement`中。

```java
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

这里的`handler`就是`AopNamespaceHandler`，调用`parse`方法，但是`AopNamespaceHandler`中没有这个方法，所以我们从它的父类中寻找。

```java
public BeanDefinition parse(Element element, ParserContext parserContext) {
		BeanDefinitionParser parser = findParserForElement(element, parserContext);
		return (parser != null ? parser.parse(element, parserContext) : null);
	}
```

通过`Element elemrnt`获取对应具体解析器。

```java
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

然后再调用具体解析器中的`parser.parse(element, parserContext)`来执行。根据`AopNamespaceHandler`的配置分为这四种。

- `config`-->`ConfigBeanDefinitionParser`
- `aspectj-autoproxy`-->`AspectJAutoProxyBeanDefinitionParser`
- `scoped-proxy`-->`ScopedProxyBeanDefinitionDecorator`
- `spring-configured`-->`SpringConfiguredBeanDefinitionParser`

根据XML配置节点，第一个节点为`<aop:config>`，所以会进入到`ConfigBeanDefinitionParser`的`parser`方法中。

```java
public BeanDefinition parse(Element element, ParserContext parserContext) {
		CompositeComponentDefinition compositeDef =
				new CompositeComponentDefinition(element.getTagName(), parserContext.extractSource(element));
		parserContext.pushContainingComponent(compositeDef);

		configureAutoProxyCreator(parserContext, element);

		List<Element> childElts = DomUtils.getChildElements(element);
		for (Element elt: childElts) {
			String localName = parserContext.getDelegate().getLocalName(elt);
			if (POINTCUT.equals(localName)) {
				parsePointcut(elt, parserContext);
			}
			else if (ADVISOR.equals(localName)) {
				parseAdvisor(elt, parserContext);
			}
			else if (ASPECT.equals(localName)) {
				parseAspect(elt, parserContext);
			}
		}

		parserContext.popAndRegisterContainingComponent();
		return null;
	}
```

具体重要逻辑看一下`configureAutoProxyCreator`方法,方法内部又调用`AopNamespaceUtils`中的`registerAspectJAutoProxyCreatorIfNecessary`方法。

```java
private void configureAutoProxyCreator(ParserContext parserContext, Element element) {
		AopNamespaceUtils.registerAspectJAutoProxyCreatorIfNecessary(parserContext, element);
	}
...
public class AopNamespaceUtils{    
    ...
public static void registerAspectJAutoProxyCreatorIfNecessary(
			ParserContext parserContext, Element sourceElement) {

		BeanDefinition beanDefinition = AopConfigUtils.registerAspectJAutoProxyCreatorIfNecessary(
				parserContext.getRegistry(), parserContext.extractSource(sourceElement));
		useClassProxyingIfNecessary(parserContext.getRegistry(), sourceElement);
		registerComponentIfNecessary(beanDefinition, parserContext);
	}
    ...
}
```

通过向`registerAspectJAutoProxyCreatorIfNecessary`方法向IOC容器中添加一个Bean   `org.springframework.aop.config.internalAutoProxyCreator`。

继续回到上面，会获取当前节点的所有子节点，然后进行遍历解析。首先是对`<aop:aspect>`的处理，会调用`parseAspect(elt, parserContext);`方法。

```java
private void parseAspect(Element aspectElement, ParserContext parserContext) {
		String aspectId = aspectElement.getAttribute(ID);
		String aspectName = aspectElement.getAttribute(REF);

		try {
			this.parseState.push(new AspectEntry(aspectId, aspectName));
			List<BeanDefinition> beanDefinitions = new ArrayList<>();
			List<BeanReference> beanReferences = new ArrayList<>();

			List<Element> declareParents = DomUtils.getChildElementsByTagName(aspectElement, DECLARE_PARENTS);
			for (int i = METHOD_INDEX; i < declareParents.size(); i++) {
				Element declareParentsElement = declareParents.get(i);
				beanDefinitions.add(parseDeclareParents(declareParentsElement, parserContext));
			}

			// We have to parse "advice" and all the advice kinds in one loop, to get the
			// ordering semantics right.
			NodeList nodeList = aspectElement.getChildNodes();
			boolean adviceFoundAlready = false;
			for (int i = 0; i < nodeList.getLength(); i++) {
				Node node = nodeList.item(i);
				if (isAdviceNode(node, parserContext)) {
					if (!adviceFoundAlready) {
						adviceFoundAlready = true;
						if (!StringUtils.hasText(aspectName)) {
							parserContext.getReaderContext().error(
									"<aspect> tag needs aspect bean reference via 'ref' attribute when declaring advices.",
									aspectElement, this.parseState.snapshot());
							return;
						}
						beanReferences.add(new RuntimeBeanReference(aspectName));
					}
					AbstractBeanDefinition advisorDefinition = parseAdvice(
							aspectName, i, aspectElement, (Element) node, parserContext, beanDefinitions, beanReferences);
					beanDefinitions.add(advisorDefinition);
				}
			}

			AspectComponentDefinition aspectComponentDefinition = createAspectComponentDefinition(
					aspectElement, aspectId, beanDefinitions, beanReferences, parserContext);
			parserContext.pushContainingComponent(aspectComponentDefinition);

			List<Element> pointcuts = DomUtils.getChildElementsByTagName(aspectElement, POINTCUT);
			for (Element pointcutElement : pointcuts) {
				parsePointcut(pointcutElement, parserContext);
			}

			parserContext.popAndRegisterContainingComponent();
		}
		finally {
			this.parseState.pop();
		}
	}
```

其中会遍历子节点，通过调用`isAdviceNode`方法，来判断当前子节点是否是`<aop:before>`、`<aop:after>`、`<aop:after-returning>`、`<aop:after-throwing method="">`、`<aop:around method="">`这些标签。 

如果是则通过`parseAdvice`方法处理。

```java
private AbstractBeanDefinition parseAdvice(
			String aspectName, int order, Element aspectElement, Element adviceElement, ParserContext parserContext,
			List<BeanDefinition> beanDefinitions, List<BeanReference> beanReferences) {

		try {
			this.parseState.push(new AdviceEntry(parserContext.getDelegate().getLocalName(adviceElement)));

			// create the method factory bean
			RootBeanDefinition methodDefinition = new RootBeanDefinition(MethodLocatingFactoryBean.class);
			methodDefinition.getPropertyValues().add("targetBeanName", aspectName);
			methodDefinition.getPropertyValues().add("methodName", adviceElement.getAttribute("method"));
			methodDefinition.setSynthetic(true);

			// create instance factory definition
			RootBeanDefinition aspectFactoryDef =
					new RootBeanDefinition(SimpleBeanFactoryAwareAspectInstanceFactory.class);
			aspectFactoryDef.getPropertyValues().add("aspectBeanName", aspectName);
			aspectFactoryDef.setSynthetic(true);

			// register the pointcut
			AbstractBeanDefinition adviceDef = createAdviceDefinition(
					adviceElement, parserContext, aspectName, order, methodDefinition, aspectFactoryDef,
					beanDefinitions, beanReferences);

			// configure the advisor
			RootBeanDefinition advisorDefinition = new RootBeanDefinition(AspectJPointcutAdvisor.class);
			advisorDefinition.setSource(parserContext.extractSource(adviceElement));
			advisorDefinition.getConstructorArgumentValues().addGenericArgumentValue(adviceDef);
			if (aspectElement.hasAttribute(ORDER_PROPERTY)) {
				advisorDefinition.getPropertyValues().add(
						ORDER_PROPERTY, aspectElement.getAttribute(ORDER_PROPERTY));
			}

			// register the final advisor
			parserContext.getReaderContext().registerWithGeneratedName(advisorDefinition);

			return advisorDefinition;
		}
		finally {
			this.parseState.pop();
		}
	}
```

首先会先创建一个`RootBeanDefinition`对象,其中bean为`MethodLocatingFactoryBean`，存储目标对象的`beanName`和`method`等信息。然后还会再创建一个`RootBeanDefinition`对象,其中bean为`SimpleBeanFactoryAwareAspectInstanceFactory`,存储当前`aspectBeanName`。然后调用`createAdviceDefinition`方法。

```java
private AbstractBeanDefinition createAdviceDefinition(
			Element adviceElement, ParserContext parserContext, String aspectName, int order,
			RootBeanDefinition methodDef, RootBeanDefinition aspectFactoryDef,
			List<BeanDefinition> beanDefinitions, List<BeanReference> beanReferences) {

		RootBeanDefinition adviceDefinition = new RootBeanDefinition(getAdviceClass(adviceElement, parserContext));
		adviceDefinition.setSource(parserContext.extractSource(adviceElement));

		adviceDefinition.getPropertyValues().add(ASPECT_NAME_PROPERTY, aspectName);
		adviceDefinition.getPropertyValues().add(DECLARATION_ORDER_PROPERTY, order);

		if (adviceElement.hasAttribute(RETURNING)) {
			adviceDefinition.getPropertyValues().add(
					RETURNING_PROPERTY, adviceElement.getAttribute(RETURNING));
		}
		if (adviceElement.hasAttribute(THROWING)) {
			adviceDefinition.getPropertyValues().add(
					THROWING_PROPERTY, adviceElement.getAttribute(THROWING));
		}
		if (adviceElement.hasAttribute(ARG_NAMES)) {
			adviceDefinition.getPropertyValues().add(
					ARG_NAMES_PROPERTY, adviceElement.getAttribute(ARG_NAMES));
		}

		ConstructorArgumentValues cav = adviceDefinition.getConstructorArgumentValues();
		cav.addIndexedArgumentValue(METHOD_INDEX, methodDef);

		Object pointcut = parsePointcutProperty(adviceElement, parserContext);
		if (pointcut instanceof BeanDefinition) {
			cav.addIndexedArgumentValue(POINTCUT_INDEX, pointcut);
			beanDefinitions.add((BeanDefinition) pointcut);
		}
		else if (pointcut instanceof String) {
			RuntimeBeanReference pointcutRef = new RuntimeBeanReference((String) pointcut);
			cav.addIndexedArgumentValue(POINTCUT_INDEX, pointcutRef);
			beanReferences.add(pointcutRef);
		}

		cav.addIndexedArgumentValue(ASPECT_INSTANCE_FACTORY_INDEX, aspectFactoryDef);

		return adviceDefinition;
	}
```

其中还会创建一个`RootBeanDefinition`对象，而`Bean`通过`getAdviceClass`方法获取。

```java
private Class<?> getAdviceClass(Element adviceElement, ParserContext parserContext) {
		String elementName = parserContext.getDelegate().getLocalName(adviceElement);
		if (BEFORE.equals(elementName)) {
			return AspectJMethodBeforeAdvice.class;
		}
		else if (AFTER.equals(elementName)) {
			return AspectJAfterAdvice.class;
		}
		else if (AFTER_RETURNING_ELEMENT.equals(elementName)) {
			return AspectJAfterReturningAdvice.class;
		}
		else if (AFTER_THROWING_ELEMENT.equals(elementName)) {
			return AspectJAfterThrowingAdvice.class;
		}
		else if (AROUND.equals(elementName)) {
			return AspectJAroundAdvice.class;
		}
		else {
			throw new IllegalArgumentException("Unknown advice kind [" + elementName + "].");
		}
	}
```

可以看到其中的处理，

* `before` 会返回`AspectJMethodBeforeAdvice`的`bean`
* `after`  会返回`AspectJAfterAdvice`的`bean`
* `after-returning`  会返回`AspectJAfterReturningAdvice`的`bean`
* `after-throwing`  会返回`AspectJAfterThrowingAdvice`的`bean`
* `around`  会返回`AspectJAroundAdvice`的`bean`

继续回到``parseAdvice``中的处理。

```java
RootBeanDefinition advisorDefinition = new RootBeanDefinition(AspectJPointcutAdvisor.class);
			advisorDefinition.setSource(parserContext.extractSource(adviceElement));
			advisorDefinition.getConstructorArgumentValues().addGenericArgumentValue(adviceDef);
			if (aspectElement.hasAttribute(ORDER_PROPERTY)) {
				advisorDefinition.getPropertyValues().add(
						ORDER_PROPERTY, aspectElement.getAttribute(ORDER_PROPERTY));
			}
// register the final advisor
			parserContext.getReaderContext().registerWithGeneratedName(advisorDefinition);
```

会再次创建一个`RootBeanDefinition`对象，其中bean为`AspectJPointcutAdvisor`。然后将上面新创建的``RootBeanDefinition``对象放入其中。

最后一步就是将这个`RootBeanDefinition`对象注册到IOC容器中。其中beanName使用的是**Class全路径+"#"+全局计数器**的方式 。其中的Class全路径为`org.springframework.aop.aspectj.AspectJPointcutAdvisor`，依次类推，每一个BeanName应当为`org.springframework.aop.aspectj.AspectJPointcutAdvisor#0`、`org.springframework.aop.aspectj.AspectJPointcutAdvisor#1`、`org.springframework.aop.aspectj.AspectJPointcutAdvisor#2`这样下去。 

继续回到`ConfigBeanDefinitionParser`的`parseAspect`方法 

```java
...
    	AspectComponentDefinition aspectComponentDefinition = createAspectComponentDefinition(
					aspectElement, aspectId, beanDefinitions, beanReferences, parserContext);
			parserContext.pushContainingComponent(aspectComponentDefinition);

			List<Element> pointcuts = DomUtils.getChildElementsByTagName(aspectElement, POINTCUT);
			for (Element pointcutElement : pointcuts) {
				parsePointcut(pointcutElement, parserContext);
			}

			parserContext.popAndRegisterContainingComponent();
		}
		finally {
			this.parseState.pop();
		}
```

继续分析对`pointcuts`的处理。

```java
private AbstractBeanDefinition parsePointcut(Element pointcutElement, ParserContext parserContext) {
		String id = pointcutElement.getAttribute(ID);
		String expression = pointcutElement.getAttribute(EXPRESSION);

		AbstractBeanDefinition pointcutDefinition = null;

		try {
			this.parseState.push(new PointcutEntry(id));
			pointcutDefinition = createPointcutDefinition(expression);
			pointcutDefinition.setSource(parserContext.extractSource(pointcutElement));

			String pointcutBeanName = id;
			if (StringUtils.hasText(pointcutBeanName)) {
				parserContext.getRegistry().registerBeanDefinition(pointcutBeanName, pointcutDefinition);
			}
			else {
				pointcutBeanName = parserContext.getReaderContext().registerWithGeneratedName(pointcutDefinition);
			}

			parserContext.registerComponent(
					new PointcutComponentDefinition(pointcutBeanName, pointcutDefinition, expression));
		}
		finally {
			this.parseState.pop();
		}

		return pointcutDefinition;
	}

```

其中包括了`pointcut`的解析，及向IOC容器的存入。而其中的Bean为`org.springframework.aop.aspectj.AspectJExpressionPointcut `。







