# FactoryBean

## 说明

一般情况下，Spring是通过反射机制利用Bean的Class属性知道实现类来实例化Bean。但是在某些情况下，实例Bean的过程比较复杂，需要Bean提供大量的配置信息，所以Spring为此提供了一个工厂类接口`FactoryBean`，可以通过实现该接口定制实例化Bean的逻辑。

```java
public interface FactoryBean<T> {
	@Nullable
	T getObject() throws Exception;
	@Nullable
	Class<?> getObjectType();
    
	default boolean isSingleton() {
		return true;
	}

```

当配置文件中`<bean>`的class属性配置的实现类是`FactoryBean`时，通过`getBean()`方法返回的不是`FactoryBean`本身，而是`FactoryBean#getObject()`方法所返回的对象，相当于`FactoryBean#getObject()`代理了`getBean`方法。



举个例子：

如果传统方式  定义个Car的类

```java
public class Car{
    private int maxSpeed;
    private String brand;
    private double price;
}

```

如果使用`FactoryBean`的方式

```java
public class CarFactoryBean implements FactoryBean<Car> {
    private String carInfo;
	@Override
	public Car getObject() throws Exception {
	    Car car = new Car();
        String [] infos = carinfo.split(",");
        car.setBrand(infos[0]);
        car.setMaxSpeed(Integer.valueOf(infos[1]));
        car.setPrice(Double.valueOf(infos[2]));
		return car;
	}
	@Override
	public Class<?> getObjectType() {
		// TODO Auto-generated method stub
		return Car.class;
	}
	@Override
	public boolean isSingleton() {
		// TODO Auto-generated method stub
		return false;
	}
    public String getCarInfo(){
        return this.catInfo;
    }
    public void setCarInfo(String carInfo){
        this.carInfo = carInfo;
    }
 
}
```

配合的XML中配置

```xml
<bean id="car" class="com.CarFactoryBean" carInfo="超级，300,2000"></bean>
```

当调用`getBean("car")`时，发现`CarFactoryBean`实现了`FactoryBean`的接口，这是Spring容器就调用接口方法`CarFactoryBean#getObject()`方法返回。如果希望获取`CarFactoryBean`的实例，则需要再调用`getBean(BeanName)`方法时将BeanName前加上`&`前缀，例如`getBean("&car")`;

## 源码实现

具体实现逻辑可以在`AbstractBeanFactory`中的`getBean`方法中进入到`doGetBean`。其中有一步处理`getObjectForBeanInstance`。

```java
protected Object getObjectForBeanInstance(
			Object beanInstance, String name, String beanName, @Nullable RootBeanDefinition mbd) {

		// Don't let calling code try to dereference the factory if the bean isn't a factory.
    //容器已经得到了 Bean 实例对象，这个实例对象可能是一个普通的 Bean，
	//也可能是一个工厂 Bean，如果是一个工厂 Bean，则使用它创建一个 Bean 实例对象，
	//如果调用本身就想获得一个容器的引用，则指定返回这个工厂 Bean 实例对象
	//如果指定的名称是容器的解引用(dereference，即是对象本身而非内存地址)，
	//且 Bean 实例也不是创建 Bean 实例对象的工厂 Bean
		if (BeanFactoryUtils.isFactoryDereference(name)) {
			if (beanInstance instanceof NullBean) {
				return beanInstance;
			}
			if (!(beanInstance instanceof FactoryBean)) {
				throw new BeanIsNotAFactoryException(transformedBeanName(name), beanInstance.getClass());
			}
		}

		// Now we have the bean instance, which may be a normal bean or a FactoryBean.
		// If it's a FactoryBean, we use it to create a bean instance, unless the
		// caller actually wants a reference to the factory.
    	//如果 Bean 实例不是工厂 Bean，或者指定名称是容器的解引用，
		//调用者向获取对容器的引用，则直接返回当前的 Bean 实例
		if (!(beanInstance instanceof FactoryBean) || BeanFactoryUtils.isFactoryDereference(name)) {
			return beanInstance;
		}
		//处理指定名称不是容器的解引用，或者根据名称获取的 Bean 实例对象是一个工厂 Bean
		//使用工厂 Bean 创建一个 Bean 的实例对象
		Object object = null;
		if (mbd == null) {
            //从 Bean 工厂缓存中获取给定名称的 Bean 实例对象
			object = getCachedObjectForFactoryBean(beanName);
		}
    //让 Bean 工厂生产给定名称的 Bean 对象实例
		if (object == null) {
			// Return bean instance from factory.
            
			FactoryBean<?> factory = (FactoryBean<?>) beanInstance;
			// Caches object obtained from FactoryBean if it is a singleton.
            //如果从 Bean 工厂生产的 Bean 是单态模式的，则缓存
			if (mbd == null && containsBeanDefinition(beanName)) {
                //从容器中获取指定名称的 Bean 定义，如果继承基类，则合并基类相关属性
				mbd = getMergedLocalBeanDefinition(beanName);
			}
            //如果从容器得到 Bean 定义信息，并且 Bean 定义信息不是虚构的，
			//则让工厂 Bean 生产 Bean 实例对象
			boolean synthetic = (mbd != null && mbd.isSynthetic());
            //调用 FactoryBeanRegistrySupport 类的 getObjectFromFactoryBean 方法，
			//实现工厂 Bean 生产 Bean 对象实例的过程
			object = getObjectFromFactoryBean(factory, beanName, !synthetic);
		}
		return object;
	}
```

