# Annotation

从Spring 2.0 以后的版本中，Spring引入了基于注解`Annotation`的配置方式，注解是JDK1.5中引入的一个新特性，用于简化bean的配置，某些场合可以取代XML配置文件。

Spring IOC 容器对于类级别的注解和类内部的注解分为两种策略：

* **类级别的注解**  如 `@Component`、`@Repository`、`@Controller`、`@Service`以及JDK 1.6以后的`@ManagedBean`和`@Named`注解，都是天津在类上面的类级别注解。Spring根据直接的过滤规则扫描读取注解Bean定义类，并将其注册到Spring IOC容器中。
* **类内部的注解**  如`@Autowire`、`@Value`、`@Resource`等，Spring IOC容器通过Bean后置注解处理器解析Bean内部注解。



##  AnnotationConfigApplicationContext（注解初始化）

其中`AnnotationConfigApplicationContext`中提供了2种IOC容器注册方式：

### 直接将注解Bean注册到容器中

通过调用`register`方法，执行IOC容器注册操作。

```java
public void register(Class<?>... annotatedClasses) {
		Assert.notEmpty(annotatedClasses, "At least one annotated class must be specified");
		this.reader.register(annotatedClasses);
	}
```

注册的操作在`AnnotationConfigApplicationContext`内部的`AnnotatedBeanDefinitionReader reader`实例对象中，在`AnnotationConfigApplicationContext`构造函数中会为`reader`变量设置个`AnnotatedBeanDefinitionReader`的对象。具体通过`AnnotatedBeanDefinitionReader`中的`doRegisterBean`方法进行处理。

```java
<T> void doRegisterBean(Class<T> annotatedClass, @Nullable Supplier<T> instanceSupplier, @Nullable String name,
			@Nullable Class<? extends Annotation>[] qualifiers, BeanDefinitionCustomizer... definitionCustomizers) {
		AnnotatedGenericBeanDefinition abd = new AnnotatedGenericBeanDefinition(annotatedClass);
		if (this.conditionEvaluator.shouldSkip(abd.getMetadata())) {
			return;
		}
		abd.setInstanceSupplier(instanceSupplier);
		ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(abd);
		abd.setScope(scopeMetadata.getScopeName());
		String beanName = (name != null ? name : 		         this.beanNameGenerator.generateBeanName(abd, this.registry));
		AnnotationConfigUtils.processCommonDefinitionAnnotations(abd);
		if (qualifiers != null) {
			for (Class<? extends Annotation> qualifier : qualifiers) {
				if (Primary.class == qualifier) {
					abd.setPrimary(true);
				}
				else if (Lazy.class == qualifier) {
					abd.setLazyInit(true);
				}
				else {
					abd.addQualifier(new AutowireCandidateQualifier(qualifier));
				}
			}
		}
		for (BeanDefinitionCustomizer customizer : definitionCustomizers) {
			customizer.customize(abd);
		}

		BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(abd, beanName);
		definitionHolder = AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
		BeanDefinitionReaderUtils.registerBeanDefinition(definitionHolder, this.registry);
	}
```

具体操作步骤：

* 创建`beandefinition`，这里创建的是一个`AnnotatedGenericBeanDefinition`的实例；
* 使用注解元数据解析器解析注解 Bean 中关于作用域的配置;
* 处理bean内部中定义的通用注解，通过`processCommonDefinitionAnnotations`;
* 使用 `AnnotationConfigUtils` 的` applyScopedProxyMode` 方法创建对于作用域的代理对象;
* 通过 `BeanDefinitionReaderUtils` 向容器注册 Bean;

首先了解一下元数据解析器中的操作，通过`resolveScopeMetadata`方法。

