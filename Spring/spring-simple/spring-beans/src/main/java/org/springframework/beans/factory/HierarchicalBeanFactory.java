package org.springframework.beans.factory;

/*
     获取上级容器的接口
 */
public interface HierarchicalBeanFactory extends BeanFactory {

    //获取上级容器
    BeanFactory getParentBeanFactory();
}
