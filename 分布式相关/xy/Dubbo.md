# Dubbo

## 自定义标签的扩展DubboNamespaceHandler

dubbo采用了spring的自定义标签方式进行扩展。具体NameSpacehandler接口实现中。

```java
public class DubboNamespaceHandler extends NamespaceHandlerSupport {
    public DubboNamespaceHandler() {
    }

    public void init() {
        this.registerBeanDefinitionParser("application", new DubboBeanDefinitionParser(ApplicationConfig.class, true));
        this.registerBeanDefinitionParser("module", new DubboBeanDefinitionParser(ModuleConfig.class, true));
        this.registerBeanDefinitionParser("registry", new DubboBeanDefinitionParser(RegistryConfig.class, true));
        this.registerBeanDefinitionParser("monitor", new DubboBeanDefinitionParser(MonitorConfig.class, true));
        this.registerBeanDefinitionParser("provider", new DubboBeanDefinitionParser(ProviderConfig.class, true));
        this.registerBeanDefinitionParser("consumer", new DubboBeanDefinitionParser(ConsumerConfig.class, true));
        this.registerBeanDefinitionParser("protocol", new DubboBeanDefinitionParser(ProtocolConfig.class, true));
        this.registerBeanDefinitionParser("service", new DubboBeanDefinitionParser(ServiceBean.class, true));
        this.registerBeanDefinitionParser("reference", new DubboBeanDefinitionParser(ReferenceBean.class, false));
        this.registerBeanDefinitionParser("annotation", new DubboBeanDefinitionParser(AnnotationBean.class, true));
    }

    static {
        Version.checkDuplicate(DubboNamespaceHandler.class);
    }
}
```

其中定义了各种标签的解析器，但是其实都是一个解析器`DubboBeanDefinitionParser`但是根据不同的参数（class），来进行不同的处理。