```java
@Override
	public ScopeMetadata resolveScopeMetadata(BeanDefinition definition) {
		ScopeMetadata metadata = new ScopeMetadata();
		if (definition instanceof AnnotatedBeanDefinition) {
			AnnotatedBeanDefinition annDef = (AnnotatedBeanDefinition) definition;
			AnnotationAttributes attributes = AnnotationConfigUtils.attributesFor(
					annDef.getMetadata(), this.scopeAnnotationType);
			if (attributes != null) {
				metadata.setScopeName(attributes.getString("value"));
				ScopedProxyMode proxyMode = attributes.getEnum("proxyMode");
				if (proxyMode == ScopedProxyMode.DEFAULT) {
					proxyMode = this.defaultProxyMode;
				}
				metadata.setScopedProxyMode(proxyMode);
			}
		}
		return metadata;
	}
```

通过`annDef.getMetadata()`获取到元信息，并通过`AnnotationConfigUtils.attributesFor`转换为`AnnotationAttributes`对象，再获取其中的作用域等信息封装后返回。

再回到上面方法，在处理通用定义注解解析时，是通过`AnnotationConfigUtils`中的`processCommonDefinitionAnnotations`方法进入。

```java
static void processCommonDefinitionAnnotations(AnnotatedBeanDefinition abd, AnnotatedTypeMetadata metadata) {
		AnnotationAttributes lazy = attributesFor(metadata, Lazy.class);
		if (lazy != null) {
			abd.setLazyInit(lazy.getBoolean("value"));
		}
		else if (abd.getMetadata() != metadata) {
			lazy = attributesFor(abd.getMetadata(), Lazy.class);
			if (lazy != null) {
				abd.setLazyInit(lazy.getBoolean("value"));
			}
		}

		if (metadata.isAnnotated(Primary.class.getName())) {
			abd.setPrimary(true);
		}
		AnnotationAttributes dependsOn = attributesFor(metadata, DependsOn.class);
		if (dependsOn != null) {
			abd.setDependsOn(dependsOn.getStringArray("value"));
		}

		if (abd instanceof AbstractBeanDefinition) {
			AbstractBeanDefinition absBd = (AbstractBeanDefinition) abd;
			AnnotationAttributes role = attributesFor(metadata, Role.class);
			if (role != null) {
				absBd.setRole(role.getNumber("value").intValue());
			}
			AnnotationAttributes description = attributesFor(metadata, Description.class);
			if (description != null) {
				absBd.setDescription(description.getString("value"));
			}
		}
	}
```

这些通用标签包括`@Lazy`,`@Primary`，`@DependsOn`,`@Role`,`@Description`。

* `@Lazy`: 用于指定该Bean是否取消预初始化。主要用于修饰Spring Bean类，用于指定该Bean的预初始化行为。
*  `@Primary` : 对同一个接口，可能会有几种不同的实现类，而默认只会采取其中一种的情况，可以使用`@Primary`注解代表默认使用这个实现类。而在这里就是具体实现方法，判断当这个bean存在这个注解后，会对封装这个bean的`beandefinition`设置`abd.setPrimary(true)`。
*  `@DependsOn` :  用于强制初始化其他Bean。可以修饰Bean类或方法，使用该Annotation时可以指定一个字符串数组作为参数，每个数组元素对应于一个强制初始化的Bean。 
* `@Role` :  表示给定bean的“角色”提示。 
* `@Description`： 对bean的描述信息。

继续了解 根据注解 Bean 定义类中配置的作用域为其应用相应的代理策略，通过`AnnotationConfigUtils` 的` applyScopedProxyMode`方法。

```java
static BeanDefinitionHolder applyScopedProxyMode(
			ScopeMetadata metadata, BeanDefinitionHolder definition, BeanDefinitionRegistry registry) {

		ScopedProxyMode scopedProxyMode = metadata.getScopedProxyMode();
		if (scopedProxyMode.equals(ScopedProxyMode.NO)) {
			return definition;
		}
		boolean proxyTargetClass = scopedProxyMode.equals(ScopedProxyMode.TARGET_CLASS);
		return ScopedProxyCreator.createScopedProxy(definition, registry, proxyTargetClass);
	}
```

