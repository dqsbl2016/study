# Annotation

从Spring 2.0 以后的版本中，Spring引入了基于注解`Annotation`的配置方式，注解是JDK1.5中引入的一个新特性，用于简化bean的配置，某些场合可以取代XML配置文件。

Spring IOC 容器对于类级别的注解和类内部的注解分为两种策略：

* **类级别的注解**  如 `@Component`、`@Repository`、`@Controller`、`@Service`以及JDK 1.6以后的`@ManagedBean`和`@Named`注解，都是天津在类上面的类级别注解。Spring根据直接的过滤规则扫描读取注解Bean定义类，并将其注册到Spring IOC容器中。
* **类内部的注解**  如`@Autowire`、`@Value`、`@Resource`等，Spring IOC容器通过Bean后置注解处理器解析Bean内部注解。



##  AnnotationConfigApplicationContext

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

##  AnnotationConfigWebApplicationContext

`AnnotationConfigWebApplicationContext`是`AnnotationConfigApplicationContext`的Web版。

对注解Bean定义的载入不同。

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

***暂未研究***



