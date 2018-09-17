下面解析buildInvokerChain方法，这个是构建了一个过滤器链，从下面filters获取了所有的活动的扩展点，有必要去展示一下

```
echo=com.alibaba.dubbo.rpc.filter.EchoFilter
generic=com.alibaba.dubbo.rpc.filter.GenericFilter
genericimpl=com.alibaba.dubbo.rpc.filter.GenericImplFilter
token=com.alibaba.dubbo.rpc.filter.TokenFilter
accesslog=com.alibaba.dubbo.rpc.filter.AccessLogFilter
activelimit=com.alibaba.dubbo.rpc.filter.ActiveLimitFilter
classloader=com.alibaba.dubbo.rpc.filter.ClassLoaderFilter
context=com.alibaba.dubbo.rpc.filter.ContextFilter
consumercontext=com.alibaba.dubbo.rpc.filter.ConsumerContextFilter
exception=com.alibaba.dubbo.rpc.filter.ExceptionFilter
executelimit=com.alibaba.dubbo.rpc.filter.ExecuteLimitFilter
deprecated=com.alibaba.dubbo.rpc.filter.DeprecatedFilter
compatible=com.alibaba.dubbo.rpc.filter.CompatibleFilter
timeout=com.alibaba.dubbo.rpc.filter.TimeoutFilter
```

这是所有的过滤器，在下面的代码中将这些过滤器封装成链的形式，这就是典型的链式模式，在每一个环节都处理与它相关的功能，这样做的好处就是单一职责和流水线作业的标准化，获取执行链之后，然后继续调用，这时候protocol就是ProtocolListenerWrapper，如果不明白看SPI那块。

```java
List<Filter> filters = ExtensionLoader.getExtensionLoader(Filter.class).getActivateExtension(invoker.getUrl(), key, group);
if (filters.size() > 0) {
    for (int i = filters.size() - 1; i >= 0; i --) {
        final Filter filter = filters.get(i);
        final Invoker<T> next = last;
        last = new Invoker<T>() {

            public Class<T> getInterface() {
                return invoker.getInterface();
            }

            public URL getUrl() {
                return invoker.getUrl();
            }

            public boolean isAvailable() {
                return invoker.isAvailable();
            }

            public Result invoke(Invocation invocation) throws RpcException {
                return filter.invoke(next, invocation);
            }

            public void destroy() {
                invoker.destroy();
            }

            @Override
            public String toString() {
                return invoker.toString();
            }
        };
```

这时候开始执行ProtocolListenerWrapper类中export方法，，这时候会构建一个ListenerExporterWrapper对象，其中传递两个参数，第一个是protocol，现在它是dubboProtocol对象，那么会接着执行它的export

```java
if (Constants.REGISTRY_PROTOCOL.equals(invoker.getUrl().getProtocol())) {
    return protocol.export(invoker);
}
return new ListenerExporterWrapper<T>(protocol.export(invoker),  // DubboProtocol
        Collections.unmodifiableList(ExtensionLoader.getExtensionLoader(ExporterListener.class)
                .getActivateExtension(invoker.getUrl(), Constants.EXPORTER_LISTENER_KEY)));
```

下面看一下DubboProtocol类中export是怎么写的，终于到了dubbo，我来了，哈哈，这里构建了一个DubboExporter对象，将invoker等进一步封装，然后返回；在这里通过调用openServer方法完成对netty进行发布服务，并且开启心跳监测

```java
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
```

下面看看openServer方法是如何实现的，在这里获取url地址，然后进行发布，具体走createServer方法，那么我们一同看看究竟

```java
// find server.
String key = url.getAddress();
//client 也可以暴露一个只有server可以调用的服务。
boolean isServer = url.getParameter(Constants.IS_SERVER_KEY,true);
if (isServer) {
   ExchangeServer server = serverMap.get(key);
   if (server == null) {
      serverMap.put(key, createServer(url));
   } else {
      //server支持reset,配合override功能使用
      server.reset(url);
   }
}
```

看看createServer方法是如何实现的，在这里加入参数设置，继续通过Exchangers.bind(url, requestHandler);去完成发布之路