```java
public DubboBeanDefinitionParser(Class<?> beanClass, boolean required) {
        this.beanClass = beanClass;
        this.required = required;
    }
...
public BeanDefinition parse(Element element, ParserContext parserContext) {
        return parse(element, parserContext, this.beanClass, this.required);
    }
。。。
private static BeanDefinition parse(Element element, ParserContext parserContext, Class<?> beanClass, boolean required) {
        RootBeanDefinition beanDefinition = new RootBeanDefinition();
        beanDefinition.setBeanClass(beanClass);
        beanDefinition.setLazyInit(false);
        String id = element.getAttribute("id");
        String className;
        int len$;
        if ((id == null || id.length() == 0) && required) {
            className = element.getAttribute("name");
            if (className == null || className.length() == 0) {
                if (ProtocolConfig.class.equals(beanClass)) {
                    className = "dubbo";
                } else {
                    className = element.getAttribute("interface");
                }
            }

            if (className == null || className.length() == 0) {
                className = beanClass.getName();
            }

            id = className;

            for(len$ = 2; parserContext.getRegistry().containsBeanDefinition(id); id = className + len$++) {
                ;
            }
        }

        if (id != null && id.length() > 0) {
            if (parserContext.getRegistry().containsBeanDefinition(id)) {
                throw new IllegalStateException("Duplicate spring bean id " + id);
            }

            parserContext.getRegistry().registerBeanDefinition(id, beanDefinition);
            beanDefinition.getPropertyValues().addPropertyValue("id", id);
        }

        if (ProtocolConfig.class.equals(beanClass)) {
            String[] arr$ = parserContext.getRegistry().getBeanDefinitionNames();
            len$ = arr$.length;

            for(int i$ = 0; i$ < len$; ++i$) {
                String name = arr$[i$];
                BeanDefinition definition = parserContext.getRegistry().getBeanDefinition(name);
                PropertyValue property = definition.getPropertyValues().getPropertyValue("protocol");
                if (property != null) {
                    Object value = property.getValue();
                    if (value instanceof ProtocolConfig && id.equals(((ProtocolConfig)value).getName())) {
                        definition.getPropertyValues().addPropertyValue("protocol", new RuntimeBeanReference(id));
                    }
                }
            }
        } else if (ServiceBean.class.equals(beanClass)) {
            className = element.getAttribute("class");
            if (className != null && className.length() > 0) {
                RootBeanDefinition classDefinition = new RootBeanDefinition();
                classDefinition.setBeanClass(ReflectUtils.forName(className));
                classDefinition.setLazyInit(false);
                parseProperties(element.getChildNodes(), classDefinition);
                beanDefinition.getPropertyValues().addPropertyValue("ref", new BeanDefinitionHolder(classDefinition, id + "Impl"));
            }
        } else if (ProviderConfig.class.equals(beanClass)) {
            parseNested(element, parserContext, ServiceBean.class, true, "service", "provider", id, beanDefinition);
        } else if (ConsumerConfig.class.equals(beanClass)) {
            parseNested(element, parserContext, ReferenceBean.class, false, "reference", "consumer", id, beanDefinition);
        }

        Set<String> props = new HashSet();
        ManagedMap parameters = null;
        Method[] arr$ = beanClass.getMethods();
        int len = arr$.length;

        int i;
        String name;
        for(i = 0; i < len; ++i) {
            Method setter = arr$[i];
            name = setter.getName();
            if (name.length() > 3 && name.startsWith("set") && Modifier.isPublic(setter.getModifiers()) && setter.getParameterTypes().length == 1) {
                Class<?> type = setter.getParameterTypes()[0];
                String property = StringUtils.camelToSplitName(name.substring(3, 4).toLowerCase() + name.substring(4), "-");
                props.add(property);
                Method getter = null;

                try {
                    getter = beanClass.getMethod("get" + name.substring(3));
                } catch (NoSuchMethodException var22) {
                    try {
                        getter = beanClass.getMethod("is" + name.substring(3));
                    } catch (NoSuchMethodException var21) {
                        ;
                    }
                }

                if (getter != null && Modifier.isPublic(getter.getModifiers()) && type.equals(getter.getReturnType())) {
                    if ("parameters".equals(property)) {
                        parameters = parseParameters(element.getChildNodes(), beanDefinition);
                    } else if ("methods".equals(property)) {
                        parseMethods(id, element.getChildNodes(), beanDefinition, parserContext);
                    } else if ("arguments".equals(property)) {
                        parseArguments(id, element.getChildNodes(), beanDefinition, parserContext);
                    } else {
                        String value = element.getAttribute(property);
                        if (value != null) {
                            value = value.trim();
                            if (value.length() > 0) {
                                if ("registry".equals(property) && "N/A".equalsIgnoreCase(value)) {
                                    RegistryConfig registryConfig = new RegistryConfig();
                                    registryConfig.setAddress("N/A");
                                    beanDefinition.getPropertyValues().addPropertyValue(property, registryConfig);
                                } else if ("registry".equals(property) && value.indexOf(44) != -1) {
                                    parseMultiRef("registries", value, beanDefinition, parserContext);
                                } else if ("provider".equals(property) && value.indexOf(44) != -1) {
                                    parseMultiRef("providers", value, beanDefinition, parserContext);
                                } else if ("protocol".equals(property) && value.indexOf(44) != -1) {
                                    parseMultiRef("protocols", value, beanDefinition, parserContext);
                                } else {
                                    Object reference;
                                    if (isPrimitive(type)) {
                                        if ("async".equals(property) && "false".equals(value) || "timeout".equals(property) && "0".equals(value) || "delay".equals(property) && "0".equals(value) || "version".equals(property) && "0.0.0".equals(value) || "stat".equals(property) && "-1".equals(value) || "reliable".equals(property) && "false".equals(value)) {
                                            value = null;
                                        }

                                        reference = value;
                                    } else if (!"protocol".equals(property) || !ExtensionLoader.getExtensionLoader(Protocol.class).hasExtension(value) || parserContext.getRegistry().containsBeanDefinition(value) && ProtocolConfig.class.getName().equals(parserContext.getRegistry().getBeanDefinition(value).getBeanClassName())) {
                                        if ("monitor".equals(property) && (!parserContext.getRegistry().containsBeanDefinition(value) || !MonitorConfig.class.getName().equals(parserContext.getRegistry().getBeanDefinition(value).getBeanClassName()))) {
                                            reference = convertMonitor(value);
                                        } else {
                                            String throwRef;
                                            String throwMethod;
                                            int index;
                                            if ("onreturn".equals(property)) {
                                                index = value.lastIndexOf(".");
                                                throwRef = value.substring(0, index);
                                                throwMethod = value.substring(index + 1);
                                                reference = new RuntimeBeanReference(throwRef);
                                                beanDefinition.getPropertyValues().addPropertyValue("onreturnMethod", throwMethod);
                                            } else if ("onthrow".equals(property)) {
                                                index = value.lastIndexOf(".");
                                                throwRef = value.substring(0, index);
                                                throwMethod = value.substring(index + 1);
                                                reference = new RuntimeBeanReference(throwRef);
                                                beanDefinition.getPropertyValues().addPropertyValue("onthrowMethod", throwMethod);
                                            } else {
                                                if ("ref".equals(property) && parserContext.getRegistry().containsBeanDefinition(value)) {
                                                    BeanDefinition refBean = parserContext.getRegistry().getBeanDefinition(value);
                                                    if (!refBean.isSingleton()) {
                                                        throw new IllegalStateException("The exported service ref " + value + " must be singleton! Please set the " + value + " bean scope to singleton, eg: <bean id=\"" + value + "\" scope=\"singleton\" ...>");
                                                    }
                                                }

                                                reference = new RuntimeBeanReference(value);
                                            }
                                        }
                                    } else {
                                        if ("dubbo:provider".equals(element.getTagName())) {
                                            logger.warn("Recommended replace <dubbo:provider protocol=\"" + value + "\" ... /> to <dubbo:protocol name=\"" + value + "\" ... />");
                                        }

                                        ProtocolConfig protocol = new ProtocolConfig();
                                        protocol.setName(value);
                                        reference = protocol;
                                    }

                                    beanDefinition.getPropertyValues().addPropertyValue(property, reference);
                                }
                            }
                        }
                    }
                }
            }
        }

        NamedNodeMap attributes = element.getAttributes();
        len = attributes.getLength();

        for(i = 0; i < len; ++i) {
            Node node = attributes.item(i);
            name = node.getLocalName();
            if (!props.contains(name)) {
                if (parameters == null) {
                    parameters = new ManagedMap();
                }

                String value = node.getNodeValue();
                parameters.put(name, new TypedStringValue(value, String.class));
            }
        }

        if (parameters != null) {
            beanDefinition.getPropertyValues().addPropertyValue("parameters", parameters);
        }

        return beanDefinition;
    }
```