根据注解 Bean 定义类中配置的作用域`@Scope` 注解的值，为 Bean 定义应用相应的代理模式，主要是在 Spring 面向切面编程(AOP)中使用。

通过`BeanDefinitionReaderUtils` 向容器注册 Bean，这里主要就是向IOC容器注册`beandefinition`以及别名的集合。

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

### 通过扫描指定的包及其子包下的所有类

通过调用`scan`方法，对路径进行扫描。

```java
public AnnotationConfigApplicationContext(String... basePackages) {
		this();
		scan(basePackages);
		refresh();
	}
```

扫描使用`ClassPathBeanDefinitionScanner`来实现，同样是构造函数中对`scanner`变量进行设置`ClassPathBeanDefinitionScanner`的实例。

```java
public int scan(String... basePackages) {
		int beanCountAtScanStart = this.registry.getBeanDefinitionCount();

		doScan(basePackages);

		// Register annotation config processors, if necessary.
		if (this.includeAnnotationConfig) {
			AnnotationConfigUtils.registerAnnotationConfigProcessors(this.registry);
		}

		return (this.registry.getBeanDefinitionCount() - beanCountAtScanStart);
	}
...
protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
		Assert.notEmpty(basePackages, "At least one base package must be specified");
		Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<>();
		for (String basePackage : basePackages) {
			Set<BeanDefinition> candidates = findCandidateComponents(basePackage);
			for (BeanDefinition candidate : candidates) {
				ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(candidate);
				candidate.setScope(scopeMetadata.getScopeName());
				String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
				if (candidate instanceof AbstractBeanDefinition) {
					postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
				}
				if (candidate instanceof AnnotatedBeanDefinition) {
					AnnotationConfigUtils.processCommonDefinitionAnnotations((AnnotatedBeanDefinition) candidate);
				}
				if (checkCandidate(beanName, candidate)) {
					BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(candidate, beanName);
					definitionHolder =
							AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
					beanDefinitions.add(definitionHolder);
					registerBeanDefinition(definitionHolder, this.registry);
				}
			}
		}
		return beanDefinitions;
	}
```

具体操作步骤：

* 通过调用父类`ClassPathScanningCandidateComponentProvider`的`findCandidateComponents`方法来扫描指定包及其子包下的类。
* 遍历每一个`beandefinition`设置作用域；
* 注册到IOC容器中，通过`registerBeanDefinition`；

### `refresh`

无论采用上面2种方式的哪种，都会调用`refresh`方法，这个与XML配置的入口执行一直。

不过当执行到`AbstractRefreshableApplicationContext`中`refreshBeanFactory`方法时，调用的`loadBeanDefinitions(beanFactory)`这个方法执行的位置缺不一样了，这个是个模板方法，而当前调用的子类是`AnnotationConfigWebApplicationContext`。所以下一步进入的是`AnnotationConfigWebApplicationContext`中的`loadBeanDefinitions(beanFactory)`方法。

### AnnotationConfigWebApplicationContext

