package org.springframework.beans.factory;

public interface BeanDefinition {

    void setBeanClassName(Object beanClass);

    Object getBeanClassName();

    void setScope(String scope);

    String getScope();

    void setLazyInit(boolean lazyInit);

    boolean isLazyInit();

    void setFactoryBeanName( String factoryBeanName);

    String getFactoryBeanName();

    boolean isSingleton();
}