这里的处理逻辑比较长，首先做的就是创建一个RootBeanDefinition，然后将实例化时的参数Class放入到RootBeanDefinition中。同时设置LazyInit为false，false表示ioc初始化后立即调用getBean加载。

然后开始对标签进行解析设置各种配置的属性，然后将bean注册到IOC容器中。

也就是说这里会将dubbo的各种bean进行初始化并且直接调用getBean加载。



## 服务发布

而我们的服务发布配置是在Service标签中，传入的参数是ServiceBean.Class,所以这个bean会进行初始化及依赖注入。首先了解一下这个Bean。

```java
public class ServiceBean<T> extends ServiceConfig<T> implements InitializingBean, DisposableBean, ApplicationContextAware, ApplicationListener, BeanNameAware {
...
}
```

这个类实现了很多Spring的扩展接口，所以当Spring对这个容器做依赖注入的时候，会分别调用其对于的实现方法。根据bean的生命周期可以看到执行顺序。

* IOC初始化
  * 调用 ApplicationListener中的**onApplicationEvent** 方法
* 依赖注入
  * 首先会调用BeanNameAware接口的setBeanName方法
  * 然后调用ApplicationContextAware接口的setApplicationContext方法
  * 然后调用InitializingBean中的afterPropertiesSet方法
  * 销毁时调用DisposableBean中的destroy方法

其中在afterPropertiesSet方法中是主要路线。

