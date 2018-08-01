package org.springframework.beans.factory.support;

import org.springframework.beans.factory.BeanDefinition;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class DefaultListableBeanFactory extends AbstractBeanFactory{

    private final Map<String,BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<>(256);


    public void  registerBeanDefinition(BeanDefinition beanDefinition){
        this.beanDefinitionMap.put(beanDefinition.getBeanClassName(), beanDefinition);
    }

    public BeanDefinition getBeanDefinition(String beanName){
        return this.beanDefinitionMap.get(beanName);
    }
}
