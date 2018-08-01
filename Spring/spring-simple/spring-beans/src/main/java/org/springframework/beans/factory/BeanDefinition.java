package org.springframework.beans.factory;

public interface BeanDefinition {

    void setBeanClass(Object beanClass);

    Object getBeanClass();

    void setBeanClassName(String beanClassName);

    String getBeanClassName();

    void setScope(String scope);

    String getScope();

    void setLazyInit(boolean lazyInit);

    boolean isLazyInit();

    void setFactoryBeanName( String factoryBeanName);

    String getFactoryBeanName();
}