```java
@Override
	protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) {
		AnnotatedBeanDefinitionReader reader = getAnnotatedBeanDefinitionReader(beanFactory);
		ClassPathBeanDefinitionScanner scanner = getClassPathBeanDefinitionScanner(beanFactory);

		BeanNameGenerator beanNameGenerator = getBeanNameGenerator();
		if (beanNameGenerator != null) {
			reader.setBeanNameGenerator(beanNameGenerator);
			scanner.setBeanNameGenerator(beanNameGenerator);
			beanFactory.registerSingleton(AnnotationConfigUtils.CONFIGURATION_BEAN_NAME_GENERATOR, beanNameGenerator);
		}

		ScopeMetadataResolver scopeMetadataResolver = getScopeMetadataResolver();
		if (scopeMetadataResolver != null) {
			reader.setScopeMetadataResolver(scopeMetadataResolver);
			scanner.setScopeMetadataResolver(scopeMetadataResolver);
		}

		if (!this.annotatedClasses.isEmpty()) {
			if (logger.isInfoEnabled()) {
				logger.info("Registering annotated classes: [" +
						StringUtils.collectionToCommaDelimitedString(this.annotatedClasses) + "]");
			}
			reader.register(ClassUtils.toClassArray(this.annotatedClasses));
		}

		if (!this.basePackages.isEmpty()) {
			if (logger.isInfoEnabled()) {
				logger.info("Scanning base packages: [" +
						StringUtils.collectionToCommaDelimitedString(this.basePackages) + "]");
			}
			scanner.scan(StringUtils.toStringArray(this.basePackages));
		}

		String[] configLocations = getConfigLocations();
		if (configLocations != null) {
			for (String configLocation : configLocations) {
				try {
					Class<?> clazz = ClassUtils.forName(configLocation, getClassLoader());
					if (logger.isInfoEnabled()) {
						logger.info("Successfully resolved class for [" + configLocation + "]");
					}
					reader.register(clazz);
				}
				catch (ClassNotFoundException ex) {
					if (logger.isDebugEnabled()) {
						logger.debug("Could not load class for config location [" + configLocation +
								"] - trying package scan. " + ex);
					}
					int count = scanner.scan(configLocation);
					if (logger.isInfoEnabled()) {
						if (count == 0) {
							logger.info("No annotated classes found for specified class/package [" + configLocation + "]");
						}
						else {
							logger.info("Found " + count + " annotated classes in package [" + configLocation + "]");
						}
					}
				}
			}
		}
	}

```

这里主要包括一些准备工作；

* 创建一个`AnnotatedBeanDefinitionReader`读取器
* 创建一个`ClassPathBeanDefinitionScanner`扫描器
* 创建一个`BeanNameGenerator`
* 创建一个`ScopeMetadataResolver`
* 执行`reader.register(ClassUtils.toClassArray(this.annotatedClasses));`

首先进入`AnnotatedBeanDefinitionReader`的`register`方法中

```java
public void register(Class<?>... annotatedClasses) {
		for (Class<?> annotatedClass : annotatedClasses) {
			registerBean(annotatedClass);
		}
	}
...
public void registerBean(Class<?> annotatedClass) {
		doRegisterBean(annotatedClass, null, null, null);
	}
...
<T> void doRegisterBean(Class<T> annotatedClass, @Nullable Supplier<T> instanceSupplier, @Nullable String name,
			@Nullable Class<? extends Annotation>[] qualifiers, BeanDefinitionCustomizer... definitionCustomizers) {
//根据指定的注解 Bean 定义类，创建 Spring 容器中对注解 Bean 的封装的数据结构
		AnnotatedGenericBeanDefinition abd = new AnnotatedGenericBeanDefinition(annotatedClass);
		if (this.conditionEvaluator.shouldSkip(abd.getMetadata())) {
			return;
		}

		abd.setInstanceSupplier(instanceSupplier);
    //解析注解 Bean 定义的作用域，若@Scope("prototype")，则 Bean 为原型类型；
//若@Scope("singleton")，则 Bean 为单态类型
		ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(abd);
		abd.setScope(scopeMetadata.getScopeName());
		String beanName = (name != null ? name : this.beanNameGenerator.generateBeanName(abd, this.registry));
//处理注解 Bean 定义中的通用注解
		AnnotationConfigUtils.processCommonDefinitionAnnotations(abd);
    //如果在向容器注册注解 Bean 定义时，使用了额外的限定符注解，则解析限定符注解。
//主要是配置的关于 autowiring 自动依赖注入装配的限定条件，即@Qualifier 注解
//Spring 自动依赖注入装配默认是按类型装配，如果使用@Qualifier 则按名称
		if (qualifiers != null) {
			for (Class<? extends Annotation> qualifier : qualifiers) {
				if (Primary.class == qualifier) {
					abd.setPrimary(true);
				}
				else if (Lazy.class == qualifier) {
					abd.setLazyInit(true);
				}
				else {
					abd.addQualifier(new AutowireCandidateQualifier(qualifier));
				}
			}
		}
		for (BeanDefinitionCustomizer customizer : definitionCustomizers) {
			customizer.customize(abd);
		}

		BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(abd, beanName);
    //根据注解 Bean 定义类中配置的作用域，创建相应的代理对象
		definitionHolder = AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
		BeanDefinitionReaderUtils.registerBeanDefinition(definitionHolder, this.registry);
	}
```