```java
public void afterPropertiesSet() throws Exception {
        Map protocolConfigMap;
        if (this.getProvider() == null) {
            protocolConfigMap = this.applicationContext == null ? null : BeanFactoryUtils.beansOfTypeIncludingAncestors(this.applicationContext, ProviderConfig.class, false, false);
            if (protocolConfigMap != null && protocolConfigMap.size() > 0) {
                Map<String, ProtocolConfig> protocolConfigMap = this.applicationContext == null ? null : BeanFactoryUtils.beansOfTypeIncludingAncestors(this.applicationContext, ProtocolConfig.class, false, false);
                Iterator i$;
                ProviderConfig config;
                if ((protocolConfigMap == null || protocolConfigMap.size() == 0) && protocolConfigMap.size() > 1) {
                    List<ProviderConfig> providerConfigs = new ArrayList();
                    i$ = protocolConfigMap.values().iterator();

                    while(i$.hasNext()) {
                        config = (ProviderConfig)i$.next();
                        if (config.isDefault() != null && config.isDefault()) {
                            providerConfigs.add(config);
                        }
                    }

                    if (providerConfigs.size() > 0) {
                        this.setProviders(providerConfigs);
                    }
                } else {
                    ProviderConfig providerConfig = null;
                    i$ = protocolConfigMap.values().iterator();

                    label318:
                    while(true) {
                        do {
                            if (!i$.hasNext()) {
                                if (providerConfig != null) {
                                    this.setProvider(providerConfig);
                                }
                                break label318;
                            }

                            config = (ProviderConfig)i$.next();
                        } while(config.isDefault() != null && !config.isDefault());

                        if (providerConfig != null) {
                            throw new IllegalStateException("Duplicate provider configs: " + providerConfig + " and " + config);
                        }

                        providerConfig = config;
                    }
                }
            }
        }

        Iterator i$;
        if (this.getApplication() == null && (this.getProvider() == null || this.getProvider().getApplication() == null)) {
            protocolConfigMap = this.applicationContext == null ? null : BeanFactoryUtils.beansOfTypeIncludingAncestors(this.applicationContext, ApplicationConfig.class, false, false);
            if (protocolConfigMap != null && protocolConfigMap.size() > 0) {
                ApplicationConfig applicationConfig = null;
                i$ = protocolConfigMap.values().iterator();

                label291:
                while(true) {
                    ApplicationConfig config;
                    do {
                        if (!i$.hasNext()) {
                            if (applicationConfig != null) {
                                this.setApplication(applicationConfig);
                            }
                            break label291;
                        }

                        config = (ApplicationConfig)i$.next();
                    } while(config.isDefault() != null && !config.isDefault());

                    if (applicationConfig != null) {
                        throw new IllegalStateException("Duplicate application configs: " + applicationConfig + " and " + config);
                    }

                    applicationConfig = config;
                }
            }
        }

        if (this.getModule() == null && (this.getProvider() == null || this.getProvider().getModule() == null)) {
            protocolConfigMap = this.applicationContext == null ? null : BeanFactoryUtils.beansOfTypeIncludingAncestors(this.applicationContext, ModuleConfig.class, false, false);
            if (protocolConfigMap != null && protocolConfigMap.size() > 0) {
                ModuleConfig moduleConfig = null;
                i$ = protocolConfigMap.values().iterator();

                label270:
                while(true) {
                    ModuleConfig config;
                    do {
                        if (!i$.hasNext()) {
                            if (moduleConfig != null) {
                                this.setModule(moduleConfig);
                            }
                            break label270;
                        }

                        config = (ModuleConfig)i$.next();
                    } while(config.isDefault() != null && !config.isDefault());

                    if (moduleConfig != null) {
                        throw new IllegalStateException("Duplicate module configs: " + moduleConfig + " and " + config);
                    }

                    moduleConfig = config;
                }
            }
        }

        ArrayList protocolConfigs;
        if ((this.getRegistries() == null || this.getRegistries().size() == 0) && (this.getProvider() == null || this.getProvider().getRegistries() == null || this.getProvider().getRegistries().size() == 0) && (this.getApplication() == null || this.getApplication().getRegistries() == null || this.getApplication().getRegistries().size() == 0)) {
            protocolConfigMap = this.applicationContext == null ? null : BeanFactoryUtils.beansOfTypeIncludingAncestors(this.applicationContext, RegistryConfig.class, false, false);
            if (protocolConfigMap != null && protocolConfigMap.size() > 0) {
                protocolConfigs = new ArrayList();
                i$ = protocolConfigMap.values().iterator();

                label240:
                while(true) {
                    RegistryConfig config;
                    do {
                        if (!i$.hasNext()) {
                            if (protocolConfigs != null && protocolConfigs.size() > 0) {
                                super.setRegistries(protocolConfigs);
                            }
                            break label240;
                        }

                        config = (RegistryConfig)i$.next();
                    } while(config.isDefault() != null && !config.isDefault());

                    protocolConfigs.add(config);
                }
            }
        }

        if (this.getMonitor() == null && (this.getProvider() == null || this.getProvider().getMonitor() == null) && (this.getApplication() == null || this.getApplication().getMonitor() == null)) {
            protocolConfigMap = this.applicationContext == null ? null : BeanFactoryUtils.beansOfTypeIncludingAncestors(this.applicationContext, MonitorConfig.class, false, false);
            if (protocolConfigMap != null && protocolConfigMap.size() > 0) {
                MonitorConfig monitorConfig = null;
                i$ = protocolConfigMap.values().iterator();

                label215:
                while(true) {
                    MonitorConfig config;
                    do {
                        if (!i$.hasNext()) {
                            if (monitorConfig != null) {
                                this.setMonitor(monitorConfig);
                            }
                            break label215;
                        }

                        config = (MonitorConfig)i$.next();
                    } while(config.isDefault() != null && !config.isDefault());

                    if (monitorConfig != null) {
                        throw new IllegalStateException("Duplicate monitor configs: " + monitorConfig + " and " + config);
                    }

                    monitorConfig = config;
                }
            }
        }

        if ((this.getProtocols() == null || this.getProtocols().size() == 0) && (this.getProvider() == null || this.getProvider().getProtocols() == null || this.getProvider().getProtocols().size() == 0)) {
            protocolConfigMap = this.applicationContext == null ? null : BeanFactoryUtils.beansOfTypeIncludingAncestors(this.applicationContext, ProtocolConfig.class, false, false);
            if (protocolConfigMap != null && protocolConfigMap.size() > 0) {
                protocolConfigs = new ArrayList();
                i$ = protocolConfigMap.values().iterator();

                label190:
                while(true) {
                    ProtocolConfig config;
                    do {
                        if (!i$.hasNext()) {
                            if (protocolConfigs != null && protocolConfigs.size() > 0) {
                                super.setProtocols(protocolConfigs);
                            }
                            break label190;
                        }

                        config = (ProtocolConfig)i$.next();
                    } while(config.isDefault() != null && !config.isDefault());

                    protocolConfigs.add(config);
                }
            }
        }

        if ((this.getPath() == null || this.getPath().length() == 0) && this.beanName != null && this.beanName.length() > 0 && this.getInterface() != null && this.getInterface().length() > 0 && this.beanName.startsWith(this.getInterface())) {
            this.setPath(this.beanName);
        }

        if (!this.isDelay()) {
            this.export();
        }

    }
```

这个方法很长，但是大部分都是数据准备工作。

我们直接看最后面的发布服务的地方，export;

```java
  public synchronized void export() {
        if (provider != null) {
            if (export == null) {
                export = provider.getExport();
            }
            if (delay == null) {
                delay = provider.getDelay();
            }
        }
        if (export != null && ! export.booleanValue()) {
            return;
        }
        if (delay != null && delay > 0) {
            Thread thread = new Thread(new Runnable() {
                public void run() {
                    try {
                        Thread.sleep(delay);
                    } catch (Throwable e) {
                    }
                    doExport();
                }
            });
            thread.setDaemon(true);
            thread.setName("DelayExportServiceThread");
            thread.start();
        } else {
            doExport();
        }
    }
```

这个方法里如果设置了延时启动，会通过开启个线程然后sleep的方式来进行延时启动，启动服务调用doExport。

这里依然是一些资源初始化的内容，然后直接看调用的doExportUrls()方法。