`Dereference`(解引用)：一个在 C/C++中应用比较多的术语，在 C++中，`*`是解引用符号，而`&`
是引用符号，解引用是指变量指向的是所引用对象的本身数据，而不是引用对象的内存地址。

工厂Bean生成Bean对象的过程通过`getObjectFromFactoryBean`方法进入。

```java
protected Object getObjectFromFactoryBean(FactoryBean<?> factory, String beanName, boolean shouldPostProcess) {
    //Bean 工厂是单态模式，并且 Bean 工厂缓存中存在指定名称的 Bean 实例对象
		if (factory.isSingleton() && containsSingleton(beanName)) {
			synchronized (getSingletonMutex()) {
                //直接从 Bean 工厂缓存中获取指定名称的 Bean 实例对象
				Object object = this.factoryBeanObjectCache.get(beanName);
                //Bean 工厂缓存中没有指定名称的实例对象，则生产该实例对象
				if (object == null) {
					object = doGetObjectFromFactoryBean(factory, beanName);
					// Only post-process and store if not put there already during getObject() call above
					// (e.g. because of circular reference processing triggered by custom getBean calls)
					Object alreadyThere = this.factoryBeanObjectCache.get(beanName);
					if (alreadyThere != null) {
						object = alreadyThere;
					}
					else {
						if (shouldPostProcess) {
							if (isSingletonCurrentlyInCreation(beanName)) {
								// Temporarily return non-post-processed object, not storing it yet..
								return object;
							}
							beforeSingletonCreation(beanName);
							try {
								object = postProcessObjectFromFactoryBean(object, beanName);
							}
							catch (Throwable ex) {
								throw new BeanCreationException(beanName,
										"Post-processing of FactoryBean's singleton object failed", ex);
							}
							finally {
								afterSingletonCreation(beanName);
							}
						}
						if (containsSingleton(beanName)) {
							this.factoryBeanObjectCache.put(beanName, object);
						}
					}
				}
				return object;
			}
		}
		else {
			Object object = doGetObjectFromFactoryBean(factory, beanName);
			if (shouldPostProcess) {
				try {
					object = postProcessObjectFromFactoryBean(object, beanName);
				}
				catch (Throwable ex) {
					throw new BeanCreationException(beanName, "Post-processing of FactoryBean's object failed", ex);
				}
			}
			return object;
		}
	}
```

通过`doGetObjectFromFactoryBean`看到具体处理

```java
private Object doGetObjectFromFactoryBean(final FactoryBean<?> factory, final String beanName)
			throws BeanCreationException {

		Object object;
		try {
			if (System.getSecurityManager() != null) {
				AccessControlContext acc = getAccessControlContext();
				try {
					object = AccessController.doPrivileged((PrivilegedExceptionAction<Object>) factory::getObject, acc);
				}
				catch (PrivilegedActionException pae) {
					throw pae.getException();
				}
			}
			else {
				object = factory.getObject();
			}
		}
		catch (FactoryBeanNotInitializedException ex) {
			throw new BeanCurrentlyInCreationException(beanName, ex.toString());
		}
		catch (Throwable ex) {
			throw new BeanCreationException(beanName, "FactoryBean threw exception on object creation", ex);
		}

		// Do not accept a null value for a FactoryBean that's not fully
		// initialized yet: Many FactoryBeans just return null then.
		if (object == null) {
			if (isSingletonCurrentlyInCreation(beanName)) {
				throw new BeanCurrentlyInCreationException(
						beanName, "FactoryBean which is currently in creation returned null from getObject");
			}
			object = new NullBean();
		}
		return object;
	}
```

在这里可以发现`object = factory.getObject();`,`BeanFactory`接口调用其实现类的`getObject`方法来创建bean

实例的对象。而`FactoryBean`的实现类有很多，`getObject`会根据不同的实现类根据不同的实现策略来具体提供。

