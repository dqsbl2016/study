package org.springframework.beans.factory;

/*
        实现对已存在实例的管理
 */
public interface AutowireCapableBeanFactory extends BeanFactory {

    //关联一个Bean的实例
    <T> T createBean(Class<T> beanClass);
   //为bean填充属性值
    void applyBeanPropertyValues(Object existingBean, String beanName);
    // 销毁Bean
    void destroyBean(Object existingBean);
}