```java
private void doExportUrls() {
        List<URL> registryURLs = loadRegistries(true);//是不是获得注册中心的配置
        for (ProtocolConfig protocolConfig : protocols) { //是不是支持多协议发布
            doExportUrlsFor1Protocol(protocolConfig, registryURLs);
        }
    }
```

这个方法中，首先调用loadRegistries获取注册中心的配置

```java
 protected List<URL> loadRegistries(boolean provider) {
        checkRegistry();
        List<URL> registryList = new ArrayList<URL>();
        if (registries != null && registries.size() > 0) {
            for (RegistryConfig config : registries) {
                String address = config.getAddress();
                if (address == null || address.length() == 0) {
                	address = Constants.ANYHOST_VALUE;
                }
                String sysaddress = System.getProperty("dubbo.registry.address");
                if (sysaddress != null && sysaddress.length() > 0) {
                    address = sysaddress;
                }
                if (address != null && address.length() > 0 
                        && ! RegistryConfig.NO_AVAILABLE.equalsIgnoreCase(address)) {
                    Map<String, String> map = new HashMap<String, String>();
                    appendParameters(map, application);
                    appendParameters(map, config);
                    map.put("path", RegistryService.class.getName());
                    map.put("dubbo", Version.getVersion());
                    map.put(Constants.TIMESTAMP_KEY, String.valueOf(System.currentTimeMillis()));
                    if (ConfigUtils.getPid() > 0) {
                        map.put(Constants.PID_KEY, String.valueOf(ConfigUtils.getPid()));
                    }
                    if (! map.containsKey("protocol")) {
                        if (ExtensionLoader.getExtensionLoader(RegistryFactory.class).hasExtension("remote")) {
                            map.put("protocol", "remote");
                        } else {
                            map.put("protocol", "dubbo");
                        }
                    }
                    List<URL> urls = UrlUtils.parseURLs(address, map);
                    for (URL url : urls) {
                        url = url.addParameter(Constants.REGISTRY_KEY, url.getProtocol());
                        url = url.setProtocol(Constants.REGISTRY_PROTOCOL);
                        if ((provider && url.getParameter(Constants.REGISTER_KEY, true))
                                || (! provider && url.getParameter(Constants.SUBSCRIBE_KEY, true))) {
                            registryList.add(url);
                        }
                    }
                }
            }
        }
        return registryList;
    }
```

这个方法应该就是获取注册中心的配置，然后会遍历配置的协议，通过doExportUrlsFor1Protocol调用，进行发布。

