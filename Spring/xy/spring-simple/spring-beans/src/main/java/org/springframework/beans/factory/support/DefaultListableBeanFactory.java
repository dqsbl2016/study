package org.springframework.beans.factory.support;

import org.springframework.beans.factory.BeanDefinition;
import org.springframework.beans.factory.BeanWrapper;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class DefaultListableBeanFactory extends AbstractBeanFactory{

    private final Map<String,BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<>(256);

    private final Map<String,BeanWrapper> beanWrapperMap = new ConcurrentHashMap<>(256);


    public void  registerBeanDefinition(BeanDefinition beanDefinition){
        try {
            Class<?> clazz =  Class.forName(beanDefinition.getBeanClassName().toString());
            if(clazz.isInterface()){
                return;
            }
            this.beanDefinitionMap.put(beanDefinition.getFactoryBeanName(), beanDefinition);
//            Class<?>[]  interfaces =clazz.getInterfaces();
//            for (Class<?> c:interfaces ) {
//
//                this.beanDefinitionMap.put(c.getSimpleName(),)
//            }
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }

    }

    public BeanDefinition getBeanDefinition(String beanName){
        return this.beanDefinitionMap.get(beanName);
    }

    public void registerBeanWrapper(String name,BeanWrapper beanWrapper){
        this.beanWrapperMap.put(name,beanWrapper);
    }

    public Object getObject(String beanClassName){
        if(this.beanWrapperMap.containsKey(beanClassName)){
            return this.beanWrapperMap.get(beanClassName);
        }else{
            if(!this.beanDefinitionMap.containsKey(beanClassName)){
                GenericBeanDefinition beanDefinition = new GenericBeanDefinition();
                beanDefinition.setFactoryBeanName(beanClassName);
                beanDefinition.setBeanClassName(beanClassName);
                this.beanDefinitionMap.put(beanClassName,beanDefinition);
            }
            getBean(beanClassName);
            return this.beanWrapperMap.get(beanClassName).getWrappedInstance();

        }
    }
}