这里操作变得复杂，进行下业务梳理

* 使用注解元数据解析器解析注解Bean中关于作用域的配置

* 解析作用域元数据 通过`resolveScopeMetadata`方法

  ```java
  public ScopeMetadata resolveScopeMetadata(BeanDefinition definition) {
  		ScopeMetadata metadata = new ScopeMetadata();
  		if (definition instanceof AnnotatedBeanDefinition) {
  			AnnotatedBeanDefinition annDef = (AnnotatedBeanDefinition) definition;
  			AnnotationAttributes attributes = AnnotationConfigUtils.attributesFor(
  					annDef.getMetadata(), this.scopeAnnotationType);
  			if (attributes != null) {
  				metadata.setScopeName(attributes.getString("value"));
  				ScopedProxyMode proxyMode = attributes.getEnum("proxyMode");
  				if (proxyMode == ScopedProxyMode.DEFAULT) {
  					proxyMode = this.defaultProxyMode;
  				}
  				metadata.setScopedProxyMode(proxyMode);
  			}
  		}
  		return metadata;
  	}
  ```

* 使用 `AnnotationConfigUtils` 的 `processCommonDefinitionAnnotations` 方法处理注解 Bean
  定义类中通用的注解。

  ```java
  static void processCommonDefinitionAnnotations(AnnotatedBeanDefinition abd, AnnotatedTypeMetadata metadata) {
  		AnnotationAttributes lazy = attributesFor(metadata, Lazy.class);
  		if (lazy != null) {
  			abd.setLazyInit(lazy.getBoolean("value"));
  		}
  		else if (abd.getMetadata() != metadata) {
  			lazy = attributesFor(abd.getMetadata(), Lazy.class);
  			if (lazy != null) {
  				abd.setLazyInit(lazy.getBoolean("value"));
  			}
  		}
  
  		if (metadata.isAnnotated(Primary.class.getName())) {
  			abd.setPrimary(true);
  		}
  		AnnotationAttributes dependsOn = attributesFor(metadata, DependsOn.class);
  		if (dependsOn != null) {
  			abd.setDependsOn(dependsOn.getStringArray("value"));
  		}
  
  		if (abd instanceof AbstractBeanDefinition) {
  			AbstractBeanDefinition absBd = (AbstractBeanDefinition) abd;
  			AnnotationAttributes role = attributesFor(metadata, Role.class);
  			if (role != null) {
  				absBd.setRole(role.getNumber("value").intValue());
  			}
  			AnnotationAttributes description = attributesFor(metadata, Description.class);
  			if (description != null) {
  				absBd.setDescription(description.getString("value"));
  			}
  		}
  	}
  ```

  通用注解只包括`lazy`，`Primary`，`DependsOn`，`Role`，`Description`这些标签的处理。

