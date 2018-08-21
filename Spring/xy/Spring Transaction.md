# Spring 事务

## 事务特性 （ACID）

* 原子性（atomicity） 

  事务必须是一个原子的操作序列单元。只允许出现两种状态，全部执行成功，全部不执行。

* 一致性（consistency）

  事务的执行不能破坏数据库的完整性和一致性，一个是我必须是使数据库从一个一致性状态编导另一个一致性状态。

* 隔离性（isolation）

  一个事务执行不能被其他事务干扰，事务内部的操作和使用的数据对并发的其他事务是隔离的，各个事务直接互不干扰。

  * 读取未提交   级别最低，允许脏读，当一个事务处理未提交时，其他事务也可以读取该数据。
  * 读取已提交   事务只能读取到已提交的时间，不能读取未提交的。
  * 可重复读    保证在事务处理过程中，多次读取同一个数据时，其值和事务开始时刻是一致的。 
  * 串行化     最严格的事务隔离级别，要求所有事务被串行执行。同一时间只能执行一个事务。 

  ![image](https://github.com/dqsbl2016/study/blob/master/Spring/xy/img/1534729740471.jpg)

	​	

* 持久性（durability） 事务一旦提交，对数据库的数据变更时永久性的。

## 基本原理

Spring事务的本章就是 数据库对事务的支持。具体操作步骤：

* 获取连接 Connection con= Drivermanager.getConnection();
* 开启事务 con.setAutoCommit(true/false);
* 执行用户操作
* 提交事务/回滚事务 con.commit()/con.rollback();
* con.close();

Spring的事务就是自动完成 开启事务 与  提交或回滚事务 的操作。

## 事务的传播属性（级别）

设置一个事务后，可以为这事务设置传播的属性，这些在`TransactionDefinition`接口中定义，其中包括

* `PROPAGATION_REQUIRED` = 0

  默认设置，如果当前没有事务，则创建一个事务。

* `PROPAGATION_REQUIRES_NEW` = 3

  如果当前存在事务，把当前事务挂起，再新建事务完成此调用。新建的事务和被挂起的事务没有任何关系，是两个独立的事务，外层事务失败回滚，不会影响内层事务的执行结果，内层事务失败回滚，外层可以捕获，可以自己决定是否回滚。

* `PROPAGATION_SUPPORTS` = 1

  支持当前事务，如果当前没有事务，就以非事务方式执行

* `PROPAGATION_MANDATORY` =2

  支持当前事务，如果当前没有事务，就抛出异常

* `PROPAGATION_NOT_SUPPORTED` = 4

  以非事务方式执行操作，如果当前存在事务，就把当前事务挂起。

* `PROPAGATION_NEVER` = 5

  以非事务方式执行，如果当前存在事务，则抛出异常。

* `PROPAGATION_NESTED` = 6

  如果一个活动的事务存在，则运行在一个嵌套的事务中。如果没有活动事务，则按 REQUIRED 属性执
  行。它使用了一个单独的事务，这个事务拥有多个可以回滚的保存点。内部事务的回滚不会对外部事
  务 造 成 影 响 。 它 只 对DataSourceTransactionManager 事务管理器起效。

## 事务的嵌套

假设定义了事务Service A中的Method A调用  另一个定义了事务Service B中的Method B。

* `PROPAGATION_REQUIRED` 

  执行Method A的时候Spring已经起了事务，这个时候调用Method B就不会再起新的事务，任何地方出现异常，事务会被回滚。

* `PROPAGATION_REQUIRES_NEW` 

  假如Method A事务级别为`PROPAGATION_REQUIRED` ，Method B的级别为`PROPAGATION_REQUIRES_NEW` 。

  当执行到Method B的时候，Method A所在的事务就会挂起，Method B会新启一个事务，等待B完成后，A才会继续执行。如果B中已完成，则代表已经提交了，这个时候A出现失败，那么B中修改是不会回滚的。

* `PROPAGATION_SUPPORTS` 

  假 设 ServiceB.MethodB() 的 事 务 级 别 为 PROPAGATION_SUPPORTS ， 那 么 当 执 行 到
  ServiceB.MethodB()时，如果发现 ServiceA.MethodA()已经开启了一个事务，则加入当前的事务，
  如果发现 ServiceA.MethodA()没有开启事务，则自己也不开启事务。这种时候，内部方法的事务性完
  全依赖于最外层的事务。

* `PROPAGATION_NESTED` 

  现在的情况就变得比较复杂了, ServiceB.MethodB() 的事务属性被配置为 PROPAGATION_NESTED,
  此时两者之间又将如何协作呢?   ServiceB#MethodB 如果 rollback, 那么内部事务 (即
  ServiceB#MethodB) 将回滚到它执行前的 SavePoint 而外部事务(即 ServiceA#MethodA) 可以有以下两种处理方式:捕获异常，执行异常分支逻辑。这种方式也是嵌套事务最有价值的地方, 它起到了分支执行的效果, 如果 ServiceB.MethodB 失败,那么执行 ServiceC.MethodC(), 而 ServiceB.MethodB 已经回滚到它执行之前的 SavePoint, 所以不会产生脏数据(相当于此方法从未执行过), 这种特性可以用在某些特殊的业务中, 而

  PROPAGATION_REQUIRED 和 PROPAGATION_REQUIRES_NEW 都没有办法做到这一点。b、 外部事务回滚/提交 代码不做任何修改, 那么如果内部事务(ServiceB#MethodB) rollback, 那么首先 ServiceB.MethodB 回滚到它执行之前的 SavePoint(在任何情况下都会如此), 外部事务(即 ServiceA#MethodA) 将根据具体的配置决定自己是 commit 还是 rollback。

## Spring中应用

### 编程式事务管理

几乎不用

### 声明式事务管理

#### 基于注解（常用）

xml

```xml
<tx:annotation-driven transaction-manager="transactionManager"/>
<bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
  <property name ="数据源ID"  ref="数据源ID"/>
</bean>
```

Annotation

```java
//直接在需要执行的方法上增加@Transactional 注解
@Transactional
public void save(){
    
}
```

#### 基于TransactionProxyFactoryBean的方式（很少使用）



#### 基于AspectJ的方式（常使用）

xml

```xml
<!-- ***************事务配置************** -->
    <bean id="transactionManager"
        class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource" />
    </bean>
    
    <!-- 定义AOP配置 -->
    <aop:config>
        <!-- 将advice和pointcut结合 -->
        <aop:advisor pointcut="execution(* com.seentao.jxgl.service.*.insert*(..))"
            advice-ref="txAdvice" />
    </aop:config>
    <!-- 定义哪些方法需要执行事务 -->
    <tx:advice id="txAdvice" transaction-manager="transactionManager">
        <tx:attributes>
            <tx:method name="insert*" read-only="true" propagation="SUPPORTS" />
            <tx:method name="*" propagation="REQUIRED" rollback-for="Exception" /> 
        </tx:attributes>
    </tx:advice>
```



## 源码解析

### 声明式事务管理

#### 正常解析

Spring事务采用自定义标签，定义了类`TxNamespaceHandler`

```java
public void init() {
		registerBeanDefinitionParser("advice", new TxAdviceBeanDefinitionParser());
		registerBeanDefinitionParser("annotation-driven", new AnnotationDrivenBeanDefinitionParser());
		registerBeanDefinitionParser("jta-transaction-manager", new JtaTransactionManagerBeanDefinitionParser());
	}

```

在XML配置中通过`<tx:annotation-driven/>` 开启事务开关。而具体的标签解析器使用了`AnnotationDrivenBeanDefinitionParser`来进行解析。

```java
public BeanDefinition parse(Element element, ParserContext parserContext) {
		registerTransactionalEventListenerFactory(parserContext);
		String mode = element.getAttribute("mode");
		if ("aspectj".equals(mode)) {
			// mode="aspectj"
			registerTransactionAspect(element, parserContext);
		}
		else {
			// mode="proxy"
			AopAutoProxyConfigurer.configureAutoProxyCreator(element, parserContext);
		}
		return null;
	}
```

首先了解`registerTransactionalEventListenerFactory`的操作。

```java
private void registerTransactionalEventListenerFactory(ParserContext parserContext) {
		RootBeanDefinition def = new RootBeanDefinition();
		def.setBeanClass(TransactionalEventListenerFactory.class);
		parserContext.registerBeanComponent(new BeanComponentDefinition(def,
				TransactionManagementConfigUtils.TRANSACTIONAL_EVENT_LISTENER_FACTORY_BEAN_NAME));
	}
```

这里主要是创建一个`RootBeanDefinition`，生成一个`TransactionalEventListenerFactory`的bean，进行IOC初始化，其中beanName是`org.springframework.transaction.config.internalTransactionalEventListenerFactory`。

然后获取标签元素`mode`的值。这里`model`有两种方式`proxy`和`aspectj`。其中默认为proxy。

如果当前是`aspectj`方式，会调用`registerTransactionAspect`进行处理。

```java
private void registerTransactionAspect(Element element, ParserContext parserContext) {
		String txAspectBeanName = TransactionManagementConfigUtils.TRANSACTION_ASPECT_BEAN_NAME;
		String txAspectClassName = TransactionManagementConfigUtils.TRANSACTION_ASPECT_CLASS_NAME;
		if (!parserContext.getRegistry().containsBeanDefinition(txAspectBeanName)) {
			RootBeanDefinition def = new RootBeanDefinition();
			def.setBeanClassName(txAspectClassName);
			def.setFactoryMethodName("aspectOf");
			registerTransactionManager(element, def);
			parserContext.registerBeanComponent(new BeanComponentDefinition(def, txAspectBeanName));
		}
	}
```

这里面主要就是设置一个beanName为`org.springframework.transaction.config.internalTransactionAspect`，Classname为

`org.springframework.transaction.aspectj.AnnotationTransactionAspect`的bean进行IOC初始化。

并且还会设置属性名称为`transactionManagerBeanName`，值为XML配置的`transaction-manager`的具体值。

这里应该做的是准备工作，设置一个为解析事务的bean。

如果model设置为proxy属性，将会执行`AopAutoProxyConfigurer.configureAutoProxyCreator`

```java
public static void configureAutoProxyCreator(Element element, ParserContext parserContext) {
			AopNamespaceUtils.registerAutoProxyCreatorIfNecessary(parserContext, element);

			String txAdvisorBeanName = TransactionManagementConfigUtils.TRANSACTION_ADVISOR_BEAN_NAME;
			if (!parserContext.getRegistry().containsBeanDefinition(txAdvisorBeanName)) {
				Object eleSource = parserContext.extractSource(element);

				// Create the TransactionAttributeSource definition.
				RootBeanDefinition sourceDef = new RootBeanDefinition(
						"org.springframework.transaction.annotation.AnnotationTransactionAttributeSource");
				sourceDef.setSource(eleSource);
				sourceDef.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
				String sourceName = parserContext.getReaderContext().registerWithGeneratedName(sourceDef);

				// Create the TransactionInterceptor definition.
				RootBeanDefinition interceptorDef = new RootBeanDefinition(TransactionInterceptor.class);
				interceptorDef.setSource(eleSource);
				interceptorDef.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
				registerTransactionManager(element, interceptorDef);
				interceptorDef.getPropertyValues().add("transactionAttributeSource", new RuntimeBeanReference(sourceName));
				String interceptorName = parserContext.getReaderContext().registerWithGeneratedName(interceptorDef);

				// Create the TransactionAttributeSourceAdvisor definition.
				RootBeanDefinition advisorDef = new RootBeanDefinition(BeanFactoryTransactionAttributeSourceAdvisor.class);
				advisorDef.setSource(eleSource);
				advisorDef.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
				advisorDef.getPropertyValues().add("transactionAttributeSource", new RuntimeBeanReference(sourceName));
				advisorDef.getPropertyValues().add("adviceBeanName", interceptorName);
				if (element.hasAttribute("order")) {
					advisorDef.getPropertyValues().add("order", element.getAttribute("order"));
				}
				parserContext.getRegistry().registerBeanDefinition(txAdvisorBeanName, advisorDef);

				CompositeComponentDefinition compositeDef = new CompositeComponentDefinition(element.getTagName(), eleSource);
				compositeDef.addNestedComponent(new BeanComponentDefinition(sourceDef, sourceName));
				compositeDef.addNestedComponent(new BeanComponentDefinition(interceptorDef, interceptorName));
				compositeDef.addNestedComponent(new BeanComponentDefinition(advisorDef, txAdvisorBeanName));
				parserContext.registerComponent(compositeDef);
			}
		}
```

这里包含不少处理，我们来分析：

首先会执行`registerAutoProxyCreatorIfNecessary`。

```java
public static void registerAutoProxyCreatorIfNecessary(
			ParserContext parserContext, Element sourceElement) {

		BeanDefinition beanDefinition = AopConfigUtils.registerAutoProxyCreatorIfNecessary(
				parserContext.getRegistry(), parserContext.extractSource(sourceElement));
		useClassProxyingIfNecessary(parserContext.getRegistry(), sourceElement);
		registerComponentIfNecessary(beanDefinition, parserContext);
	}
```

继续执行`registerAutoProxyCreatorIfNecessary`

```
private static BeanDefinition registerOrEscalateApcAsRequired(Class<?> cls, BeanDefinitionRegistry registry,
      @Nullable Object source) {

   Assert.notNull(registry, "BeanDefinitionRegistry must not be null");

   if (registry.containsBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME)) {
      BeanDefinition apcDefinition = registry.getBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME);
      if (!cls.getName().equals(apcDefinition.getBeanClassName())) {
         int currentPriority = findPriorityForClass(apcDefinition.getBeanClassName());
         int requiredPriority = findPriorityForClass(cls);
         if (currentPriority < requiredPriority) {
            apcDefinition.setBeanClassName(cls.getName());
         }
      }
      return null;
   }

   RootBeanDefinition beanDefinition = new RootBeanDefinition(cls);
   beanDefinition.setSource(source);
   beanDefinition.getPropertyValues().add("order", Ordered.HIGHEST_PRECEDENCE);
   beanDefinition.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
   registry.registerBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME, beanDefinition);
   return beanDefinition;
}
```

首先会判断`org.springframework.aop.config.internalAutoProxyCreator` 容器中是否已存在这个bean。

如果存在，会判断优先级选择是否替换具体的class。

如果不存在，会创建一个beanName为`org.springframework.aop.config.internalAutoProxyCreator`   className为`InfrastructureAdvisorAutoProxyCreator.class`的bean，进行IOC初始化。

继续回到上面方法，会执行`useClassProxyingIfNecessary`方法，这个方法很熟悉了，在AOP的时候也执行过。

```java
private static void useClassProxyingIfNecessary(BeanDefinitionRegistry registry, @Nullable Element sourceElement) {
		if (sourceElement != null) {
			boolean proxyTargetClass = Boolean.parseBoolean(sourceElement.getAttribute(PROXY_TARGET_CLASS_ATTRIBUTE));
			if (proxyTargetClass) {
				AopConfigUtils.forceAutoProxyCreatorToUseClassProxying(registry);
			}
			boolean exposeProxy = Boolean.parseBoolean(sourceElement.getAttribute(EXPOSE_PROXY_ATTRIBUTE));
			if (exposeProxy) {
				AopConfigUtils.forceAutoProxyCreatorToExposeProxy(registry);
			}
		}
	}
```

这里是判断xml是否设置了`proxy-target-class`和`expose-proxy`属性。进行应用。`proxy-target-class`表示使用哪种代理方式，默认为CGLIB。另外自动代理创建器设置`exposeProxy`为`true`。这个设置是有时候对象内部的自我调用将无法实施切面中的增强，所以设置为`true`后，内部调用通过 （class）.调用方法方式将依然可以增强，例如`AopService`中存在`a`,`b`两个方法，在`a`方法中调用`b`方法可以通过`((AopService) AopContext.currentProxy()).b()`方式来使用;

再回到上面通过`registerComponentIfNecessary(beanDefinition, parserContext);`做一些内部封装注册。

继续回到`configureAutoProxyCreator`方法的处理。

判断当前bean容器中是否有`org.springframework.transaction.config.internalTransactionAdvisor";`这个bean如果不存在则注册3个bean。

* `org.springframework.transaction.annotation.AnnotationTransactionAttributeSource`

  会根据Spring内部规则定义BeanName

* `TransactionInterceptor.class`

  在注册这个过程中，还会再初始化一个`TransactionalEventListenerFactory`的监听bean。

  会根据Spring内部规则定义BeanName

* `BeanFactoryTransactionAttributeSourceAdvisor.class`

  这个会注册到上面判断的``org.springframework.transaction.config.internalTransactionAdvisor`这个beanName中。

然后将这些设置镶嵌关系，进行注册。

![image](https://github.com/dqsbl2016/study/blob/master/Spring/xy/img/SpringTransaction1.jpg)

​	

#### 基于AspectJ得额外解析

接下来看`advice`标签的处理解析，因为配置的`TxAdviceBeanDefinitionParser`没有实现`parse`方法，所以会从父类向上寻找，最后找到`AbstractBeanDefinitionParser`中的实现。

```javaj
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

首先执行的就是`parseInternal`方法，这个通过模板设计模式会调用子类中的实现，所以会进入`org.springframework.beans.factory.xml.AbstractSingleBeanDefinitionParser'中的'parseInternal`方法

```java
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

先创建一个new BeanDefinitionBuilder(new GenericBeanDefinition());

然后设置beanClass为`TransactionInterceptor.class`。并加入到beandefinition中，

然后执行doParse方法，这个在子类中实现所以会进入`org.springframework.transaction.config.TxAdviceBeanDefinitionParser`中的`doParse`方法。

```java
protected void doParse(Element element, ParserContext parserContext, BeanDefinitionBuilder builder) {
		builder.addPropertyReference("transactionManager", TxNamespaceHandler.getTransactionManagerName(element));

		List<Element> txAttributes = DomUtils.getChildElementsByTagName(element, ATTRIBUTES_ELEMENT);
		if (txAttributes.size() > 1) {
			parserContext.getReaderContext().error(
					"Element <attributes> is allowed at most once inside element <advice>", element);
		}
		else if (txAttributes.size() == 1) {
			// Using attributes source.
			Element attributeSourceElement = txAttributes.get(0);
			RootBeanDefinition attributeSourceDefinition = parseAttributeSource(attributeSourceElement, parserContext);
			builder.addPropertyValue("transactionAttributeSource", attributeSourceDefinition);
		}
		else {
			// Assume annotations source.
			builder.addPropertyValue("transactionAttributeSource",
					new RootBeanDefinition("org.springframework.transaction.annotation.AnnotationTransactionAttributeSource"));
		}
	}
```

通过`getChildElementsByTagName`获取子元素中的`<tx:attributes>`标签中的值。

```java
public static List<Element> getChildElementsByTagName(Element ele, String... childEleNames) {
		Assert.notNull(ele, "Element must not be null");
		Assert.notNull(childEleNames, "Element names collection must not be null");
		List<String> childEleNameList = Arrays.asList(childEleNames);
		NodeList nl = ele.getChildNodes();
		List<Element> childEles = new ArrayList<>();
		for (int i = 0; i < nl.getLength(); i++) {
			Node node = nl.item(i);
			if (node instanceof Element && nodeNameMatch(node, childEleNameList)) {
				childEles.add((Element) node);
			}
		}
		return childEles;
	}
```

然后通过`parseAttributeSource`方法进行属性设置的解析

```java
private RootBeanDefinition parseAttributeSource(Element attrEle, ParserContext parserContext) {
		List<Element> methods = DomUtils.getChildElementsByTagName(attrEle, METHOD_ELEMENT);
		ManagedMap<TypedStringValue, RuleBasedTransactionAttribute> transactionAttributeMap =
				new ManagedMap<>(methods.size());
		transactionAttributeMap.setSource(parserContext.extractSource(attrEle));

		for (Element methodEle : methods) {
			String name = methodEle.getAttribute(METHOD_NAME_ATTRIBUTE);
			TypedStringValue nameHolder = new TypedStringValue(name);
			nameHolder.setSource(parserContext.extractSource(methodEle));

			RuleBasedTransactionAttribute attribute = new RuleBasedTransactionAttribute();
			String propagation = methodEle.getAttribute(PROPAGATION_ATTRIBUTE);
			String isolation = methodEle.getAttribute(ISOLATION_ATTRIBUTE);
			String timeout = methodEle.getAttribute(TIMEOUT_ATTRIBUTE);
			String readOnly = methodEle.getAttribute(READ_ONLY_ATTRIBUTE);
			if (StringUtils.hasText(propagation)) {
				attribute.setPropagationBehaviorName(RuleBasedTransactionAttribute.PREFIX_PROPAGATION + propagation);
			}
			if (StringUtils.hasText(isolation)) {
				attribute.setIsolationLevelName(RuleBasedTransactionAttribute.PREFIX_ISOLATION + isolation);
			}
			if (StringUtils.hasText(timeout)) {
				try {
					attribute.setTimeout(Integer.parseInt(timeout));
				}
				catch (NumberFormatException ex) {
					parserContext.getReaderContext().error("Timeout must be an integer value: [" + timeout + "]", methodEle);
				}
			}
			if (StringUtils.hasText(readOnly)) {
				attribute.setReadOnly(Boolean.valueOf(methodEle.getAttribute(READ_ONLY_ATTRIBUTE)));
			}

			List<RollbackRuleAttribute> rollbackRules = new LinkedList<>();
			if (methodEle.hasAttribute(ROLLBACK_FOR_ATTRIBUTE)) {
				String rollbackForValue = methodEle.getAttribute(ROLLBACK_FOR_ATTRIBUTE);
				addRollbackRuleAttributesTo(rollbackRules,rollbackForValue);
			}
			if (methodEle.hasAttribute(NO_ROLLBACK_FOR_ATTRIBUTE)) {
				String noRollbackForValue = methodEle.getAttribute(NO_ROLLBACK_FOR_ATTRIBUTE);
				addNoRollbackRuleAttributesTo(rollbackRules,noRollbackForValue);
			}
			attribute.setRollbackRules(rollbackRules);

			transactionAttributeMap.put(nameHolder, attribute);
		}

		RootBeanDefinition attributeSourceDefinition = new RootBeanDefinition(NameMatchTransactionAttributeSource.class);
		attributeSourceDefinition.setSource(parserContext.extractSource(attrEle));
		attributeSourceDefinition.getPropertyValues().add("nameMap", transactionAttributeMap);
		return attributeSourceDefinition;
	}
```

首先获取所有的` <tx:method >` 标签元素，然后遍历结果再读其他的属性进行设置。

然后创建一个beandefinition，其中classname为`NameMatchTransactionAttributeSource.class`.

然后将这个beandefinition设置到上面生成的builder中的属性中。`builder.addPropertyValue("transactionAttributeSource", attributeSourceDefinition);` 然后将builder中的

`beandefinition`返回。再回到`parse`方法中会调用`resolveId`方法解析

```java
protected String resolveId(Element element, AbstractBeanDefinition definition, ParserContext parserContext)
			throws BeanDefinitionStoreException {

		if (shouldGenerateId()) {
			return parserContext.getReaderContext().generateBeanName(definition);
		}
		else {
			String id = element.getAttribute(ID_ATTRIBUTE);
			if (!StringUtils.hasText(id) && shouldGenerateIdAsFallback()) {
				id = parserContext.getReaderContext().generateBeanName(definition);
			}
			return id;
		}
	}

```

获取元素中的id内容`<tx:advice id="defaultTxAdvice"> `。如果其中未设置ID，会自动生成一个。

然后判断是否设置别名，做对应处理。

然后会根据beanName为id的值，className为前面返回的definition，放入到BeanDefinitionHolder中，然后进行IOC初始化工作。之后还会再内嵌工作。最后返回这个`definition`。



#### 依赖注入

在上面如果使用代理的方式，会在IOC容器中增加一个`InfrastructureAdvisorAutoProxyCreator.class`的bean。

而这个class向上一直找发现它是最后是一个实现`BeanPostProcessor`接口的实现类。

所以当bean初始化的时候会执行实例化前后，初始化前后的方法。

**有个疑问，什么地方调用的`InfrastructureAdvisorAutoProxyCreator`的依赖注入也就是getBean，其中有一个说法是@Transactional注解的bean会继承这个InfrastructureAdvisorAutoProxyCreator得实现。**

先继续看

主要会执行到初始化的后置方法

```java
public Object postProcessAfterInitialization(@Nullable Object bean, String beanName) throws BeansException {
		if (bean != null) {
			Object cacheKey = getCacheKey(bean.getClass(), beanName);
			if (!this.earlyProxyReferences.contains(cacheKey)) {
				return wrapIfNecessary(bean, beanName, cacheKey);
			}
		}
		return bean;
	}
```

其中会执行`wrapIfNecessary`方法

```java
protected Object wrapIfNecessary(Object bean, String beanName, Object cacheKey) {
		if (StringUtils.hasLength(beanName) && this.targetSourcedBeans.contains(beanName)) {
			return bean;
		}
		if (Boolean.FALSE.equals(this.advisedBeans.get(cacheKey))) {
			return bean;
		}
		if (isInfrastructureClass(bean.getClass()) || shouldSkip(bean.getClass(), beanName)) {
			this.advisedBeans.put(cacheKey, Boolean.FALSE);
			return bean;
		}

		// Create proxy if we have advice.
		Object[] specificInterceptors = getAdvicesAndAdvisorsForBean(bean.getClass(), beanName, null);
		if (specificInterceptors != DO_NOT_PROXY) {
			this.advisedBeans.put(cacheKey, Boolean.TRUE);
			Object proxy = createProxy(
					bean.getClass(), beanName, specificInterceptors, new SingletonTargetSource(bean));
			this.proxyTypes.put(cacheKey, proxy.getClass());
			return proxy;
		}

		this.advisedBeans.put(cacheKey, Boolean.FALSE);
		return bean;
	}
```

首先会做一些验证，然后执行`getAdvicesAndAdvisorsForBean`方法

```java
	protected Object[] getAdvicesAndAdvisorsForBean(
			Class<?> beanClass, String beanName, @Nullable TargetSource targetSource) {

		List<Advisor> advisors = findEligibleAdvisors(beanClass, beanName);
		if (advisors.isEmpty()) {
			return DO_NOT_PROXY;
		}
		return advisors.toArray();
	}
...
protected List<Advisor> findEligibleAdvisors(Class<?> beanClass, String beanName) {
		List<Advisor> candidateAdvisors = findCandidateAdvisors();
		List<Advisor> eligibleAdvisors = findAdvisorsThatCanApply(candidateAdvisors, beanClass, beanName);
		extendAdvisors(eligibleAdvisors);
		if (!eligibleAdvisors.isEmpty()) {
			eligibleAdvisors = sortAdvisors(eligibleAdvisors);
		}
		return eligibleAdvisors;
	}
```

这个逻辑在AOP中见过，就是寻找增强器，然后再获取最合适的增强器。

```java
public List<Advisor> findAdvisorBeans() {
		// Determine list of advisor bean names, if not cached already.
		String[] advisorNames = null;
		synchronized (this) {
			advisorNames = this.cachedAdvisorBeanNames;
			if (advisorNames == null) {
				// Do not initialize FactoryBeans here: We need to leave all regular beans
				// uninitialized to let the auto-proxy creator apply to them!
				advisorNames = BeanFactoryUtils.beanNamesForTypeIncludingAncestors(
						this.beanFactory, Advisor.class, true, false);
				this.cachedAdvisorBeanNames = advisorNames;
			}
		}
		if (advisorNames.length == 0) {
			return new LinkedList<>();
		}

		List<Advisor> advisors = new LinkedList<>();
		for (String name : advisorNames) {
			if (isEligibleBean(name)) {
				if (this.beanFactory.isCurrentlyInCreation(name)) {
					if (logger.isDebugEnabled()) {
						logger.debug("Skipping currently created advisor '" + name + "'");
					}
				}
				else {
					try {
						advisors.add(this.beanFactory.getBean(name, Advisor.class));
					}
					catch (BeanCreationException ex) {
						Throwable rootCause = ex.getMostSpecificCause();
						if (rootCause instanceof BeanCurrentlyInCreationException) {
							BeanCreationException bce = (BeanCreationException) rootCause;
							String bceBeanName = bce.getBeanName();
							if (bceBeanName != null && this.beanFactory.isCurrentlyInCreation(bceBeanName)) {
								if (logger.isDebugEnabled()) {
									logger.debug("Skipping advisor '" + name +
											"' with dependency on currently created bean: " + ex.getMessage());
								}
								// Ignore: indicates a reference back to the bean we're trying to advise.
								// We want to find advisors other than the currently created bean itself.
								continue;
							}
						}
						throw ex;
					}
				}
			}
		}
		return advisors;
	}
```

这里做的就是获取到所有的`Advisor.class`类型的bean。而之前解析的过程中，向IOC容器中放入了`BeanFactoryTransactionAttributeSourceAdvisor.class`这个bean。而在这个里面又内嵌了2个bean。那么此刻这个bean就开始使用了

回到上面`findAdvisorsThatCanApply`来获取合适的增强器。

```java
protected List<Advisor> findAdvisorsThatCanApply(
			List<Advisor> candidateAdvisors, Class<?> beanClass, String beanName) {

		ProxyCreationContext.setCurrentProxiedBeanName(beanName);
		try {
			return AopUtils.findAdvisorsThatCanApply(candidateAdvisors, beanClass);
		}
		finally {
			ProxyCreationContext.setCurrentProxiedBeanName(null);
		}
	}
...
public static List<Advisor> findAdvisorsThatCanApply(List<Advisor> candidateAdvisors, Class<?> clazz) {
		if (candidateAdvisors.isEmpty()) {
			return candidateAdvisors;
		}
		List<Advisor> eligibleAdvisors = new LinkedList<>();
		for (Advisor candidate : candidateAdvisors) {
			if (candidate instanceof IntroductionAdvisor && canApply(candidate, clazz)) {
				eligibleAdvisors.add(candidate);
			}
		}
		boolean hasIntroductions = !eligibleAdvisors.isEmpty();
		for (Advisor candidate : candidateAdvisors) {
			if (candidate instanceof IntroductionAdvisor) {
				// already processed
				continue;
			}
			if (canApply(candidate, clazz, hasIntroductions)) {
				eligibleAdvisors.add(candidate);
			}
		}
		return eligibleAdvisors;
	}
```

这里的判断还是判断是否用这个增强器，例如当前增强器是`BeanFactoryTransactionAttributeSourceAdvisor.class`,而这个class的继承关系间接实现了`PointcutAdvisor`，所以会进入第二个判断执行canApply(candidate, clazz, hasIntroductions)

```java
public static boolean canApply(Advisor advisor, Class<?> targetClass) {
		return canApply(advisor, targetClass, false);
	}
。。。
public static boolean canApply(Advisor advisor, Class<?> targetClass, boolean hasIntroductions) {
		if (advisor instanceof IntroductionAdvisor) {
			return ((IntroductionAdvisor) advisor).getClassFilter().matches(targetClass);
		}
		else if (advisor instanceof PointcutAdvisor) {
			PointcutAdvisor pca = (PointcutAdvisor) advisor;
			return canApply(pca.getPointcut(), targetClass, hasIntroductions);
		}
		else {
			// It doesn't have a pointcut so we assume it applies.
			return true;
		}
	}

```

这里也会执行 canApply(pca.getPointcut(), targetClass, hasIntroductions)，而第一个参数获取的pca.getPointcut()是什么呢？进入到`org.springframework.transaction.interceptor.BeanFactoryTransactionAttributeSourceAdvisor`中的`getPointcut`方法，发现返回的是`TransactionAttributeSourcePointcut`的实例。

```java
public Pointcut getPointcut() {
		return this.pointcut;
	}
。。。
private final TransactionAttributeSourcePointcut pointcut = new TransactionAttributeSourcePointcut() {
		@Override
		@Nullable
		protected TransactionAttributeSource getTransactionAttributeSource() {
			return transactionAttributeSource;
		}
	};
```

继续回到上面分支点向下走

```java
public static boolean canApply(Pointcut pc, Class<?> targetClass, boolean hasIntroductions) {
		Assert.notNull(pc, "Pointcut must not be null");
		if (!pc.getClassFilter().matches(targetClass)) {
			return false;
		}

		MethodMatcher methodMatcher = pc.getMethodMatcher();
		if (methodMatcher == MethodMatcher.TRUE) {
			// No need to iterate the methods if we're matching any method anyway...
			return true;
		}

		IntroductionAwareMethodMatcher introductionAwareMethodMatcher = null;
		if (methodMatcher instanceof IntroductionAwareMethodMatcher) {
			introductionAwareMethodMatcher = (IntroductionAwareMethodMatcher) methodMatcher;
		}

		Set<Class<?>> classes = new LinkedHashSet<>();
		if (!Proxy.isProxyClass(targetClass)) {
			classes.add(ClassUtils.getUserClass(targetClass));
		}
		classes.addAll(ClassUtils.getAllInterfacesForClassAsSet(targetClass));

		for (Class<?> clazz : classes) {
			Method[] methods = ReflectionUtils.getAllDeclaredMethods(clazz);
			for (Method method : methods) {
				if (introductionAwareMethodMatcher != null ?
						introductionAwareMethodMatcher.matches(method, targetClass, hasIntroductions) :
						methodMatcher.matches(method, targetClass)) {
					return true;
				}
			}
		}

		return false;
	}
```

首先`pc.getMethodMatcher()`会返回一个`StaticMethodMatcherPointcut`对象。

这里可以看下`StaticMethodMatcherPointcut`的继承关系

 StaticMethodMatcher   Pointcut   MethodMatcher

所有后面判断都不会执行，然后判断如果不是代理类，记录到class集合中。再获取当前class的所有接口，再一起遍历，获取所有方法，再遍历方法，然后做匹配操作

```java
if (introductionAwareMethodMatcher != null ?
						introductionAwareMethodMatcher.matches(method, targetClass, hasIntroductions) :
						methodMatcher.matches(method, targetClass)) {
```

这里`introductionAwareMethodMatcher`为null，所以会走`methodMatcher.matches(method, targetClass)`。

会执行`TransactionAttributeSourcePointcut`中的`matches`

```java
public boolean matches(Method method, @Nullable Class<?> targetClass) {
		if (targetClass != null && TransactionalProxy.class.isAssignableFrom(targetClass)) {
			return false;
		}
		TransactionAttributeSource tas = getTransactionAttributeSource();
		return (tas == null || tas.getTransactionAttribute(method, targetClass) != null);
	}
```

然后进入`getTransactionAttribute`，而此时的tas是`AnnotationTransactionAttributeSource`，通过解析标签是内嵌过去的。但是这个里没有实现，所以去父类中查找`AbstractFallbackTransactionAttributeSource`

```java
public TransactionAttribute getTransactionAttribute(Method method, @Nullable Class<?> targetClass) {
		if (method.getDeclaringClass() == Object.class) {
			return null;
		}

		// First, see if we have a cached value.
		Object cacheKey = getCacheKey(method, targetClass);
		Object cached = this.attributeCache.get(cacheKey);
		if (cached != null) {
			// Value will either be canonical value indicating there is no transaction attribute,
			// or an actual transaction attribute.
			if (cached == NULL_TRANSACTION_ATTRIBUTE) {
				return null;
			}
			else {
				return (TransactionAttribute) cached;
			}
		}
		else {
			// We need to work it out.
			TransactionAttribute txAttr = computeTransactionAttribute(method, targetClass);
			// Put it in the cache.
			if (txAttr == null) {
				this.attributeCache.put(cacheKey, NULL_TRANSACTION_ATTRIBUTE);
			}
			else {
				String methodIdentification = ClassUtils.getQualifiedMethodName(method, targetClass);
				if (txAttr instanceof DefaultTransactionAttribute) {
					((DefaultTransactionAttribute) txAttr).setDescriptor(methodIdentification);
				}
				if (logger.isDebugEnabled()) {
					logger.debug("Adding transactional method '" + methodIdentification + "' with attribute: " + txAttr);
				}
				this.attributeCache.put(cacheKey, txAttr);
			}
			return txAttr;
		}
	}
```

这里先从缓存中获取，如果为空则调用`computeTransactionAttribute`

```java
protected TransactionAttribute computeTransactionAttribute(Method method, @Nullable Class<?> targetClass) {
		// Don't allow no-public methods as required.
		if (allowPublicMethodsOnly() && !Modifier.isPublic(method.getModifiers())) {
			return null;
		}

		// The method may be on an interface, but we need attributes from the target class.
		// If the target class is null, the method will be unchanged.
		Method specificMethod = AopUtils.getMostSpecificMethod(method, targetClass);

		// First try is the method in the target class.
		TransactionAttribute txAttr = findTransactionAttribute(specificMethod);
		if (txAttr != null) {
			return txAttr;
		}

		// Second try is the transaction attribute on the target class.
		txAttr = findTransactionAttribute(specificMethod.getDeclaringClass());
		if (txAttr != null && ClassUtils.isUserLevelMethod(method)) {
			return txAttr;
		}

		if (specificMethod != method) {
			// Fallback is to look at the original method.
			txAttr = findTransactionAttribute(method);
			if (txAttr != null) {
				return txAttr;
			}
			// Last fallback is the class of the original method.
			txAttr = findTransactionAttribute(method.getDeclaringClass());
			if (txAttr != null && ClassUtils.isUserLevelMethod(method)) {
				return txAttr;
			}
		}

		return null;
	}
```

首先寻找实现类中的方法，通过`getMostSpecificMethod`方法获取实现类的方法。

然后判断方法是否存在事务声明通过`findTransactionAttribute`方法。

然后判断放在的所在类中是否存在事务声明，通过`findTransactionAttribute`方法。

如果存在接口，再去接口的方法看看有没有事务声明，然后再看接口有没有事务声明。

具体如何判断是否有事务声明，进入findTransactionAttribute方法

```java
protected TransactionAttribute findTransactionAttribute(Class<?> clazz) {
		return determineTransactionAttribute(clazz);
	}
。。。
protected TransactionAttribute determineTransactionAttribute(AnnotatedElement ae) {
		for (TransactionAnnotationParser annotationParser : this.annotationParsers) {
			TransactionAttribute attr = annotationParser.parseTransactionAnnotation(ae);
			if (attr != null) {
				return attr;
			}
		}
		return null;
	}
```

其中的`annotationParsers`属性时，实例化的时候加进去的

```java
public AnnotationTransactionAttributeSource(boolean publicMethodsOnly) {
		this.publicMethodsOnly = publicMethodsOnly;
		this.annotationParsers = new LinkedHashSet<>(2);
		this.annotationParsers.add(new SpringTransactionAnnotationParser());
		if (jta12Present) {
			this.annotationParsers.add(new JtaTransactionAnnotationParser());
		}
		if (ejb3Present) {
			this.annotationParsers.add(new Ejb3TransactionAnnotationParser());
		}
	}
```

所以上面`annotationParser.parseTransactionAnnotation(ae)` 会执行`SpringTransactionAnnotationParser`中的

```java
public TransactionAttribute parseTransactionAnnotation(AnnotatedElement ae) {
		AnnotationAttributes attributes = AnnotatedElementUtils.findMergedAnnotationAttributes(
				ae, Transactional.class, false, false);
		if (attributes != null) {
			return parseTransactionAnnotation(attributes);
		}
		else {
			return null;
		}
	}
。。。
protected TransactionAttribute parseTransactionAnnotation(AnnotationAttributes attributes) {
		RuleBasedTransactionAttribute rbta = new RuleBasedTransactionAttribute();
		Propagation propagation = attributes.getEnum("propagation");
		rbta.setPropagationBehavior(propagation.value());
		Isolation isolation = attributes.getEnum("isolation");
		rbta.setIsolationLevel(isolation.value());
		rbta.setTimeout(attributes.getNumber("timeout").intValue());
		rbta.setReadOnly(attributes.getBoolean("readOnly"));
		rbta.setQualifier(attributes.getString("value"));
		ArrayList<RollbackRuleAttribute> rollBackRules = new ArrayList<>();
		Class<?>[] rbf = attributes.getClassArray("rollbackFor");
		for (Class<?> rbRule : rbf) {
			RollbackRuleAttribute rule = new RollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		String[] rbfc = attributes.getStringArray("rollbackForClassName");
		for (String rbRule : rbfc) {
			RollbackRuleAttribute rule = new RollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		Class<?>[] nrbf = attributes.getClassArray("noRollbackFor");
		for (Class<?> rbRule : nrbf) {
			NoRollbackRuleAttribute rule = new NoRollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		String[] nrbfc = attributes.getStringArray("noRollbackForClassName");
		for (String rbRule : nrbfc) {
			NoRollbackRuleAttribute rule = new NoRollbackRuleAttribute(rbRule);
			rollBackRules.add(rule);
		}
		rbta.getRollbackRules().addAll(rollBackRules);
		return rbta;
	}
```

而这个里面就是做的解析工作，会解析@Transaction中配置的各种属性。

而到这里，初始化工作就全部完成了。到这里bean完成了依赖注入，而其中初始化后对这个bean进行了增强。在调用这个bean的时候会调用这个类的Advisor增强实现类BeanFactoryTransactionAttributeSourceAdvisor.class。而在上面标签解析的时候，会把一个TransactionInterceptor类型的bean内嵌到了BeanFactoryTransactionAttributeSourceAdvisor中，所以具体调用的时候会首先执行TransactionInterceptor进行增强。

#### 事务使用

所以在调用bean时，会先执行TransactionInterceptor中的invoke方法。

**这个地方不明白为什么会调用**

```java
public Object invoke(final MethodInvocation invocation) throws Throwable {
		// Work out the target class: may be {@code null}.
		// The TransactionAttributeSource should be passed the target class
		// as well as the method, which may be from an interface.
		Class<?> targetClass = (invocation.getThis() != null ? AopUtils.getTargetClass(invocation.getThis()) : null);

		// Adapt to TransactionAspectSupport's invokeWithinTransaction...
		return invokeWithinTransaction(invocation.getMethod(), targetClass, invocation::proceed);
	}
...
protected Object invokeWithinTransaction(Method method, @Nullable Class<?> targetClass,
			final InvocationCallback invocation) throws Throwable {

		// If the transaction attribute is null, the method is non-transactional.
		TransactionAttributeSource tas = getTransactionAttributeSource();
		final TransactionAttribute txAttr = (tas != null ? tas.getTransactionAttribute(method, targetClass) : null);
		final PlatformTransactionManager tm = determineTransactionManager(txAttr);
		final String joinpointIdentification = methodIdentification(method, targetClass, txAttr);

		if (txAttr == null || !(tm instanceof CallbackPreferringPlatformTransactionManager)) {
			// Standard transaction demarcation with getTransaction and commit/rollback calls.
			TransactionInfo txInfo = createTransactionIfNecessary(tm, txAttr, joinpointIdentification);
			Object retVal = null;
			try {
				// This is an around advice: Invoke the next interceptor in the chain.
				// This will normally result in a target object being invoked.
				retVal = invocation.proceedWithInvocation();
			}
			catch (Throwable ex) {
				// target invocation exception
				completeTransactionAfterThrowing(txInfo, ex);
				throw ex;
			}
			finally {
				cleanupTransactionInfo(txInfo);
			}
			commitTransactionAfterReturning(txInfo);
			return retVal;
		}

		else {
			final ThrowableHolder throwableHolder = new ThrowableHolder();

			// It's a CallbackPreferringPlatformTransactionManager: pass a TransactionCallback in.
			try {
				Object result = ((CallbackPreferringPlatformTransactionManager) tm).execute(txAttr, status -> {
					TransactionInfo txInfo = prepareTransactionInfo(tm, txAttr, joinpointIdentification, status);
					try {
						return invocation.proceedWithInvocation();
					}
					catch (Throwable ex) {
						if (txAttr.rollbackOn(ex)) {
							// A RuntimeException: will lead to a rollback.
							if (ex instanceof RuntimeException) {
								throw (RuntimeException) ex;
							}
							else {
								throw new ThrowableHolderException(ex);
							}
						}
						else {
							// A normal return value: will lead to a commit.
							throwableHolder.throwable = ex;
							return null;
						}
					}
					finally {
						cleanupTransactionInfo(txInfo);
					}
				});

				// Check result state: It might indicate a Throwable to rethrow.
				if (throwableHolder.throwable != null) {
					throw throwableHolder.throwable;
				}
				return result;
			}
			catch (ThrowableHolderException ex) {
				throw ex.getCause();
			}
			catch (TransactionSystemException ex2) {
				if (throwableHolder.throwable != null) {
					logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
					ex2.initApplicationException(throwableHolder.throwable);
				}
				throw ex2;
			}
			catch (Throwable ex2) {
				if (throwableHolder.throwable != null) {
					logger.error("Application exception overridden by commit exception", throwableHolder.throwable);
				}
				throw ex2;
			}
		}
	}
```

首先获取事务属性源，`AnnotationTransactionAttributeSource`.

获取事务属性，获取transactionManager,获取事务方法

做判断处理，如果是声明式事务处理过程，如果是编程式事务的处理过程。

这里以声明式为例子：

首先创建事务，通过`createTransactionIfNecessary`方法。

```java
protected TransactionInfo createTransactionIfNecessary(@Nullable PlatformTransactionManager tm,
			@Nullable TransactionAttribute txAttr, final String joinpointIdentification) {

		// If no name specified, apply method identification as transaction name.
		if (txAttr != null && txAttr.getName() == null) {
			txAttr = new DelegatingTransactionAttribute(txAttr) {
				@Override
				public String getName() {
					return joinpointIdentification;
				}
			};
		}

		TransactionStatus status = null;
		if (txAttr != null) {
			if (tm != null) {
				status = tm.getTransaction(txAttr);
			}
			else {
				if (logger.isDebugEnabled()) {
					logger.debug("Skipping transactional joinpoint [" + joinpointIdentification +
							"] because no transaction manager has been configured");
				}
			}
		}
		return prepareTransactionInfo(tm, txAttr, joinpointIdentification, status);
	}
```