```java
private void doExportUrlsFor1Protocol(ProtocolConfig protocolConfig, List<URL> registryURLs) {
        String name = protocolConfig.getName();
        if (name == null || name.length() == 0) {
            name = "dubbo";
        }

        String host = protocolConfig.getHost();
        if (provider != null && (host == null || host.length() == 0)) {
            host = provider.getHost();
        }
        boolean anyhost = false;
        if (NetUtils.isInvalidLocalHost(host)) {
            anyhost = true;
            try {
                host = InetAddress.getLocalHost().getHostAddress();
            } catch (UnknownHostException e) {
                logger.warn(e.getMessage(), e);
            }
            if (NetUtils.isInvalidLocalHost(host)) {
                if (registryURLs != null && registryURLs.size() > 0) {
                    for (URL registryURL : registryURLs) {
                        try {
                            Socket socket = new Socket();
                            try {
                                SocketAddress addr = new InetSocketAddress(registryURL.getHost(), registryURL.getPort());
                                socket.connect(addr, 1000);
                                host = socket.getLocalAddress().getHostAddress();
                                break;
                            } finally {
                                try {
                                    socket.close();
                                } catch (Throwable e) {}
                            }
                        } catch (Exception e) {
                            logger.warn(e.getMessage(), e);
                        }
                    }
                }
                if (NetUtils.isInvalidLocalHost(host)) {
                    host = NetUtils.getLocalHost();
                }
            }
        }

        Integer port = protocolConfig.getPort();
        if (provider != null && (port == null || port == 0)) {
            port = provider.getPort();
        }
        final int defaultPort = ExtensionLoader.getExtensionLoader(Protocol.class).getExtension(name).getDefaultPort();
        if (port == null || port == 0) {
            port = defaultPort;
        }
        if (port == null || port <= 0) {
            port = getRandomPort(name);
            if (port == null || port < 0) {
                port = NetUtils.getAvailablePort(defaultPort);
                putRandomPort(name, port);
            }
            logger.warn("Use random available port(" + port + ") for protocol " + name);
        }

        Map<String, String> map = new HashMap<String, String>();
        if (anyhost) {
            map.put(Constants.ANYHOST_KEY, "true");
        }
        map.put(Constants.SIDE_KEY, Constants.PROVIDER_SIDE);
        map.put(Constants.DUBBO_VERSION_KEY, Version.getVersion());
        map.put(Constants.TIMESTAMP_KEY, String.valueOf(System.currentTimeMillis()));
        if (ConfigUtils.getPid() > 0) {
            map.put(Constants.PID_KEY, String.valueOf(ConfigUtils.getPid()));
        }
        appendParameters(map, application);
        appendParameters(map, module);
        appendParameters(map, provider, Constants.DEFAULT_KEY);
        appendParameters(map, protocolConfig);
        appendParameters(map, this);
        if (methods != null && methods.size() > 0) {
            for (MethodConfig method : methods) {
                appendParameters(map, method, method.getName());
                String retryKey = method.getName() + ".retry";
                if (map.containsKey(retryKey)) {
                    String retryValue = map.remove(retryKey);
                    if ("false".equals(retryValue)) {
                        map.put(method.getName() + ".retries", "0");
                    }
                }
                List<ArgumentConfig> arguments = method.getArguments();
                if (arguments != null && arguments.size() > 0) {
                    for (ArgumentConfig argument : arguments) {
                        //类型自动转换.
                        if(argument.getType() != null && argument.getType().length() >0){
                            Method[] methods = interfaceClass.getMethods();
                            //遍历所有方法
                            if(methods != null && methods.length > 0){
                                for (int i = 0; i < methods.length; i++) {
                                    String methodName = methods[i].getName();
                                    //匹配方法名称，获取方法签名.
                                    if(methodName.equals(method.getName())){
                                        Class<?>[] argtypes = methods[i].getParameterTypes();
                                        //一个方法中单个callback
                                        if (argument.getIndex() != -1 ){
                                            if (argtypes[argument.getIndex()].getName().equals(argument.getType())){
                                                appendParameters(map, argument, method.getName() + "." + argument.getIndex());
                                            }else {
                                                throw new IllegalArgumentException("argument config error : the index attribute and type attirbute not match :index :"+argument.getIndex() + ", type:" + argument.getType());
                                            }
                                        } else {
                                            //一个方法中多个callback
                                            for (int j = 0 ;j<argtypes.length ;j++) {
                                                Class<?> argclazz = argtypes[j];
                                                if (argclazz.getName().equals(argument.getType())){
                                                    appendParameters(map, argument, method.getName() + "." + j);
                                                    if (argument.getIndex() != -1 && argument.getIndex() != j){
                                                        throw new IllegalArgumentException("argument config error : the index attribute and type attirbute not match :index :"+argument.getIndex() + ", type:" + argument.getType());
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }else if(argument.getIndex() != -1){
                            appendParameters(map, argument, method.getName() + "." + argument.getIndex());
                        }else {
                            throw new IllegalArgumentException("argument config must set index or type attribute.eg: <dubbo:argument index='0' .../> or <dubbo:argument type=xxx .../>");
                        }

                    }
                }
            } // end of methods for
        }

        if (ProtocolUtils.isGeneric(generic)) {
            map.put("generic", generic);
            map.put("methods", Constants.ANY_VALUE);
        } else {
            String revision = Version.getVersion(interfaceClass, version);
            if (revision != null && revision.length() > 0) {
                map.put("revision", revision);
            }

            String[] methods = Wrapper.getWrapper(interfaceClass).getMethodNames();
            if(methods.length == 0) {
                logger.warn("NO method found in service interface " + interfaceClass.getName());
                map.put("methods", Constants.ANY_VALUE);
            }
            else {
                map.put("methods", StringUtils.join(new HashSet<String>(Arrays.asList(methods)), ","));
            }
        }
        if (! ConfigUtils.isEmpty(token)) {
            if (ConfigUtils.isDefault(token)) {
                map.put("token", UUID.randomUUID().toString());
            } else {
                map.put("token", token);
            }
        }
        //如果scope没有配置或者配置local、remote，dubbo会将服务export到本地，
        // 意思就是：将服务以injvm协议export出去，如果是同一个jvm的应用可以直接通过jvm发起调用，
        // 而不需要通过网络发起远程调用。
        if ("injvm".equals(protocolConfig.getName())) {
            protocolConfig.setRegister(false);
            map.put("notify", "false");
        }
        // 导出服务
        String contextPath = protocolConfig.getContextpath();
        if ((contextPath == null || contextPath.length() == 0) && provider != null) {
            contextPath = provider.getContextpath();
        }
        URL url = new URL(name, host, port, (contextPath == null || contextPath.length() == 0 ? "" : contextPath + "/") + path, map);

        if (ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class)
                .hasExtension(url.getProtocol())) {
            url = ExtensionLoader.getExtensionLoader(ConfiguratorFactory.class)
                    .getExtension(url.getProtocol()).getConfigurator(url).configure(url);
        }

        String scope = url.getParameter(Constants.SCOPE_KEY);
        //配置为none不暴露
        if (! Constants.SCOPE_NONE.toString().equalsIgnoreCase(scope)) {

            //配置不是remote的情况下做本地暴露 (配置为remote，则表示只暴露远程服务)
            //发布服务
            if (!Constants.SCOPE_REMOTE.toString().equalsIgnoreCase(scope)) {
                exportLocal(url);
            }
            //如果配置不是local则暴露为远程服务.(配置为local，则表示只暴露本地服务)
            //注册服务
            if (! Constants.SCOPE_LOCAL.toString().equalsIgnoreCase(scope) ){
                if (logger.isInfoEnabled()) {
                    logger.info("Export dubbo service " + interfaceClass.getName() + " to url " + url);
                }
                if (registryURLs != null && registryURLs.size() > 0
                        && url.getParameter("register", true)) {
                    for (URL registryURL : registryURLs) {//
                        url = url.addParameterIfAbsent("dynamic", registryURL.getParameter("dynamic"));
                        URL monitorUrl = loadMonitor(registryURL);
                        if (monitorUrl != null) {
                            url = url.addParameterAndEncoded(Constants.MONITOR_KEY, monitorUrl.toFullString());
                        }
                        if (logger.isInfoEnabled()) {
                            logger.info("Register dubbo service " + interfaceClass.getName() + " url " + url + " to registry " + registryURL);
                        }
                        //通过proxyFactory来获取Invoker对象
                        Invoker<?> invoker = proxyFactory.getInvoker(ref, (Class) interfaceClass, registryURL.addParameterAndEncoded(Constants.EXPORT_KEY, url.toFullString()));
                        //注册服务
                        Exporter<?> exporter = protocol.export(invoker);
                        //将exporter添加到list中
                        exporters.add(exporter);
                    }
                } else {
                    Invoker<?> invoker = proxyFactory.getInvoker(ref, (Class) interfaceClass, url);
                    Exporter<?> exporter = protocol.export(invoker);
                    exporters.add(exporter);
                }
            }
        }
        this.urls.add(url);
    }
```