* 使用` AnnotationConfigUtils `的` applyScopedProxyMode` 方法创建对于作用域的代理对象。

  ```java
  static BeanDefinitionHolder applyScopedProxyMode(
  			ScopeMetadata metadata, BeanDefinitionHolder definition, BeanDefinitionRegistry registry) {
  
  		ScopedProxyMode scopedProxyMode = metadata.getScopedProxyMode();
  		if (scopedProxyMode.equals(ScopedProxyMode.NO)) {
  			return definition;
  		}
  		boolean proxyTargetClass = scopedProxyMode.equals(ScopedProxyMode.TARGET_CLASS);
  		return ScopedProxyCreator.createScopedProxy(definition, registry, proxyTargetClass);
  	}
  ```

  通过`ScopedProxyCreator.createScopedProxy(definition, registry, proxyTargetClass);`创建对于作用域的代理对象。

  ```java
  public static BeanDefinitionHolder createScopedProxy(
  			BeanDefinitionHolder definitionHolder, BeanDefinitionRegistry registry, boolean proxyTargetClass) {
  		return ScopedProxyUtils.createScopedProxy(definitionHolder, registry, proxyTargetClass);
  	}
  ...
  public static BeanDefinitionHolder createScopedProxy(BeanDefinitionHolder definition,
  			BeanDefinitionRegistry registry, boolean proxyTargetClass) {
  
  		String originalBeanName = definition.getBeanName();
  		BeanDefinition targetDefinition = definition.getBeanDefinition();
  		String targetBeanName = getTargetBeanName(originalBeanName);
  
  		// Create a scoped proxy definition for the original bean name,
  		// "hiding" the target bean in an internal target definition.
  		RootBeanDefinition proxyDefinition = new RootBeanDefinition(ScopedProxyFactoryBean.class);
  		proxyDefinition.setDecoratedDefinition(new BeanDefinitionHolder(targetDefinition, targetBeanName));
  		proxyDefinition.setOriginatingBeanDefinition(targetDefinition);
  		proxyDefinition.setSource(definition.getSource());
  		proxyDefinition.setRole(targetDefinition.getRole());
  
  		proxyDefinition.getPropertyValues().add("targetBeanName", targetBeanName);
  		if (proxyTargetClass) {
  			targetDefinition.setAttribute(AutoProxyUtils.PRESERVE_TARGET_CLASS_ATTRIBUTE, Boolean.TRUE);
  			// ScopedProxyFactoryBean's "proxyTargetClass" default is TRUE, so we don't need to set it explicitly here.
  		}
  		else {
  			proxyDefinition.getPropertyValues().add("proxyTargetClass", Boolean.FALSE);
  		}
  
  		// Copy autowire settings from original bean definition.
  		proxyDefinition.setAutowireCandidate(targetDefinition.isAutowireCandidate());
  		proxyDefinition.setPrimary(targetDefinition.isPrimary());
  		if (targetDefinition instanceof AbstractBeanDefinition) {
  			proxyDefinition.copyQualifiersFrom((AbstractBeanDefinition) targetDefinition);
  		}
  
  		// The target bean should be ignored in favor of the scoped proxy.
  		targetDefinition.setAutowireCandidate(false);
  		targetDefinition.setPrimary(false);
  
  		// Register the target bean as separate bean in the factory.
  		registry.registerBeanDefinition(targetBeanName, targetDefinition);
  
  		// Return the scoped proxy definition as primary bean definition
  		// (potentially an inner bean).
  		return new BeanDefinitionHolder(proxyDefinition, originalBeanName, definition.getAliases());
  	}
  ```

  主要创建一份代理对象，并且注入到IOC容器中，代理对象命名规则为`scopedTarget.`+`originalBeanName（原BeanName）`。

* 通过 `BeanDefinitionReaderUtils `向容器注册 Bean。

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

  具体逻辑与XML方式一致，注册到IOC容器，并注册别名容器。

**具体如何处理详细标签未深入了解 **







# 自动装配

