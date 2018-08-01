package org.springframework.beans.factory;

/*
    最底层容器
 */
public interface BeanFactory {

    Object getBean(String name);
}