这个方法很大，首先获取协议名，然后获取协议id地址，端口（如果未配置端口，则会使用默认端口，如果也没有或者配置的为负数，则会随机产生端口），然后设置一个map集合，存放各种数据。

然后将所有内容封装成一个URL，然后判断协议名是否是本地服务，是则发布本地服务。否则如果是远程服务，先获取注册中心内容，遍历注册中心，进行属性赋值，然后会执行很重要的操作

```java
   //通过proxyFactory来获取Invoker对象
Invoker<?> invoker = proxyFactory.getInvoker(ref, (Class) interfaceClass, registryURL.addParameterAndEncoded(Constants.EXPORT_KEY, url.toFullString()));
//注册服务
Exporter<?> exporter = protocol.export(invoker);
//将exporter添加到list中
exporters.add(exporter);
```

创建代理对象，及发布服务。

首先了解创建代理内容

```java

```



继续上面分析，会进入到export服务发布方法，这里根据SPI机制会进入到wapper-----》dubboProtocol

```java
public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
        URL url = invoker.getUrl();
        
        // export service.
        String key = serviceKey(url);
        DubboExporter<T> exporter = new DubboExporter<T>(invoker, key, exporterMap);
        exporterMap.put(key, exporter);

        //export an stub service for dispaching event
        Boolean isStubSupportEvent = url.getParameter(Constants.STUB_EVENT_KEY,Constants.DEFAULT_STUB_EVENT);
        Boolean isCallbackservice = url.getParameter(Constants.IS_CALLBACK_SERVICE, false);
        if (isStubSupportEvent && !isCallbackservice){
            String stubServiceMethods = url.getParameter(Constants.STUB_EVENT_METHODS_KEY);
            if (stubServiceMethods == null || stubServiceMethods.length() == 0 ){
                if (logger.isWarnEnabled()){
                    logger.warn(new IllegalStateException("consumer [" +url.getParameter(Constants.INTERFACE_KEY) +
                            "], has set stubproxy support event ,but no stub methods founded."));
                }
            } else {
                stubServiceMethodsMap.put(url.getServiceKey(), stubServiceMethods);
            }
        }

        openServer(url);
        
        return exporter;
    }
```

这里会将要发布的服务封装一个`DubboExporter`对象，然后放入exporterMap变量中。如果设置了事假或callback等会做对应参数赋值。然后调用主要的方法openServer准备发布服务

```java
private void openServer(URL url) {
        String key = url.getAddress();
        boolean isServer = url.getParameter("isserver", true);
        if (isServer) {
            ExchangeServer server = (ExchangeServer)this.serverMap.get(key);
            if (server == null) {
                this.serverMap.put(key, this.createServer(url));
            } else {
                server.reset(url);
            }
        }

    }
```

dubbo大部分操作都是基于URL驱动的，所以这里获取url中的地址。

然后依然先从变量serverMap中是否有这个地址的服务列表，如果没有则调用createServer创建服务，否则会调用server.reset(url);进行重新启动。

首先看createServer方法

```java
private ExchangeServer createServer(URL url) {
        url = url.addParameterIfAbsent("channel.readonly.sent", Boolean.TRUE.toString());
        url = url.addParameterIfAbsent("heartbeat", String.valueOf(60000));
        String str = url.getParameter("server", "netty");
        if (str != null && str.length() > 0 && !ExtensionLoader.getExtensionLoader(Transporter.class).hasExtension(str)) {
            throw new RpcException("Unsupported server type: " + str + ", url: " + url);
        } else {
            url = url.addParameter("codec", Version.isCompatibleVersion() ? "dubbo1compatible" : "dubbo");

            ExchangeServer server;
            try {
                server = Exchangers.bind(url, this.requestHandler);
            } catch (RemotingException var5) {
                throw new RpcException("Fail to start server(url: " + url + ") " + var5.getMessage(), var5);
            }

            str = url.getParameter("client");
            if (str != null && str.length() > 0) {
                Set<String> supportedTypes = ExtensionLoader.getExtensionLoader(Transporter.class).getSupportedExtensions();
                if (!supportedTypes.contains(str)) {
                    throw new RpcException("Unsupported client type: " + str);
                }
            }

            return server;
        }
    }
```

