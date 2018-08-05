package org.springframework.beans.factory.support;

import org.springframework.beans.factory.BeanDefinition;

public class AbstractBeanDefinition implements BeanDefinition {

    private Object beanClassName;

    private String scope = "";

    private boolean lazyInit = false;

    private String factoryBeanName;

    private boolean singleton;


    @Override
    public void setBeanClassName(Object beanClass) {
        this.beanClassName = beanClass;
    }

    @Override
    public Object getBeanClassName() {
        return this.beanClassName;
    }

    @Override
    public void setScope(String scope) {
        this.scope =scope;
    }

    @Override
    public String getScope() {
        return this.scope;
    }

    @Override
    public void setLazyInit(boolean lazyInit) {
        this.lazyInit = lazyInit;
    }

    @Override
    public boolean isLazyInit() {
        return this.lazyInit;
    }

    @Override
    public void setFactoryBeanName(String factoryBeanName) {
        this.factoryBeanName = factoryBeanName;
    }

    @Override
    public String getFactoryBeanName() {
        return this.factoryBeanName;
    }

    @Override
    public boolean isSingleton() {
        return this.singleton;
    }
}