```java
//默认开启server关闭时发送readonly事件
url = url.addParameterIfAbsent(Constants.CHANNEL_READONLYEVENT_SENT_KEY, Boolean.TRUE.toString());
//默认开启heartbeat
url = url.addParameterIfAbsent(Constants.HEARTBEAT_KEY, String.valueOf(Constants.DEFAULT_HEARTBEAT));
String str = url.getParameter(Constants.SERVER_KEY, Constants.DEFAULT_REMOTING_SERVER);

if (str != null && str.length() > 0 && ! ExtensionLoader.getExtensionLoader(Transporter.class).hasExtension(str))
    throw new RpcException("Unsupported server type: " + str + ", url: " + url);

url = url.addParameter(Constants.CODEC_KEY, Version.isCompatibleVersion() ? COMPATIBLE_CODEC_NAME : DubboCodec.NAME);
ExchangeServer server;
try {
    //发布服务
    server = Exchangers.bind(url, requestHandler);
} catch (RemotingException e) {
    throw new RpcException("Fail to start server(url: " + url + ") " + e.getMessage(), e);
}
str = url.getParameter(Constants.CLIENT_KEY);
if (str != null && str.length() > 0) {
    Set<String> supportedTypes = ExtensionLoader.getExtensionLoader(Transporter.class).getSupportedExtensions();
    if (!supportedTypes.contains(str)) {
        throw new RpcException("Unsupported client type: " + str);
    }
}
return server;
```



继续跟下bind方法代码，在这里又调用了一个扩展点方法getExchanger，bind方法是哪个对象执行的要先跟一下方法

```java
if (url == null) {
    throw new IllegalArgumentException("url == null");
}
if (handler == null) {
    throw new IllegalArgumentException("handler == null");
}
url = url.addParameterIfAbsent(Constants.CODEC_KEY, "exchange");
return getExchanger(url).bind(url, handler);
```

getExchanger方法里面，首先获取了一个type，这个type的值是header，取得默认的，继续跟进，慢慢清晰起来了

```java
String type = url.getParameter(Constants.EXCHANGER_KEY, Constants.DEFAULT_EXCHANGER);
return getExchanger(type);
```

getExchanger方法是一个扩展点，最终返回的对象是HeaderExchanger，这个还是SPI的范畴，不熟悉的话，移步SPI学习，至此确认了是执行HeaderExchanger的bind方法，那么书接上文，继续跟进吧

```java
ExtensionLoader.getExtensionLoader(Exchanger.class).getExtension(type);
```

bind方法里是这样实现的，构建了一个新的HeaderExchangeServer对象，并传递server对象，也就是具体的服务对象使用的mina或者netty服务器，解析一下 里面方法

```java
return new HeaderExchangeServer(Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler))));
```

这句代码里执行了很多东西，首先handler被两个对象进行封装，一个是解码相关，另一个是处理接收的请求，下面看下bind方法是怎么实现的

```java
Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler)))
```

继续跟进bind方法，在这里面进行一些基础判空判断，并且进行传递多个handler的时候用ChannelHandlerDispatcher（ps这个是处理器适配器）进行包装，我们发现又一个getTransporter方法。这个又是一个扩展点适配器，还是SPI，此处就不在重复讲解是怎么获取该扩展点的，直接说结果是NettyTransport,跟了这么久终于见到真身了，使用netty进行服务发布，然后最终调用的是NettyTransport的bind方法，继续跟进

```java
if (url == null) {
    throw new IllegalArgumentException("url == null");
}
if (handlers == null || handlers.length == 0) {
    throw new IllegalArgumentException("handlers == null");
}
ChannelHandler handler;
if (handlers.length == 1) {
    handler = handlers[0];
} else {
    handler = new ChannelHandlerDispatcher(handlers);
}
return getTransporter().bind(url, handler);
```

bind方法中 构建了一个netty的服务端，到这里启动了netty服务并且设置了监听，在往下就是关于netty的操作，这里就不展开了，构建好了server就放进缓存里，下次就不用再创建了，直接使用。

```java
return new NettyServer(url, listener);
```



### 客户端订阅服务