方法中还是先根据URL信息进行一些处理，然后调用Exchangers.bind(url, this.requestHandler);绑定服务

```java
  public static ExchangeServer bind(URL url, ExchangeHandler handler) throws RemotingException {
        if (url == null) {
            throw new IllegalArgumentException("url == null");
        } else if (handler == null) {
            throw new IllegalArgumentException("handler == null");
        } else {
            url = url.addParameterIfAbsent("codec", "exchange");
            return getExchanger(url).bind(url, handler);
        }
    }
。。。
public ExchangeServer bind(URL url, ExchangeHandler handler) throws RemotingException {
        return new HeaderExchangeServer(Transporters.bind(url, new ChannelHandler[]{new DecodeHandler(new HeaderExchangeHandler(handler))}));
    }
```

可以看到这里返回一个HeaderExchangeServer对象，所以上面reset中调用的也是HeaderExchangeServer这个中的方法。

实例HeaderExchangeServer对象时，参数中会调用Transporters.bind操作。

```java
public static Server bind(URL url, ChannelHandler... handlers) throws RemotingException {
        if (url == null) {
            throw new IllegalArgumentException("url == null");
        } else if (handlers != null && handlers.length != 0) {
            Object handler;
            if (handlers.length == 1) {
                handler = handlers[0];
            } else {
                handler = new ChannelHandlerDispatcher(handlers);
            }

            return getTransporter().bind(url, (ChannelHandler)handler);
        } else {
            throw new IllegalArgumentException("handlers == null");
        }
    }
```

这其中会调用getTransporter().bind方法进行服务发布。这里getTransporter()返回的是什么呢?

```java
public static Transporter getTransporter() {
        return (Transporter)ExtensionLoader.getExtensionLoader(Transporter.class).getAdaptiveExtension();
    }
```

一样使用了SPI机制，默认使用netty的对应实现netty=com.alibaba.dubbo.remoting.transport.netty.NettyTransporter

```java
@SPI("netty")public interface Transporter {}
```

所以这里会进入NettyTransporter内的实现。

```java
public Server bind(URL url, ChannelHandler listener) throws RemotingException {
        return new NettyServer(url, listener);
    }
```

最后进入到了netty框架中的处理。



继续回到上面方法看看reset的处理

```java
public void reset(URL url) {
        this.server.reset(url);

        try {
            if (url.hasParameter("heartbeat") || url.hasParameter("heartbeat.timeout")) {
                int h = url.getParameter("heartbeat", this.heartbeat);
                int t = url.getParameter("heartbeat.timeout", h * 3);
                if (t < h * 2) {
                    throw new IllegalStateException("heartbeatTimeout < heartbeatInterval * 2");
                }

                if (h != this.heartbeat || t != this.heartbeatTimeout) {
                    this.heartbeat = h;
                    this.heartbeatTimeout = t;
                    this.startHeatbeatTimer();
                }
            }
        } catch (Throwable var4) {
            this.logger.error(var4.getMessage(), var4);
        }

    }
```

这里的server就是创建的nettyserver,但是方法中未写reset方法，所以会调父类中。

```java
 public void reset(URL url) {
        if (url != null) {
            int t;
            try {
                if (url.hasParameter("accepts")) {
                    t = url.getParameter("accepts", 0);
                    if (t > 0) {
                        this.accepts = t;
                    }
                }
            } catch (Throwable var7) {
                logger.error(var7.getMessage(), var7);
            }

            try {
                if (url.hasParameter("idle.timeout")) {
                    t = url.getParameter("idle.timeout", 0);
                    if (t > 0) {
                        this.idleTimeout = t;
                    }
                }
            } catch (Throwable var6) {
                logger.error(var6.getMessage(), var6);
            }

            try {
                if (url.hasParameter("threads") && this.executor instanceof ThreadPoolExecutor && !this.executor.isShutdown()) {
                    ThreadPoolExecutor threadPoolExecutor = (ThreadPoolExecutor)this.executor;
                    int threads = url.getParameter("threads", 0);
                    int max = threadPoolExecutor.getMaximumPoolSize();
                    int core = threadPoolExecutor.getCorePoolSize();
                    if (threads > 0 && (threads != max || threads != core)) {
                        if (threads < core) {
                            threadPoolExecutor.setCorePoolSize(threads);
                            if (core == max) {
                                threadPoolExecutor.setMaximumPoolSize(threads);
                            }
                        } else {
                            threadPoolExecutor.setMaximumPoolSize(threads);
                            if (core == max) {
                                threadPoolExecutor.setCorePoolSize(threads);
                            }
                        }
                    }
                }
            } catch (Throwable var8) {
                logger.error(var8.getMessage(), var8);
            }

            super.setUrl(this.getUrl().addParameters(url.getParameters()));
        }
    }

```

这里只是做了 线程池的数量做了调整。

