package org.springframework.beans.factory.support;

import org.springframework.beans.factory.*;

import java.lang.annotation.Annotation;
import java.lang.reflect.Field;
import java.util.Map;

public abstract class AbstractBeanFactory implements ListableBeanFactory,HierarchicalBeanFactory,AutowireCapableBeanFactory {
    @Override
    public <T> T createBean(Class<T> beanClass) {
        return null;
    }

    @Override
    public void applyBeanPropertyValues(Object existingBean, String beanName) {

    }

    @Override
    public void destroyBean(Object existingBean) {

    }

    @Override
    public BeanFactory getParentBeanFactory() {
        return null;
    }

    @Override
    public <T> Map<String, T> getBeansOfType(Class<T> type) {
        return null;
    }

    @Override
    public Map<String, Object> getBeansWithAnnotation(Class<? extends Annotation> annotationType) {
        return null;
    }

    @Override
    public Object getBean(String name) {
        return doGetBean(name);
    }

    protected abstract BeanDefinition getBeanDefinition(String beanName) ;


    public Object doGetBean(String name){

        BeanWrapper instanceWrapper = doCreateBean(name);

        populateBean(name,instanceWrapper);

        return instanceWrapper.getWrappedInstance();
    }


    public BeanWrapper doCreateBean(String name){
        BeanDefinition beanDefinition = getBeanDefinition(name);
        try {
            Object beanInstance = null;
            try {
                beanInstance = Class.forName(beanDefinition.getBeanClass().toString()).newInstance();
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            }
            BeanWrapper beanWrapper = new BeanWrapperImpl(beanInstance);
            return beanWrapper;
        } catch (InstantiationException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
        return null;
    }
    public void populateBean(String name,BeanWrapper beanWrapper){

        try {
            //属性注入没有实现。。  测试写死了一个属性
            Field f  = beanWrapper.getWrappedInstance().getClass().getDeclaredField("snum");
            f.setAccessible(true);
            f.set(beanWrapper.getWrappedInstance(),18);
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        }
    }
}
