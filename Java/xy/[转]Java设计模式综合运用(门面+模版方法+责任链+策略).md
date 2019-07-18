> 引言：很久没有更新了，主要是工作忙。最近，工作中一个子系统升级，把之前不易扩展的缺点给改进了一下，主要是运用了几个设计模式进行稍微改造了一下。
> 本文也同步发布至简书，地址： [https://www.jianshu.com/p/962...](https://www.jianshu.com/p/96218890852e)

# 1.项目背景

在公司的一个实际项目中，需要做一个第三方公司（以下简称GMG）的系统集成工作，把该公司的一些订单数据集成到自己公司平台下，各个订单具有一些共性，但是也有其特有的特征。 经过设计，目前我把订单分为POLICY和BOB类型（暂且这么说吧，反正就是一种订单类型，大家参照着看就OK）。

在订单数据集成到公司平台前，需要对订单数据进行一些必要的业务逻辑校验操作，并且每个订单都有自己的校验逻辑（包含公共的校验逻辑）。 本节介绍的便是整个订单集成系统中的校验逻辑在综合利用设计模式的基础上进行架构设计。

# 2.校验逻辑

本校验逻辑主要分为四个部分：

1. 校验文件名称（RequestValidator.validateFileInfo）
2. 校验文件内容中的概要部分（RequestValidator.validateSummary）
3. 校验文件内容中的列名称（RequestValidator.validateHeaders）
4. 校验文件内容中的明细（RequestValidator.validateDetails）

其实上面的RequestValidator的实现逻辑最后都是委托给RequestValidationFacade这个门面类进行相应的校验操作。

# 3.实现细节

## 3.1 domain介绍

主要分为RequestFile和RequestDetail两个domain,RequestFile接收泛型的类型（即RequestFile）, 使得其子类能够自动识别相应的RequestDetail的子类。RequestFile为抽象类，定义了以下抽象方法，由子类实现：

```
//由子类实现具体的获取文件明细内容
public abstract List<T> getRequestDetails();
//由子类实现具体的获取workflow的值
public abstract WorkflowEnum getProcessWorkFlow();
//由子类实现文件列字段名列表
public abstract String[] getDetailHeaders();
```

RequestDetail及其子类就是workflow对应文件的明细内容。

## 3.2 WorkflowEnum枚举策略

本例中如下规定：

1. workflow为WorkflowEnum.POLICY对应文件名为：csync_policy_yyyyMMdd_HHmmss_count.txt
2. workflow为WorkflowEnum.BOB对应文件名为：csync_bob_integration_yyyyMMdd_HHmmss_count.txt

以上校验逻辑在AbstractRequestValidation类相应的子类中实现（validateFileName方法），其实这个枚举贯穿整个校验组件，它就是一个针对每个业务流程定义的一个枚举策略。

## 3.3 涉及到的设计模式实现思路

### 3.3.1 门面模式

在客户端调用程序中，采用门面模式进行统一的入口（门面模式讲究的是脱离具体的业务逻辑代码）。门面模式封装的结果就是避免高层模块深入子系统内部，同时提供系统的高内聚、低耦合的特性。

此案例中，门面类为RequestValidationFacade，然后各个门面方法的参数均为抽象类RequestFile，通过RequestFile->getProcessWorkFlow()决定调用AbstractRequestValidation中的哪个子类。 AbstractRequestValidation类构造方法中定义了如下逻辑：

```
requestValidationHandlerMap.put(this.accessWorkflow(),this.accessBeanName());
```

把子类中Spring自动注入的实体bean缓存到requestValidationHandlerMap中，key即为WorkflowEnum枚举值，value为spring bean name, 然后在门面类中可以通过对应的枚举值取得BeanName，进而得到AbstractRequestValidation相应的子类对象，进行相应的校验操作。

注：这边动态调用到AbstractRequestValidation相应的子类对象，其实也是隐藏着【策略模式】的影子。

类图如下：
![门面模式](https://segmentfault.com/img/remote/1460000019219565)

### 3.3.2 模版方法模式

在具体的校验逻辑中，用到核心设计模式便是模版方法模式，AbstractRequestValidation抽象类中定义了以下抽象方法：

```
 /**
     * validate the file details
     * @param errMsg
     * @param requestFile
     * @return
     */
    protected abstract StringBuilder validateFileDetails(StringBuilder errMsg,RequestFile requestFile);

    /**
     * validate the file name
     * @param fileName
     * @return
     */
    protected abstract String validateFileName(String fileName);

    /**
     * return the current CSYNC_UPDATE_WORKFLOW.UPDATE_WORKFLOW_ID
     * @return
     */
    protected abstract WorkflowEnum accessWorkflow();

    /**
     * return the current file name's format ,such as: csync_policy_yyyyMMdd_HHmmss_count.txt
     * @return
     */
    protected abstract String accessFileNameFormat();

    /**
     * return the subclass's spring bean name
     * @return
     */
    protected abstract String accessBeanName();
```

以上抽象方法就类似我们常说的钩子函数，由子类实现即可。类图如下图所示：
![模版方法模式](https://segmentfault.com/img/remote/1460000019219566)

### 3.3.3 责任链模式

在AbstractRequestValidation抽象类中有个抽象方法validateFileDetails，校验的是文件的明细内容中的相应业务规则，此为核心校验， 较为复杂，而且针对每个业务流程，其校验逻辑相差较大，在此处，利用了责任链模式进行处理。

Validator为校验器的父接口，包含两个泛型参数(即：<R extends RequestDetail,F extends RequestFile>)，其实现类可以方便的转换需要校验的文件明细。

```
String doValidate(R detail, F file, ValidatorChain chain) throws BusinessValidationException;
```

该方法含有一个ValidatorChain参数，就自然而然的为该校验器形成一个链条提供便利条件。

ValidatorChain为校验器链，含有两个接口方法：

```
String doValidate(T requestDetail, F requestFile) throws BusinessValidationException;

ValidatorChain addValidator(Validator validator, WorkflowEnum workflowId);
```

该处有一个addValidator方法，为ValidatorChain对象添加校验器的方法，返回本身。对应于每个业务流程需要哪些校验器就在此实现即可（即AbstractRequestValidation的子类方法validateFileDetails）。

类图如下图所示：
![责任链模式1-validator chain](https://segmentfault.com/img/remote/1460000019219567)
![责任链模式2-部分validator](https://segmentfault.com/img/remote/1460000019219568)

### 3.3.4 策略模式

如果单单从上面的校验器实现上来看，如果需要增加一个校验器，就需要在AbstractRequestValidation的子类方法validateFileDetails中添加，然后进行相应的校验操作。这样就会非常的麻烦，没有做到真正的解耦。 此时，策略模式就发挥到了可以动态选择某种校验策略的作用（Validator的实现类就是一个具体的校验策略）。

AbstractValidatorHandler抽象类持有FileDetailValidatorChain类的对象，并且实现累Spring的一个接口ApplicationListener（是为了Spring容器启动完成的时候自动把相应的校验器加入到校验器链中）。 核心就是WorkflowEnum这个策略枚举的作用，在子类可以动态的取得相应的校验器对象。

根据子类提供需要的校验器所在的包名列表和不需要的校验器列表，动态配置出需要的校验器链表。核心实现逻辑如下：

```
private void addValidators() {
    List<Class<? extends Validator>> validators = getValidators();

    validators.forEach((validator) -> {
        String simpleName = validator.getSimpleName();
        String beanName = simpleName.substring(0, 1).toLowerCase() + simpleName.substring(1);

        LOGGER.info("Added validator:{},spring bean name is:{}",simpleName,beanName);

        Validator validatorInstance = ApplicationUtil.getApplicationContext().getBean(beanName,validator);

        fileDetailValidatorChain.addValidator(validatorInstance,getWorkflowId());

    });
}
```

具体实现可以参考github代码即可。

该类含有以下几个抽象方法：

```
protected abstract WorkflowEnum getWorkflowId();
/**
 * the package need to be added the validators
 * @return
 */
protected abstract Set<String> getBasePackages();

/**
 * the classes need to be excluded
 * @return
 */
protected abstract Set<Class> excludeClasses();
```

**事例代码地址**：[https://github.com/landy8530/...](https://github.com/landy8530/DesignPatterns)