```
/**
 * 自动装配;
 *        Spring利用依赖注入（DI），完成对IOC容器中中各个组件的依赖关系赋值；
 * 
 * 1）、@Autowired：自动注入：（按类型装配）
 *        1）、默认优先按照类型去容器中找对应的组件:applicationContext.getBean(BookDao.class);找到就赋值
 *        2）、如果找到多个相同类型的组件，再将属性的名称作为组件的id去容器中查找
 *                       applicationContext.getBean("bookDao")
 *        3）、@Qualifier("bookDao")：使用@Qualifier指定需要装配的组件的id，而不是使用属性名
 *        4）、自动装配默认一定要将属性赋值好，没有就会报错；
 *             可以使用@Autowired(required=false);
 *        5）、@Primary：让Spring进行自动装配的时候，默认使用首选的bean；
 *              也可以继续使用@Qualifier指定需要装配的bean的名字
 *        
 * 2）、Spring还支持使用@Resource(JSR250)和@Inject(JSR330)[java规范的注解]
 *        @Resource:
 *           可以和@Autowired一样实现自动装配功能；默认是按照组件名称进行装配的；
 *           没有能支持@Primary功能没有支持@Autowired（reqiured=false）;
 *        @Inject:
 *           需要导入javax.inject的包，和Autowired的功能一样。没有required=false的功能；
 *  区别： @Autowired:Spring定义的，按类型装配； @Resource、@Inject都是java规范，按name装配
 *     
 * AutowiredAnnotationBeanPostProcessor:解析完成自动装配功能；       
 * 
 * 3）、 @Autowired:构造器，参数，方法，属性；都是从容器中获取参数组件的值
 *        1）、[标注在方法位置]：@Bean+方法参数；参数从容器中获取;默认不写@Autowired效果是一样的；都能自动装配
 *        2）、[标在构造器上]：如果组件只有一个有参构造器，这个有参构造器的@Autowired可以省略，参数位置的组件还是可以自动从容器中获取
 *        3）、放在参数位置：
 * 
 * 4）、自定义组件想要使用Spring容器底层的一些组件（ApplicationContext，BeanFactory，xxx）；
 *        自定义组件实现xxxAware；在创建对象的时候，会调用接口规定的方法注入相关组件；Aware；
 *        把Spring底层一些组件注入到自定义的Bean中；
 *        xxxAware：功能使用xxxProcessor来处理；
 *        ApplicationContextAware ==》 ApplicationContextAwareProcessor；
 
       Aware 的接口
          ApplicationContextAware        -->获取ApplicationContext 
          ApplicationEventPublisherAware -->获取ApplicationEventPublisher  事件派发器
          BeanClassLoaderAware           -->获取 ClassLoader    类加载器
          BeanFactoryAware               -->获取 BeanFactory   bean工厂
          BeanNameAware                  -->获取 beanName 
          EmbeddedValueResolverAware     -->获取 值解析器,解析占位符
          EnvironmentAware               -->获取 Environment  运行环境
          ImportAware                    -->获取 AnnotationMetadata   导入相关bean
          ResourceLoaderAware            -->获取 ResourceLoader   资源加载
          MessageSourceAware             -->获取 MessageSource    国际化
*/        
 
```

1.Autowired和Qualifier注解 (AutowiredAnnotationBeanPostProcessor处理，解析完成自动装配的功能)

```
@Qualifier("persionDao")   //使用@Qualifier指定需要装配的组件的id，而不是使用属性名
@Autowired(required = false)  //有persionDao这个bean就注解没有不报错
public PersionDao persionDao;


@Primary  //@Primary：让Spring进行自动装配的时候，默认使用首选的bean；多个bean优先选这个bean
@Bean
public PersionDao persionDao(){
    return new PersionDao();
}

```

2、Aware使用，实现相应的接口

```
@Component
public class Red implements ApplicationContextAware,BeanNameAware,EmbeddedValueResolverAware {
    
    private ApplicationContext applicationContext;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        // TODO Auto-generated method stub
        System.out.println("传入的ioc："+applicationContext);
        this.applicationContext = applicationContext;
    }

    @Override
    public void setBeanName(String name) {
        // TODO Auto-generated method stub
        System.out.println("当前bean的名字："+name);
    }

    @Override
    public void setEmbeddedValueResolver(StringValueResolver resolver) {
        // TODO Auto-generated method stub
        String resolveStringValue = resolver.resolveStringValue("你好 ${os.name} 我是 #{20*18}");
        System.out.println("解析的字符串："+resolveStringValue);
    }
}

```

